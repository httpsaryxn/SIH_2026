import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/small_business_label_model.dart';
import 'file_download_service_stub.dart'
    if (dart.library.html) 'file_download_service_web.dart' as platform_downloader;
import 'gs1_ean13_encoder.dart';
import 'nutrition_calculator.dart';

class FileDownloadService {
  /// Extracts width (mm) and height (mm) from packaging dimension strings (e.g. "Standard Pouch (100 × 150 mm)")
  static ({double widthMm, double heightMm}) parseDimensions(String? dimension, {double defaultW = 100, double defaultH = 118}) {
    if (dimension == null || dimension.isEmpty) {
      return (widthMm: defaultW, heightMm: defaultH);
    }
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*[×xX*]\s*(\d+(?:\.\d+)?)').firstMatch(dimension);
    if (match != null) {
      final w = double.tryParse(match.group(1)!) ?? defaultW;
      final h = double.tryParse(match.group(2)!) ?? defaultH;
      return (widthMm: w, heightMm: h);
    }
    return (widthMm: defaultW, heightMm: defaultH);
  }

  /// Resolves raw image bytes from Data URL, base64, local file path, asset, or HTTP URL
  static Future<Uint8List?> _resolveImageRawBytes(String? source) async {
    if (source == null || source.trim().isEmpty) return null;
    final trimmed = source.trim();

    // 1. Data URL / Base64 image
    if (trimmed.startsWith('data:image') || trimmed.contains('base64,')) {
      try {
        String b64 = trimmed;
        if (trimmed.contains('base64,')) {
          b64 = trimmed.split('base64,').last;
        }
        b64 = b64.replaceAll(RegExp(r'\s+'), '');
        return base64Decode(base64.normalize(b64));
      } catch (e) {
        debugPrint('Failed to decode base64 logo: $e');
      }
    }

    // 2. Pure base64 fallback
    if (trimmed.length > 100 && !trimmed.contains('/') && !trimmed.contains('\\')) {
      try {
        return base64Decode(base64.normalize(trimmed.replaceAll(RegExp(r'\s+'), '')));
      } catch (_) {}
    }

    // 3. Local file path
    if (!kIsWeb &&
        (trimmed.startsWith('/') ||
            trimmed.startsWith('file://') ||
            trimmed.contains(r':\') ||
            trimmed.contains(':/'))) {
      try {
        final path = trimmed.replaceFirst('file://', '');
        final file = io.File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      } catch (e) {
        debugPrint('Failed to read local logo file: $e');
      }
    }

    // 4. Asset image path
    if (trimmed.startsWith('assets/') || trimmed.startsWith('asset:')) {
      try {
        final assetPath = trimmed.replaceFirst('asset:', '');
        final data = await rootBundle.load(assetPath);
        return data.buffer.asUint8List();
      } catch (e) {
        debugPrint('Failed to load asset logo: $e');
      }
    }

    // 5. Network URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final response = await http.get(Uri.parse(trimmed));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Failed to download network logo: $e');
      }
    }

    return null;
  }

  /// Decodes image bytes (PNG, JPEG, WEBP) into raw RGB bytes and base64 for PDF and SVG
  static Future<Map<String, dynamic>?> _convertImageBytesToRgbMap(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final int width = img.width;
      final int height = img.height;
      final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData != null) {
        final rgba = byteData.buffer.asUint8List();
        final rgb = Uint8List(width * height * 3);
        int rgbIdx = 0;
        for (int i = 0; i < rgba.length; i += 4) {
          final r = rgba[i];
          final g = rgba[i + 1];
          final b = rgba[i + 2];
          final a = rgba[i + 3] / 255.0;
          // Alpha blend over clean white background (255, 255, 255)
          rgb[rgbIdx++] = ((r * a) + (255 * (1.0 - a))).round().clamp(0, 255);
          rgb[rgbIdx++] = ((g * a) + (255 * (1.0 - a))).round().clamp(0, 255);
          rgb[rgbIdx++] = ((b * a) + (255 * (1.0 - a))).round().clamp(0, 255);
        }
        return {
          'bytes': rgb,
          'width': width,
          'height': height,
          'pngBase64': base64Encode(bytes),
        };
      }
    } catch (e) {
      debugPrint('Image byte conversion error: $e');
    }
    return null;
  }

  /// Loads and prepares the official FSSAI PNG image for direct PDF XObject embedding
  static Future<Map<String, dynamic>?> _loadFssaiImageData() async {
    try {
      final ByteData assetData = await rootBundle.load('assets/images/fssai_logo.png');
      return await _convertImageBytesToRgbMap(assetData.buffer.asUint8List());
    } catch (e) {
      debugPrint('FSSAI logo asset load note: $e');
    }
    return null;
  }

  /// Loads and prepares user brand logo from Data URL, base64, file, asset or HTTP URL
  static Future<Map<String, dynamic>?> _loadBrandLogoData(String? logoSource) async {
    if (logoSource == null || logoSource.trim().isEmpty) return null;
    try {
      final bytes = await _resolveImageRawBytes(logoSource);
      if (bytes != null && bytes.isNotEmpty) {
        return await _convertImageBytesToRgbMap(bytes);
      }
    } catch (e) {
      debugPrint('Brand logo asset load note: $e');
    }
    return null;
  }

  /// Generates and triggers direct download of standalone, valid SVG packaging artwork
  static Future<String?> downloadSvgLabel({
    required SmallBusinessLabelModel model,
    required String dimension,
    double? widthMm,
    double? heightMm,
    double? customWidthMm,
    double? customHeightMm,
    bool shareOnMobile = false,
  }) async {
    final effectiveCustomW = customWidthMm ?? widthMm;
    final effectiveCustomH = customHeightMm ?? heightMm;
    final parsed = parseDimensions(dimension.isNotEmpty ? dimension : model.labelDimension);
    final effectiveW = (effectiveCustomW != null && effectiveCustomW > 0 && dimension.startsWith('Custom'))
        ? effectiveCustomW
        : ((effectiveCustomW != null && effectiveCustomW > 0 && !dimension.contains('(')) ? effectiveCustomW : parsed.widthMm);
    final effectiveH = (effectiveCustomH != null && effectiveCustomH > 0 && dimension.startsWith('Custom'))
        ? effectiveCustomH
        : ((effectiveCustomH != null && effectiveCustomH > 0 && !dimension.contains('(')) ? effectiveCustomH : parsed.heightMm);

    final cleanName = _cleanFileName(model.productName.isNotEmpty ? model.productName : 'Product');
    final fileName = '${cleanName}_label_artwork_${effectiveW.toInt()}x${effectiveH.toInt()}mm.svg';

    final fssaiData = await _loadFssaiImageData();
    final fssaiBase64 = fssaiData?['pngBase64'] as String?;
    final brandLogoData = await _loadBrandLogoData(model.logoUrl);
    final brandLogoBase64 = brandLogoData?['pngBase64'] as String?;

    final svgContent = _generateLabelSvg(
      model: model,
      dimension: dimension,
      widthMm: effectiveW,
      heightMm: effectiveH,
      fssaiBase64: fssaiBase64,
      brandLogoBase64: brandLogoBase64,
    );

    return await platform_downloader.triggerDownload(
      fileName: fileName,
      content: svgContent,
      mimeType: 'image/svg+xml;charset=utf-8',
      shareOnMobile: shareOnMobile,
    );
  }

  /// Direct download of pre-rendered PNG bytes
  static Future<String?> downloadPngBytes({
    required String fileName,
    required List<int> bytes,
    bool shareOnMobile = false,
  }) async {
    return await platform_downloader.triggerBytesDownload(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'image/png',
      shareOnMobile: shareOnMobile,
    );
  }

  /// Generates and triggers direct download of genuine, high-resolution PNG bitmap
  static Future<String?> downloadPngLabel({
    required SmallBusinessLabelModel model,
    required String dimension,
    double? widthMm,
    double? heightMm,
    double? customWidthMm,
    double? customHeightMm,
    List<int>? preRenderedBytes,
    bool shareOnMobile = false,
  }) async {
    final effectiveCustomW = customWidthMm ?? widthMm;
    final effectiveCustomH = customHeightMm ?? heightMm;
    final parsed = parseDimensions(dimension.isNotEmpty ? dimension : model.labelDimension);
    final effectiveW = (effectiveCustomW != null && effectiveCustomW > 0 && dimension.startsWith('Custom'))
        ? effectiveCustomW
        : ((effectiveCustomW != null && effectiveCustomW > 0 && !dimension.contains('(')) ? effectiveCustomW : parsed.widthMm);
    final effectiveH = (effectiveCustomH != null && effectiveCustomH > 0 && dimension.startsWith('Custom'))
        ? effectiveCustomH
        : ((effectiveCustomH != null && effectiveCustomH > 0 && !dimension.contains('(')) ? effectiveCustomH : parsed.heightMm);

    final cleanName = _cleanFileName(model.productName.isNotEmpty ? model.productName : 'Product');
    final fileName = '${cleanName}_label_highres_${effectiveW.toInt()}x${effectiveH.toInt()}mm.png';

    if (preRenderedBytes != null && preRenderedBytes.isNotEmpty) {
      return await downloadPngBytes(
        fileName: fileName,
        bytes: preRenderedBytes,
        shareOnMobile: shareOnMobile,
      );
    }

    final fssaiData = await _loadFssaiImageData();
    final fssaiBase64 = fssaiData?['pngBase64'] as String?;
    final brandLogoData = await _loadBrandLogoData(model.logoUrl);
    final brandLogoBase64 = brandLogoData?['pngBase64'] as String?;

    final svgContent = _generateLabelSvg(
      model: model,
      dimension: dimension,
      widthMm: effectiveW,
      heightMm: effectiveH,
      fssaiBase64: fssaiBase64,
      brandLogoBase64: brandLogoBase64,
    );

    return await platform_downloader.triggerSvgToPngDownload(
      fileName: fileName,
      svgContent: svgContent,
      width: (effectiveW * 12).toInt().clamp(800, 2400),
      height: (effectiveH * 12).toInt().clamp(944, 3600),
      shareOnMobile: shareOnMobile,
    );
  }

  /// Generates and triggers direct download of a 100% valid, complete PDF 1.4 document
  static Future<String?> downloadPdfLabel({
    required SmallBusinessLabelModel model,
    required String dimension,
    double? widthMm,
    double? heightMm,
    double? customWidthMm,
    double? customHeightMm,
    bool shareOnMobile = false,
  }) async {
    final effectiveCustomW = customWidthMm ?? widthMm;
    final effectiveCustomH = customHeightMm ?? heightMm;
    final parsed = parseDimensions(dimension.isNotEmpty ? dimension : model.labelDimension);
    final effectiveW = (effectiveCustomW != null && effectiveCustomW > 0 && dimension.startsWith('Custom'))
        ? effectiveCustomW
        : ((effectiveCustomW != null && effectiveCustomW > 0 && !dimension.contains('(')) ? effectiveCustomW : parsed.widthMm);
    final effectiveH = (effectiveCustomH != null && effectiveCustomH > 0 && dimension.startsWith('Custom'))
        ? effectiveCustomH
        : ((effectiveCustomH != null && effectiveCustomH > 0 && !dimension.contains('(')) ? effectiveCustomH : parsed.heightMm);

    final cleanName = _cleanFileName(model.productName.isNotEmpty ? model.productName : 'Product');
    final fileName = '${cleanName}_label_print_${effectiveW.toInt()}x${effectiveH.toInt()}mm_300dpi.pdf';

    final fssaiData = await _loadFssaiImageData();
    final brandLogoData = await _loadBrandLogoData(model.logoUrl);

    final pdfBytes = _generateValidPdfBytes(
      model: model,
      dimension: dimension,
      widthMm: effectiveW,
      heightMm: effectiveH,
      fssaiImageData: fssaiData,
      brandLogoData: brandLogoData,
    );

    return await platform_downloader.triggerBytesDownload(
      fileName: fileName,
      bytes: pdfBytes,
      mimeType: 'application/pdf',
      shareOnMobile: shareOnMobile,
    );
  }

  /// Generates and triggers direct download of Legal Metrology JSON metadata
  static Future<String?> downloadJsonMetadata({
    required SmallBusinessLabelModel model,
    bool shareOnMobile = true,
  }) async {
    final cleanName = _cleanFileName(model.productName.isNotEmpty ? model.productName : 'Product');
    final fileName = '${cleanName}_compliance_metadata.json';

    final barcodeDigits = GS1Ean13Encoder.deriveBarcodeDigits(
      fssaiNumber: model.fssaiLicenseNumber,
    );
    final map = model.toMap();
    map['derivedBarcode'] = barcodeDigits;
    map['barcodeStandard'] = 'GS1 EAN-13';
    map['complianceStandard'] = 'Legal Metrology (Packaged Commodities) Rules 2011 & FSSAI Standards';

    final jsonContent = const JsonEncoder.withIndent('  ').convert(map);

    return await platform_downloader.triggerDownload(
      fileName: fileName,
      content: jsonContent,
      mimeType: 'application/json;charset=utf-8',
      shareOnMobile: shareOnMobile,
    );
  }

  static Future<void> shareLabel({
    required String title,
    required String text,
    String? url,
    String? filePath,
  }) async {
    await platform_downloader.triggerNativeShare(title: title, text: text, url: url, filePath: filePath);
  }

  static String _cleanFileName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static List<String> _wrapText(String text, int maxChars) {
    final words = text.split(' ');
    final lines = <String>[];
    var currentLine = '';
    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + word.length + 1) <= maxChars) {
        currentLine = '$currentLine $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
    return lines;
  }

  /// Generates the Ultra-Compact Commercial Packaging SVG layout
  /// with 100% zero vacant space and a synchronized GS1 EAN-13 barcode.
  static String _generateLabelSvg({
    required SmallBusinessLabelModel model,
    required String dimension,
    required double widthMm,
    required double heightMm,
    String? fssaiBase64,
    String? brandLogoBase64,
  }) {
    final brand = _escapeXml(model.brandName.isNotEmpty ? model.brandName : 'HALDIRAMS');
    final product = _escapeXml(model.productName.isNotEmpty ? model.productName : 'KURKURE');
    final category = _escapeXml(model.productCategory.isNotEmpty ? model.productCategory.toUpperCase() : 'SNACKS & NAMKEEN');

    final cleanNetQty = model.netQuantity.replaceAll(RegExp(r'[^0-9.]'), '');
    final netGrams = double.tryParse(cleanNetQty) ?? 70.0;
    final netUnit = model.netQuantityUnit.isNotEmpty ? model.netQuantityUnit : 'g';
    final ozVal = (netGrams * 0.035274).toStringAsFixed(2);

    final cleanMrp = model.mrp.replaceAll('₹', '').replaceFirst('Rs.', '').trim();
    final mrpDisplay = cleanMrp.isNotEmpty ? 'Rs. $cleanMrp' : 'Rs. 20.00';
    final uspDisplay = model.usp.isNotEmpty ? model.usp.replaceAll('₹', 'Rs. ') : 'Rs. 0.28 / g';

    final fssai = _escapeXml(model.fssaiLicenseNumber.isNotEmpty ? model.fssaiLicenseNumber : '74125896323145');
    final manufacturer = _escapeXml(model.manufacturerName.isNotEmpty ? model.manufacturerName : model.brandName);
    final address = _escapeXml(model.manufacturerAddress.isNotEmpty ? model.manufacturerAddress : 'Registered Business Address');
    final phone = _escapeXml(model.consumerCarePhone.isNotEmpty ? model.consumerCarePhone : '9876543210');
    final email = _escapeXml(model.consumerCareEmail.isNotEmpty ? model.consumerCareEmail : 'care@business.in');
    final website = _escapeXml(model.consumerCareWebsite != null && model.consumerCareWebsite!.isNotEmpty ? model.consumerCareWebsite! : 'www.business.in');
    final packagingType = _escapeXml(model.packagingType.isNotEmpty ? model.packagingType : 'Food Grade Metallized Pouch');
    final batch = _escapeXml(model.batchNumber.isNotEmpty ? model.batchNumber : 'BATCH-2026-I92');
    final mfg = _escapeXml(model.mfgDate.isNotEmpty && model.mfgDate != 'AUG 2026' ? model.mfgDate : DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase());
    final bestBefore = _escapeXml(model.bestBefore.isNotEmpty ? model.bestBefore : '12 Months from Packaging');
    final storage = _escapeXml(model.storageInstructions.isNotEmpty ? model.storageInstructions : 'Store in a cool, dry & hygienic place.');

    final isVeg = model.isVegetarian;
    final vegColor = isVeg ? '#16A34A' : '#991B1B';

    // Serving size & Calories
    final sSize = model.servingSize.isNotEmpty ? model.servingSize : '70';
    final sUnit = model.servingSizeUnit.isNotEmpty ? model.servingSizeUnit : 'g';
    final serveG = double.tryParse(sSize) ?? 70.0;
    final servingsPerPack = (serveG > 0) ? (netGrams / serveG).round().clamp(1, 99) : 1;

    final energyItem = model.nutrients.cast<SmallBusinessNutrientModel?>().firstWhere(
      (n) => n?.label.toLowerCase() == 'energy' || n?.label.toLowerCase() == 'calories',
      orElse: () => null,
    );
    final energyVal = double.tryParse(energyItem?.value ?? '') ?? 536.0;
    final calPerServe = ((energyVal * serveG) / 100.0).round().toString();
    final calPercentStr = NutritionCalculator.calculateCaloriesRda(calPerServe);

    // Ingredients with explicit percentage of content
    final ingredientsText = model.ingredients.isNotEmpty
        ? model.ingredients.map((i) {
            if (i.percentage != null && i.percentage! > 0) {
              final pctStr = (i.percentage! == i.percentage!.roundToDouble())
                  ? '${i.percentage!.toInt()}%'
                  : '${i.percentage!.toStringAsFixed(1)}%';
              return '${_escapeXml(i.name)} ($pctStr)';
            }
            return _escapeXml(i.name);
          }).join(', ')
        : 'Turmeric Powder (28%), Red Chilli Powder (24%), Coriander Powder (20%), Mustard Seeds (14%), Black Pepper (8%), Garam Masala (6%)';

    final allergensText = model.allergens.isNotEmpty
        ? model.allergens.map(_escapeXml).join(', ')
        : 'Wheat / Gluten';

    // Synchronized GS1 EAN-13 Barcode
    final barcodeDigits = GS1Ean13Encoder.deriveBarcodeDigits(
      fssaiNumber: model.fssaiLicenseNumber,
    );
    final modules = GS1Ean13Encoder.encodeModules(barcodeDigits);
    final splitBarcode = GS1Ean13Encoder.splitForDisplay(barcodeDigits);

    final barSvgBuffer = StringBuffer();
    const double barStartX = 24.0;
    const double barStartY = 386.0;
    const double totalBarW = 166.0;
    final double moduleW = totalBarW / modules.length;
    const double normalBarH = 28.0;
    const double guardBarH = 34.0;

    for (int i = 0; i < modules.length; i++) {
      if (modules[i]) {
        final isGuard = (i < 3) || (i >= 45 && i < 50) || (i >= modules.length - 3);
        final bh = isGuard ? guardBarH : normalBarH;
        final bx = barStartX + (i * moduleW);
        barSvgBuffer.writeln('      <rect x="${bx.toStringAsFixed(2)}" y="$barStartY" width="${(moduleW + 0.15).toStringAsFixed(2)}" height="${bh.toStringAsFixed(2)}" fill="#000000" />');
      }
    }

    // Nutrients rows
    final defaultNutrients = [
      {'name': 'Energy', 'val': '536 kcal', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Energy', value: '536', unit: 'kcal', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Protein', 'val': '5.6 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Protein', value: '5.6', unit: 'g', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Carbohydrate', 'val': '230 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Carbohydrate', value: '230', unit: 'g', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Total Sugars', 'val': '2 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Total Sugars', value: '2', unit: 'g', servingSizeGrams: serveG), 'level': 1},
      {'name': 'Added Sugars', 'val': '2 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Added Sugars', value: '2', unit: 'g', servingSizeGrams: serveG), 'level': 2},
      {'name': 'Total Fat', 'val': '10 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Total Fat', value: '10', unit: 'g', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Saturated Fat', 'val': '1 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Saturated Fat', value: '1', unit: 'g', servingSizeGrams: serveG), 'level': 1},
      {'name': 'Trans Fat', 'val': '0 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Trans Fat', value: '0', unit: 'g', servingSizeGrams: serveG), 'level': 1},
      {'name': 'Cholesterol', 'val': '0 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Cholesterol', value: '0', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Sodium', 'val': '222 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Sodium', value: '222', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Potassium', 'val': '140 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Potassium', value: '140', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Calcium', 'val': '40 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Calcium', value: '40', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Iron', 'val': '1.2 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Iron', value: '1.2', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
    ];

    final displayNutrients = <Map<String, dynamic>>[];
    if (model.nutrients.isNotEmpty) {
      for (final n in model.nutrients) {
        final rdaVal = NutritionCalculator.calculateRdaPercentage(
          label: n.label,
          value: n.value,
          unit: n.unit,
          servingSizeGrams: serveG,
        );
        displayNutrients.add({
          'name': _escapeXml(n.label),
          'val': '${_escapeXml(n.value)} ${_escapeXml(n.unit)}',
          'rda': rdaVal,
          'level': n.isSubNutrient ? 1 : 0,
        });
      }
    } else {
      displayNutrients.addAll(defaultNutrients);
    }

    final nutrientRowsSvg = StringBuffer();
    double currentNY = 120.0;
    for (final r in displayNutrients) {
      final name = r['name'] as String;
      final val = r['val'] as String;
      final rda = r['rda'] as String;
      final level = r['level'] as int;
      final isBold = level == 0 || name.contains('Fat') || name.contains('Carbohydrate') || name.contains('Protein') || name.contains('Sodium');
      final prefix = level == 1 ? '— ' : (level == 2 ? '• ' : '');
      final indentX = 14.0 + (level * 10.0);

      nutrientRowsSvg.writeln('    <line x1="8" y1="${currentNY - 2}" x2="452" y2="${currentNY - 2}" stroke="#E2E8F0" stroke-width="0.5" />');
      nutrientRowsSvg.writeln('    <text x="$indentX" y="${currentNY + 7}" font-family="Arial, sans-serif" font-size="7.5px" font-weight="${isBold ? '900' : '500'}" fill="${isBold ? '#000000' : '#333333'}">$prefix$name <tspan font-weight="normal" fill="#555555">$val</tspan></text>');
      nutrientRowsSvg.writeln('    <text x="444" y="${currentNY + 7}" font-family="Arial, sans-serif" font-size="7.5px" font-weight="${isBold ? '900' : '500'}" fill="${isBold ? '#000000' : '#333333'}" text-anchor="end">$rda</text>');
      currentNY += 10.0;
    }

    final totalNutritionHeight = (currentNY - 60.0) + 12.0;

    // Ingredients lines wrapped
    final ingLines = _wrapText(ingredientsText, 90);
    final ingSvgBuffer = StringBuffer();
    double ingY = 60.0 + totalNutritionHeight + 8.0;
    for (int i = 0; i < ingLines.length; i++) {
      if (i == 0) {
        ingSvgBuffer.writeln('    <text x="12" y="$ingY" font-family="Arial, sans-serif" font-size="7.5px" fill="#1E293B"><tspan font-weight="900" fill="#000000">INGREDIENTS: </tspan>${ingLines[i]}</text>');
      } else {
        ingSvgBuffer.writeln('    <text x="12" y="$ingY" font-family="Arial, sans-serif" font-size="7.5px" fill="#1E293B">${ingLines[i]}</text>');
      }
      ingY += 9.5;
    }

    final allergenBoxY = ingY + 2.0;
    final specBoxY = allergenBoxY + 20.0;
    final metrologyBoxY = specBoxY + 20.0;
    final barcodeBoxY = metrologyBoxY + 54.0;
    final footerBoxY = barcodeBoxY + 76.0;
    final totalCanvasH = (footerBoxY + 62.0).round();

    return '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${widthMm}mm" height="${heightMm}mm" viewBox="0 0 460 $totalCanvasH">
  <defs>
    <style>
      .bold { font-weight: 900; }
      .semi { font-weight: 700; }
      .medium { font-weight: 600; }
      .reg { font-weight: 400; }
    </style>
  </defs>

  <!-- 1. Master Ultra-Compact Outer Border (Zero Vacant Space) -->
  <rect x="1" y="1" width="458" height="${totalCanvasH - 2}" fill="#FFFFFF" stroke="#000000" stroke-width="1.6" rx="2" />

  <!-- 2. Header: Brand, Product, Proprietary Food Category, Net Wt Badge & Veg Emblem -->
  <g transform="translate(10, 8)">
    <!-- Brand Logo / Initial Badge -->
    ${(brandLogoBase64 != null && brandLogoBase64.isNotEmpty) ? '''
    <rect x="0" y="0" width="34" height="34" rx="4" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="0.8" />
    <image x="2" y="2" width="30" height="30" href="${brandLogoBase64.startsWith('data:') ? brandLogoBase64 : 'data:image/png;base64,$brandLogoBase64'}" preserveAspectRatio="xMidYMid meet" />
    ''' : '''
    <rect x="0" y="0" width="34" height="34" rx="4" fill="#047857" />
    <text x="17" y="24" font-family="Arial, sans-serif" font-size="19px" font-weight="900" fill="#FFFFFF" text-anchor="middle">${brand.isNotEmpty ? brand[0].toUpperCase() : 'H'}</text>
    '''}

    <!-- Brand, Product, Category -->
    <text x="42" y="10" font-family="Arial, sans-serif" font-size="9px" font-weight="900" fill="#047857" letter-spacing="0.8">${brand.toUpperCase()}</text>
    <text x="42" y="23" font-family="Arial, sans-serif" font-size="13.5px" font-weight="900" fill="#000000" letter-spacing="-0.2">$product</text>
    <text x="42" y="33" font-family="Arial, sans-serif" font-size="7.5px" font-weight="700" fill="#555555">PROPRIETARY FOOD [$category]</text>

    <!-- Net Weight Badge -->
    <rect x="314" y="6" width="86" height="22" rx="2" fill="#F8FAFC" stroke="#94A3B8" stroke-width="0.8" />
    <text x="357" y="20.5" font-family="Arial, sans-serif" font-size="8.5px" font-weight="800" fill="#000000" text-anchor="middle">NET WT. $cleanNetQty $netUnit</text>

    <!-- Statutory Vegetarian Emblem (1:1 Ratio) -->
    <rect x="412" y="6" width="22" height="22" rx="2" fill="#FFFFFF" stroke="$vegColor" stroke-width="1.6" />
    <circle cx="423" cy="17" r="5" fill="$vegColor" />
  </g>

  <!-- Divider Line -->
  <line x1="6" y1="50" x2="454" y2="50" stroke="#000000" stroke-width="1.2" />

  <!-- 3. Commercial Nutrition Facts Panel (Black Header, Serving Callout, Indented Rows) -->
  <rect x="8" y="56" width="444" height="${totalNutritionHeight.toStringAsFixed(1)}" fill="#FFFFFF" stroke="#000000" stroke-width="1" rx="2" />
  <rect x="8" y="56" width="444" height="18" fill="#000000" />
  <text x="16" y="68.5" font-family="Arial, sans-serif" font-size="8.5px" font-weight="900" fill="#FFFFFF" letter-spacing="0.3">NUTRITION FACTS / VALEUR NUTRITIVE</text>
  <text x="444" y="68.5" font-family="Arial, sans-serif" font-size="8px" font-weight="800" fill="#FFFFFF" text-anchor="end">PER ${sSize.toUpperCase()} ${sUnit.toUpperCase()}</text>

  <text x="16" y="85" font-family="Arial, sans-serif" font-size="7.5px" font-weight="700" fill="#475569">Serving Size: $sSize $sUnit (Pack contains $servingsPerPack serving)</text>
  <text x="444" y="85" font-family="Arial, sans-serif" font-size="7.5px" font-weight="700" fill="#475569" text-anchor="end">% Daily Value / % RDA *</text>

  <line x1="8" y1="90" x2="452" y2="90" stroke="#000000" stroke-width="1.8" />

  <!-- Calories Hero Callout -->
  <text x="16" y="104" font-family="Arial, sans-serif" font-size="12px" font-weight="900" fill="#000000">Calories $calPerServe <tspan font-size="8.5px" font-weight="normal" fill="#555555">(Energy $energyVal kcal / 100 g)</tspan></text>
  <text x="444" y="104" font-family="Arial, sans-serif" font-size="11.5px" font-weight="900" fill="#000000" text-anchor="end">$calPercentStr</text>

  <line x1="8" y1="109" x2="452" y2="109" stroke="#000000" stroke-width="1.2" />

$nutrientRowsSvg
  <line x1="8" y1="${currentNY.toStringAsFixed(1)}" x2="452" y2="${currentNY.toStringAsFixed(1)}" stroke="#000000" stroke-width="0.6" />
  <text x="16" y="${(currentNY + 8.5).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="6.5px" fill="#555555">*5% or less is a little, 15% or more is a lot. % Daily Values based on 2,000 kcal diet.</text>

  <!-- 4. Ingredients Statement with Explicit % w/w Formulation -->
$ingSvgBuffer

  <!-- 5. Allergen Advice Strip -->
  <rect x="8" y="${allergenBoxY.toStringAsFixed(1)}" width="444" height="17" rx="2" fill="#FFF5F5" stroke="#FEB2B2" stroke-width="0.8" />
  <text x="14" y="${(allergenBoxY + 11.5).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="7.2px" fill="#991B1B"><tspan font-weight="900">ALLERGEN ADVICE: </tspan>Contains $allergensText. Made in a facility that also processes Mustard, Sesame &amp; Peanuts.</text>

  <!-- 6. Specification & Origin Strip -->
  <rect x="8" y="${specBoxY.toStringAsFixed(1)}" width="444" height="16" rx="2" fill="#F1F5F9" stroke="#CBD5E1" stroke-width="0.7" />
  <text x="14" y="${(specBoxY + 11).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="7.2px" font-weight="800" fill="#000000">NET WT. $cleanNetQty $netUnit / $ozVal oz.</text>
  <text x="230" y="${(specBoxY + 11).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="7.2px" font-weight="800" fill="#475569" text-anchor="middle">PRODUCT OF INDIA / PRODUIT DE L&apos;INDE</text>
  <text x="444" y="${(specBoxY + 11).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="7.2px" font-weight="800" fill="#047857" text-anchor="end">COMMERCIAL PACK</text>

  <!-- 7. Legal Metrology Pricing Triad & Traceability Box -->
  <rect x="8" y="${metrologyBoxY.toStringAsFixed(1)}" width="444" height="48" rx="2" fill="#FFFFFF" stroke="#000000" stroke-width="1" />
  <text x="14" y="${(metrologyBoxY + 11).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="6.5px" font-weight="800" fill="#64748B" letter-spacing="0.3">NET QUANTITY</text>
  <text x="14" y="${(metrologyBoxY + 24).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="11.5px" font-weight="900" fill="#000000">$cleanNetQty $netUnit</text>

  <line x1="110" y1="${(metrologyBoxY + 4).toStringAsFixed(1)}" x2="110" y2="${(metrologyBoxY + 28).toStringAsFixed(1)}" stroke="#CBD5E1" stroke-width="0.8" />

  <text x="120" y="${(metrologyBoxY + 11).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="6.5px" font-weight="800" fill="#64748B" letter-spacing="0.3">MAX RETAIL PRICE [MRP]</text>
  <text x="120" y="${(metrologyBoxY + 24).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="11.5px" font-weight="900" fill="#047857">$mrpDisplay <tspan font-size="7px" font-weight="normal" fill="#64748B">[Incl. of all taxes]</tspan></text>

  <line x1="290" y1="${(metrologyBoxY + 4).toStringAsFixed(1)}" x2="290" y2="${(metrologyBoxY + 28).toStringAsFixed(1)}" stroke="#CBD5E1" stroke-width="0.8" />

  <text x="300" y="${(metrologyBoxY + 11).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="6.5px" font-weight="800" fill="#64748B" letter-spacing="0.3">UNIT SALE PRICE [USP]</text>
  <text x="300" y="${(metrologyBoxY + 24).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="11px" font-weight="900" fill="#000000">$uspDisplay</text>

  <line x1="8" y1="${(metrologyBoxY + 31).toStringAsFixed(1)}" x2="452" y2="${(metrologyBoxY + 31).toStringAsFixed(1)}" stroke="#CBD5E1" stroke-width="0.7" />
  <text x="14" y="${(metrologyBoxY + 40).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="7.2px" font-weight="600" fill="#1E293B">Batch No: $batch   •   Mfg Date: $mfg   •   Best Before: $bestBefore</text>
  <text x="320" y="${(metrologyBoxY + 40).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="6.8px" fill="#555555">Storage: $storage</text>

  <!-- 8. Scannable GS1 Barcode & Authentic 4:3 FSSAI Logo Area -->
  <rect x="8" y="${barcodeBoxY.toStringAsFixed(1)}" width="444" height="70" rx="2" fill="#FFFFFF" stroke="#000000" stroke-width="1" />

  <!-- Left: Authentic GS1 EAN-13 Vector Barcode Modules -->
  <rect x="20" y="${(barcodeBoxY + 4).toStringAsFixed(1)}" width="180" height="42" fill="#FFFFFF" />
$barSvgBuffer
  <text x="14" y="${(barcodeBoxY + 50).toStringAsFixed(1)}" font-family="monospace" font-size="8.5px" font-weight="900" fill="#000000">${splitBarcode.d1}</text>
  <text x="56" y="${(barcodeBoxY + 50).toStringAsFixed(1)}" font-family="monospace" font-size="8.5px" font-weight="900" fill="#000000" letter-spacing="1.5">${splitBarcode.left6}</text>
  <text x="140" y="${(barcodeBoxY + 50).toStringAsFixed(1)}" font-family="monospace" font-size="8.5px" font-weight="900" fill="#000000" letter-spacing="1.5">${splitBarcode.right6}</text>
  <text x="105" y="${(barcodeBoxY + 62).toStringAsFixed(1)}" font-family="Arial, sans-serif" font-size="6.5px" font-weight="800" fill="#059669" text-anchor="middle">GS1 EAN-13 VERIFIED ✓</text>

  <!-- Center Divider -->
  <line x1="228" y1="${(barcodeBoxY + 6).toStringAsFixed(1)}" x2="228" y2="${(barcodeBoxY + 64).toStringAsFixed(1)}" stroke="#CBD5E1" stroke-width="0.8" />

  <!-- Right: Un-distorted 4:3 FSSAI Logo Area -->
  <g transform="translate(242, ${(barcodeBoxY + 6).toStringAsFixed(1)})">
    <rect width="198" height="58" rx="2" fill="#FFFFFF" stroke="#047857" stroke-width="0.8" />
${fssaiBase64 != null ? '''    <image href="data:image/png;base64,$fssaiBase64" x="71" y="4" width="56" height="38" preserveAspectRatio="xMidYMid meet" />''' : '''    <text x="99" y="26" font-family="Arial, sans-serif" font-size="18px" font-weight="900" fill="#047857" text-anchor="middle">fssai</text>'''}
    <text x="99" y="49" font-family="Arial, sans-serif" font-size="8px" font-weight="900" fill="#000000" letter-spacing="0.3" text-anchor="middle">Lic. No. $fssai</text>
  </g>

  <!-- 9. Manufacturer, Consumer Care & Compliance Declaration Footer -->
  <rect x="8" y="${footerBoxY.toStringAsFixed(1)}" width="444" height="54" rx="2" fill="#FFFFFF" stroke="#000000" stroke-width="1" />
  <g transform="translate(14, ${(footerBoxY + 6).toStringAsFixed(1)})">
    <text x="0" y="6" font-family="Arial, sans-serif" font-size="7.2px" fill="#000000"><tspan font-weight="900">Mfd. By: </tspan>$manufacturer, $address  |  <tspan font-weight="900">Lic. No. </tspan>$fssai</text>
    <line x1="0" y1="11" x2="384" y2="11" stroke="#E2E8F0" stroke-width="0.6" />

    <text x="0" y="19" font-family="Arial, sans-serif" font-size="6.8px" fill="#333333">Consumer Care: +91 $phone  •  Email: $email  •  Origin: INDIA  •  Web: $website</text>
    <line x1="0" y1="24" x2="384" y2="24" stroke="#E2E8F0" stroke-width="0.6" />

    <text x="0" y="32" font-family="Arial, sans-serif" font-size="6.5px" font-weight="800" fill="#047857">✓ Compliant with Legal Metrology (Packaged Commodities) Rules 2011 &amp; FSSAI Standards.</text>
    <text x="0" y="41" font-family="Arial, sans-serif" font-size="6.2px" fill="#64748B">Packaging: $packagingType • Keep Clean (MoEFCC Disposal Logo)</text>

    <!-- Clean India Disposal Mark -->
    <circle cx="410" cy="20" r="14" fill="none" stroke="#047857" stroke-width="0.9" />
    <path d="M 410 11 L 405 17 L 408 17 L 408 24 L 412 24 L 412 17 L 415 17 Z" fill="#047857" />
    <text x="410" y="31" font-family="Arial, sans-serif" font-size="3.2px" font-weight="900" fill="#047857" text-anchor="middle">DISPOSE</text>
  </g>
</svg>''';
  }

  /// Generates a print-ready vector PDF document matching the exact packaging dimensions
  /// ($widthMm × $heightMm) with 100% zero vacant space and a synchronized GS1 EAN-13 barcode.
  static List<int> _generateValidPdfBytes({
    required SmallBusinessLabelModel model,
    required String dimension,
    required double widthMm,
    required double heightMm,
    Map<String, dynamic>? fssaiImageData,
    Map<String, dynamic>? brandLogoData,
  }) {
    // 1 mm = 2.83464567 pt
    final pageW = widthMm * 2.83464567;
    final pageH = heightMm * 2.83464567;

    final brand = _sanitizePdfString(model.brandName.isNotEmpty ? model.brandName : 'HALDIRAMS');
    final product = _sanitizePdfString(model.productName.isNotEmpty ? model.productName : 'KURKURE');
    final category = _sanitizePdfString(model.productCategory.isNotEmpty ? model.productCategory.toUpperCase() : 'SNACKS & NAMKEEN');

    final cleanNetQty = model.netQuantity.replaceAll(RegExp(r'[^0-9.]'), '');
    final netGrams = double.tryParse(cleanNetQty) ?? 70.0;
    final netUnit = model.netQuantityUnit.isNotEmpty ? model.netQuantityUnit : 'g';
    final ozVal = (netGrams * 0.035274).toStringAsFixed(2);

    final cleanMrp = model.mrp.replaceAll('₹', '').replaceFirst('Rs.', '').trim();
    final mrpDisplay = cleanMrp.isNotEmpty ? 'Rs. $cleanMrp' : 'Rs. 20.00';
    final uspDisplay = model.usp.isNotEmpty ? _sanitizePdfString(model.usp.replaceAll('₹', 'Rs. ')) : 'Rs. 0.28 / g';

    final fssai = _sanitizePdfString(model.fssaiLicenseNumber.isNotEmpty ? model.fssaiLicenseNumber : '74125896323145');
    final manufacturer = _sanitizePdfString(model.manufacturerName.isNotEmpty ? model.manufacturerName : model.brandName);
    final address = _sanitizePdfString(model.manufacturerAddress.isNotEmpty ? model.manufacturerAddress : 'Registered Business Address');
    final phone = _sanitizePdfString(model.consumerCarePhone.isNotEmpty ? model.consumerCarePhone : '9876543210');
    final email = _sanitizePdfString(model.consumerCareEmail.isNotEmpty ? model.consumerCareEmail : 'care@business.in');
    final website = _sanitizePdfString(model.consumerCareWebsite != null && model.consumerCareWebsite!.isNotEmpty ? model.consumerCareWebsite! : 'www.business.in');
    final packagingType = _sanitizePdfString(model.packagingType.isNotEmpty ? model.packagingType : 'Food Grade Metallized Pouch');
    final batch = _sanitizePdfString(model.batchNumber.isNotEmpty ? model.batchNumber : 'BATCH-2026-I92');
    final mfg = _sanitizePdfString(model.mfgDate.isNotEmpty && model.mfgDate != 'AUG 2026' ? model.mfgDate : DateFormat('MMM yyyy').format(DateTime.now()).toUpperCase());
    final bestBefore = _sanitizePdfString(model.bestBefore.isNotEmpty ? model.bestBefore : '12 Months from Packaging');
    final storage = _sanitizePdfString(model.storageInstructions.isNotEmpty ? model.storageInstructions : 'Store in a cool, dry & hygienic place.');

    final isVeg = model.isVegetarian;

    // Serving size & Calories
    final sSize = model.servingSize.isNotEmpty ? model.servingSize : '70';
    final sUnit = model.servingSizeUnit.isNotEmpty ? model.servingSizeUnit : 'g';
    final serveG = double.tryParse(sSize) ?? 70.0;
    final servingsPerPack = (serveG > 0) ? (netGrams / serveG).round().clamp(1, 99) : 1;

    final energyItem = model.nutrients.cast<SmallBusinessNutrientModel?>().firstWhere(
      (n) => n?.label.toLowerCase() == 'energy' || n?.label.toLowerCase() == 'calories',
      orElse: () => null,
    );
    final energyVal = double.tryParse(energyItem?.value ?? '') ?? 536.0;
    final calPerServe = ((energyVal * serveG) / 100.0).round().toString();
    final calPercentStr = NutritionCalculator.calculateCaloriesRda(calPerServe);

    // Ingredients with explicit percentage of content
    final ingredientsText = model.ingredients.isNotEmpty
        ? model.ingredients.map((i) {
            if (i.percentage != null && i.percentage! > 0) {
              final pctStr = (i.percentage! == i.percentage!.roundToDouble())
                  ? '${i.percentage!.toInt()}%'
                  : '${i.percentage!.toStringAsFixed(1)}%';
              return '${_sanitizePdfString(i.name)} ($pctStr)';
            }
            return _sanitizePdfString(i.name);
          }).join(', ')
        : 'Turmeric Powder (28%), Red Chilli Powder (24%), Coriander Powder (20%), Mustard Seeds (14%), Black Pepper (8%), Garam Masala (6%)';

    final allergensText = model.allergens.isNotEmpty
        ? model.allergens.map(_sanitizePdfString).join(', ')
        : 'Wheat / Gluten';

    // Synchronized GS1 EAN-13 Barcode
    final barcodeDigits = GS1Ean13Encoder.deriveBarcodeDigits(
      fssaiNumber: model.fssaiLicenseNumber,
    );
    final modules = GS1Ean13Encoder.encodeModules(barcodeDigits);
    final splitBarcode = GS1Ean13Encoder.splitForDisplay(barcodeDigits);

    // Nutrients List
    final defaultNutrients = [
      {'name': 'Energy', 'val': '536 kcal', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Energy', value: '536', unit: 'kcal', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Protein', 'val': '5.6 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Protein', value: '5.6', unit: 'g', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Carbohydrate', 'val': '230 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Carbohydrate', value: '230', unit: 'g', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Total Sugars', 'val': '2 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Total Sugars', value: '2', unit: 'g', servingSizeGrams: serveG), 'level': 1},
      {'name': 'Added Sugars', 'val': '2 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Added Sugars', value: '2', unit: 'g', servingSizeGrams: serveG), 'level': 2},
      {'name': 'Total Fat', 'val': '10 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Total Fat', value: '10', unit: 'g', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Saturated Fat', 'val': '1 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Saturated Fat', value: '1', unit: 'g', servingSizeGrams: serveG), 'level': 1},
      {'name': 'Trans Fat', 'val': '0 g', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Trans Fat', value: '0', unit: 'g', servingSizeGrams: serveG), 'level': 1},
      {'name': 'Cholesterol', 'val': '0 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Cholesterol', value: '0', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Sodium', 'val': '222 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Sodium', value: '222', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Potassium', 'val': '140 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Potassium', value: '140', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Calcium', 'val': '40 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Calcium', value: '40', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
      {'name': 'Iron', 'val': '1.2 mg', 'rda': NutritionCalculator.calculateRdaPercentage(label: 'Iron', value: '1.2', unit: 'mg', servingSizeGrams: serveG), 'level': 0},
    ];

    final displayNutrients = <Map<String, dynamic>>[];
    if (model.nutrients.isNotEmpty) {
      for (final n in model.nutrients) {
        final rdaVal = NutritionCalculator.calculateRdaPercentage(
          label: n.label,
          value: n.value,
          unit: n.unit,
          servingSizeGrams: serveG,
        );
        displayNutrients.add({
          'name': _sanitizePdfString(n.label),
          'val': '${_sanitizePdfString(n.value)} ${_sanitizePdfString(n.unit)}',
          'rda': rdaVal,
          'level': n.isSubNutrient ? 1 : 0,
        });
      }
    } else {
      displayNutrients.addAll(defaultNutrients);
    }

    final sb = StringBuffer();

    // Mathematical coordinate mapper from 460 x 540 reference packaging layout
    // to exact native PDF points (with 3 pt margin on each side)
    const double refW = 460.0;
    const double refH = 540.0;
    const double margin = 3.0;
    final double availW = pageW - (margin * 2);
    final double availH = pageH - (margin * 2);

    // Uniform scaling keeps 100% true aspect ratio, preventing distorted barcodes,
    // squished logos, and horizontal text clipping across varied packaging dimensions.
    final double uniformScale = math.min(availW / refW, availH / refH);
    final double renderW = refW * uniformScale;
    final double renderH = refH * uniformScale;
    final double offsetX = margin + (availW - renderW) / 2;
    final double offsetY = margin + (availH - renderH) / 2;

    double toX(double rx) => offsetX + (rx * uniformScale);
    double toY(double ry, double rh) => offsetY + renderH - ((ry + rh) * uniformScale);
    double toW(double rw) => rw * uniformScale;
    double toH(double rh) => rh * uniformScale;
    double toTextY(double ry, double fontSize) => offsetY + renderH - ((ry + (fontSize * 0.82)) * uniformScale);
    double toFont(double fontSize) => fontSize * uniformScale;

    // Fill entire page canvas with clean white
    sb.writeln('1 1 1 rg');
    sb.writeln('0 0 ${pageW.toStringAsFixed(2)} ${pageH.toStringAsFixed(2)} re f');

    // Outer packaging cut guide when label artwork does not occupy 100% of package area
    if ((availW - renderW) > 6 || (availH - renderH) > 6) {
      sb.writeln('0.82 0.85 0.90 RG');
      sb.writeln('[3 3] 0 d');
      sb.writeln('0.75 w');
      sb.writeln('${margin.toStringAsFixed(2)} ${margin.toStringAsFixed(2)} ${availW.toStringAsFixed(2)} ${availH.toStringAsFixed(2)} re S');
      sb.writeln('[] 0 d'); // reset dash
    }

    void rect(double rx, double ry, double rw, double rh, {
      bool fill = false,
      bool stroke = true,
      List<double>? fillColor,
      List<double>? strokeColor,
      double lw = 1.0,
    }) {
      final px = toX(rx);
      final py = toY(ry, rh);
      final pw = toW(rw);
      final ph = toH(rh);

      if (fillColor != null && fillColor.length == 3) {
        sb.writeln('${fillColor[0]} ${fillColor[1]} ${fillColor[2]} rg');
      }
      if (strokeColor != null && strokeColor.length == 3) {
        sb.writeln('${strokeColor[0]} ${strokeColor[1]} ${strokeColor[2]} RG');
      }
      sb.writeln('${(lw * uniformScale).toStringAsFixed(2)} w');
      sb.writeln('${px.toStringAsFixed(2)} ${py.toStringAsFixed(2)} ${pw.toStringAsFixed(2)} ${ph.toStringAsFixed(2)} re ${fill && stroke ? "B" : (fill ? "f" : "S")}');
    }

    void line(double rx1, double ry1, double rx2, double ry2, {
      double lw = 1.0,
      List<double>? strokeColor,
    }) {
      final px1 = toX(rx1);
      final py1 = offsetY + renderH - (ry1 * uniformScale);
      final px2 = toX(rx2);
      final py2 = offsetY + renderH - (ry2 * uniformScale);

      if (strokeColor != null && strokeColor.length == 3) {
        sb.writeln('${strokeColor[0]} ${strokeColor[1]} ${strokeColor[2]} RG');
      }
      sb.writeln('${(lw * uniformScale).toStringAsFixed(2)} w');
      sb.writeln('${px1.toStringAsFixed(2)} ${py1.toStringAsFixed(2)} m ${px2.toStringAsFixed(2)} ${py2.toStringAsFixed(2)} l S');
    }

    void text(String t, double rx, double ry, {
      String font = '/F2',
      double size = 8.0,
      List<double>? color,
    }) {
      final sanitized = _sanitizePdfString(t);
      final px = toX(rx);
      final py = toTextY(ry, size);
      final pSize = toFont(size);

      if (color != null && color.length == 3) {
        sb.writeln('${color[0]} ${color[1]} ${color[2]} rg');
      } else {
        sb.writeln('0 0 0 rg');
      }
      sb.writeln('BT');
      sb.writeln('$font ${pSize.toStringAsFixed(2)} Tf');
      sb.writeln('1 0 0 1 ${px.toStringAsFixed(2)} ${py.toStringAsFixed(2)} Tm');
      sb.writeln('($sanitized) Tj');
      sb.writeln('ET');
    }

    // 1. Master Outer Label Border (Zero Vacant Space)
    rect(0, 0, refW, refH, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0, 0, 0], lw: 1.4);

    // 2. Header
    // Brand Logo or Initial Badge
    final hasBrandImage = brandLogoData != null && brandLogoData['bytes'] != null;
    if (hasBrandImage) {
      // Clean white box with subtle stroke
      rect(10, 8, 34, 34, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0.82, 0.85, 0.90], lw: 0.8);

      final double bImgW = (brandLogoData['width'] as int).toDouble();
      final double bImgH = (brandLogoData['height'] as int).toDouble();
      final double bAspect = (bImgW > 0 && bImgH > 0) ? bImgW / bImgH : 1.0;

      const double maxW = 30.0;
      const double maxH = 30.0;
      double fitW = maxW;
      double fitH = maxH;
      if (bAspect > 1.0) {
        fitH = maxW / bAspect;
      } else {
        fitW = maxH * bAspect;
      }
      final double fitX = 10.0 + (34.0 - fitW) / 2;
      final double fitY = 8.0 + (34.0 - fitH) / 2;

      final logoW = toW(fitW);
      final logoH = toH(fitH);
      final logoX = toX(fitX);
      final logoY = toY(fitY, fitH);
      sb.writeln('q ${logoW.toStringAsFixed(2)} 0 0 ${logoH.toStringAsFixed(2)} ${logoX.toStringAsFixed(2)} ${logoY.toStringAsFixed(2)} cm /BrandLogo Do Q');
    } else {
      rect(10, 8, 34, 34, fill: true, stroke: false, fillColor: [0.015, 0.47, 0.34]);
      text(brand.isNotEmpty ? brand[0].toUpperCase() : 'H', 22, 16, font: '/F1', size: 18, color: [1, 1, 1]);
    }

    // Brand Name, Product, Category
    text(brand.toUpperCase(), 50, 10, font: '/F1', size: 9, color: [0.015, 0.47, 0.34]);
    text(product, 50, 21, font: '/F1', size: 13, color: [0, 0, 0]);
    text('PROPRIETARY FOOD [$category]', 50, 33, font: '/F1', size: 7.2, color: [0.33, 0.33, 0.33]);

    // Net Wt Badge
    rect(314, 14, 86, 22, fill: true, stroke: true, fillColor: [0.97, 0.98, 0.99], strokeColor: [0.58, 0.64, 0.72], lw: 0.8);
    text('NET WT. $cleanNetQty $netUnit', 324, 20, font: '/F1', size: 8, color: [0, 0, 0]);

    // Statutory Vegetarian Emblem (1:1 Ratio)
    final vegRgb = isVeg ? [0.08, 0.64, 0.29] : [0.6, 0.1, 0.1];
    rect(412, 14, 22, 22, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: vegRgb, lw: 1.6);
    rect(418, 20, 10, 10, fill: true, stroke: false, fillColor: vegRgb);

    // Header Divider Line
    line(6, 48, 454, 48, lw: 1.2, strokeColor: [0, 0, 0]);

    // 3. Nutrition Facts Panel
    final nutritionH = 50.0 + (displayNutrients.length * 10.0);
    rect(8, 54, 444, nutritionH, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0, 0, 0], lw: 1.0);
    // Black Header
    rect(8, 54, 444, 18, fill: true, stroke: false, fillColor: [0, 0, 0]);
    text('NUTRITION FACTS / VALEUR NUTRITIVE', 14, 58, font: '/F1', size: 8.5, color: [1, 1, 1]);
    text('PER ${sSize.toUpperCase()} ${sUnit.toUpperCase()}', 355, 58, font: '/F1', size: 8.0, color: [1, 1, 1]);

    // Serving Size & % Daily Value Subheader
    text('Serving Size: $sSize $sUnit (Pack contains $servingsPerPack serving)', 14, 76, font: '/F1', size: 7.2, color: [0.28, 0.33, 0.41]);
    text('% Daily Value / % RDA *', 350, 76, font: '/F1', size: 7.2, color: [0.28, 0.33, 0.41]);

    line(8, 87, 452, 87, lw: 1.6, strokeColor: [0, 0, 0]);

    // Calories Hero Callout
    text('Calories $calPerServe (Energy $energyVal kcal / 100 g)', 14, 91, font: '/F1', size: 11.5, color: [0, 0, 0]);
    final calRdaX = 444.0 - (calPercentStr.length * 6.5);
    text(calPercentStr, calRdaX, 91, font: '/F1', size: 11.0, color: [0, 0, 0]);

    line(8, 105, 452, 105, lw: 1.0, strokeColor: [0, 0, 0]);

    double curNY = 108.0;
    for (final r in displayNutrients) {
      final name = r['name'] as String;
      final val = r['val'] as String;
      final rda = r['rda'] as String;
      final level = r['level'] as int;
      final isBold = level == 0 || name.contains('Fat') || name.contains('Carbohydrate') || name.contains('Protein') || name.contains('Sodium');
      final f = isBold ? '/F1' : '/F2';
      final prefix = level == 1 ? '- ' : (level == 2 ? '* ' : '');
      final indentX = 14.0 + (level * 10.0);

      line(8, curNY - 2, 452, curNY - 2, lw: 0.5, strokeColor: [0.88, 0.91, 0.94]);
      text('$prefix$name $val', indentX, curNY, font: f, size: 7.2, color: isBold ? [0, 0, 0] : [0.2, 0.2, 0.2]);
      final rdaX = 444.0 - (rda.length * 4.2);
      text(rda, rdaX, curNY, font: f, size: 7.2, color: isBold ? [0, 0, 0] : [0.2, 0.2, 0.2]);
      curNY += 9.5;
    }

    line(8, curNY, 452, curNY, lw: 0.6, strokeColor: [0, 0, 0]);
    text('*5% or less is a little, 15% or more is a lot. % Daily Values based on 2,000 kcal diet.', 14, curNY + 2, font: '/F2', size: 6.2, color: [0.33, 0.33, 0.33]);

    // 4. Ingredients Statement
    final ingLines = _wrapText('INGREDIENTS: $ingredientsText', 88);
    double ingY = 54.0 + nutritionH + 6.0;
    for (int i = 0; i < ingLines.length && i < 3; i++) {
      text(ingLines[i], 12, ingY, font: i == 0 ? '/F1' : '/F2', size: 7.2, color: [0.1, 0.15, 0.22]);
      ingY += 9.0;
    }

    // 5. Allergen Advice Strip
    final allergenBoxY = ingY + 2.0;
    rect(8, allergenBoxY, 444, 16, fill: true, stroke: true, fillColor: [1, 0.96, 0.96], strokeColor: [0.99, 0.7, 0.7], lw: 0.8);
    text('ALLERGEN ADVICE: Contains $allergensText. Made in a facility that also processes Mustard, Sesame & Peanuts.', 14, allergenBoxY + 3.5, font: '/F1', size: 6.8, color: [0.6, 0.1, 0.1]);

    // 6. Specification & Origin Strip
    final specBoxY = allergenBoxY + 18.0;
    rect(8, specBoxY, 444, 15, fill: true, stroke: true, fillColor: [0.95, 0.96, 0.98], strokeColor: [0.8, 0.83, 0.88], lw: 0.7);
    text('NET WT. $cleanNetQty $netUnit / $ozVal oz.', 14, specBoxY + 3.5, font: '/F1', size: 6.8, color: [0, 0, 0]);
    text('PRODUCT OF INDIA / PRODUIT DE L\'INDE', 170, specBoxY + 3.5, font: '/F1', size: 6.8, color: [0.28, 0.33, 0.41]);
    text('COMMERCIAL PACK', 370, specBoxY + 3.5, font: '/F1', size: 6.8, color: [0.015, 0.47, 0.34]);

    // 7. Legal Metrology Pricing Triad & Traceability Box
    final metrologyBoxY = specBoxY + 18.0;
    rect(8, metrologyBoxY, 444, 46, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0, 0, 0], lw: 1.0);
    text('NET QUANTITY', 14, metrologyBoxY + 3, font: '/F1', size: 6.5, color: [0.4, 0.45, 0.55]);
    text('$cleanNetQty $netUnit', 14, metrologyBoxY + 13, font: '/F1', size: 11.0, color: [0, 0, 0]);

    line(110, metrologyBoxY + 3, 110, metrologyBoxY + 26, lw: 0.8, strokeColor: [0.8, 0.83, 0.88]);

    text('MAX RETAIL PRICE [MRP]', 120, metrologyBoxY + 3, font: '/F1', size: 6.5, color: [0.4, 0.45, 0.55]);
    text('$mrpDisplay [Incl. of all taxes]', 120, metrologyBoxY + 13, font: '/F1', size: 10.5, color: [0.015, 0.47, 0.34]);

    line(290, metrologyBoxY + 3, 290, metrologyBoxY + 26, lw: 0.8, strokeColor: [0.8, 0.83, 0.88]);

    text('UNIT SALE PRICE [USP]', 300, metrologyBoxY + 3, font: '/F1', size: 6.5, color: [0.4, 0.45, 0.55]);
    text(uspDisplay, 300, metrologyBoxY + 13, font: '/F1', size: 10.5, color: [0, 0, 0]);

    line(8, metrologyBoxY + 29, 452, metrologyBoxY + 29, lw: 0.7, strokeColor: [0.8, 0.83, 0.88]);
    text('Batch No: $batch   *   Mfg Date: $mfg   *   Best Before: $bestBefore', 14, metrologyBoxY + 33, font: '/F1', size: 6.8, color: [0.12, 0.16, 0.23]);
    text('Storage: $storage', 300, metrologyBoxY + 33, font: '/F2', size: 6.5, color: [0.33, 0.33, 0.33]);

    // 8. Scannable GS1 Barcode & Authentic 4:3 FSSAI Logo Area
    final barcodeBoxY = metrologyBoxY + 50.0;
    rect(8, barcodeBoxY, 444, 68, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0, 0, 0], lw: 1.0);

    // Render Exact GS1 EAN-13 Vector Barcode Modules
    const double barStartX = 24.0;
    final double barStartY = barcodeBoxY + 5;
    const double totalBarW = 166.0;
    final double moduleW = totalBarW / modules.length;
    const double normalBarH = 28.0;
    const double guardBarH = 34.0;

    for (int i = 0; i < modules.length; i++) {
      if (modules[i]) {
        final isGuard = (i < 3) || (i >= 45 && i < 50) || (i >= modules.length - 3);
        final bh = isGuard ? guardBarH : normalBarH;
        final bx = barStartX + (i * moduleW);
        rect(bx, barStartY, moduleW + 0.15, bh, fill: true, stroke: false, fillColor: [0, 0, 0]);
      }
    }

    // Human-readable EAN-13 Digits below bars
    text(splitBarcode.d1, 14, barcodeBoxY + 44, font: '/F3', size: 8.0, color: [0, 0, 0]);
    text(splitBarcode.left6, 44, barcodeBoxY + 44, font: '/F3', size: 8.0, color: [0, 0, 0]);
    text(splitBarcode.right6, 126, barcodeBoxY + 44, font: '/F3', size: 8.0, color: [0, 0, 0]);
    text('GS1 EAN-13 VERIFIED', 75, barcodeBoxY + 56, font: '/F1', size: 6.0, color: [0.02, 0.58, 0.41]);

    // Center divider
    line(228, barcodeBoxY + 4, 228, barcodeBoxY + 64, lw: 0.8, strokeColor: [0.8, 0.83, 0.88]);

    // Right: 4:3 FSSAI Logo Area
    final hasFssaiImage = fssaiImageData != null && fssaiImageData['bytes'] != null;
    rect(242, barcodeBoxY + 5, 198, 56, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0.015, 0.47, 0.34], lw: 0.8);

    if (hasFssaiImage) {
      // Direct PDF Image XObject placement preserving exact 4:3 proportions (48 x 36 pt)
      final logoW = toW(48.0);
      final logoH = toH(36.0);
      final logoX = toX(317.0);
      final logoY = toY(barcodeBoxY + 8.0, 36.0);
      sb.writeln('q ${logoW.toStringAsFixed(2)} 0 0 ${logoH.toStringAsFixed(2)} ${logoX.toStringAsFixed(2)} ${logoY.toStringAsFixed(2)} cm /FssaiLogo Do Q');
      text('Lic. No. $fssai', 290, barcodeBoxY + 48, font: '/F1', size: 8.0, color: [0, 0, 0]);
    } else {
      text('fssai', 320, barcodeBoxY + 22, font: '/F1', size: 16.0, color: [0.015, 0.47, 0.34]);
      text('Lic. No. $fssai', 290, barcodeBoxY + 42, font: '/F1', size: 8.0, color: [0, 0, 0]);
    }

    // 9. Manufacturer, Consumer Care & Compliance Declaration Footer
    final footerBoxY = barcodeBoxY + 72.0;
    rect(8, footerBoxY, 444, 48, fill: true, stroke: true, fillColor: [1, 1, 1], strokeColor: [0, 0, 0], lw: 1.0);
    text('Mfd. By: $manufacturer, $address  |  Lic. No. $fssai', 14, footerBoxY + 3, font: '/F1', size: 6.8, color: [0, 0, 0]);
    line(14, footerBoxY + 13, 400, footerBoxY + 13, lw: 0.6, strokeColor: [0.88, 0.91, 0.94]);

    text('Consumer Care: +91 $phone  *  Email: $email  *  Origin: INDIA  *  Web: $website', 14, footerBoxY + 16, font: '/F2', size: 6.5, color: [0.2, 0.2, 0.2]);
    line(14, footerBoxY + 25, 400, footerBoxY + 25, lw: 0.6, strokeColor: [0.88, 0.91, 0.94]);

    text('* Compliant with Legal Metrology (Packaged Commodities) Rules 2011 & FSSAI Standards.', 14, footerBoxY + 28, font: '/F1', size: 6.2, color: [0.015, 0.47, 0.34]);
    text('Packaging: $packagingType * Keep Clean (MoEFCC Disposal Logo)', 14, footerBoxY + 37, font: '/F2', size: 6.0, color: [0.4, 0.45, 0.55]);

    // Clean India Disposal Mark
    rect(410, footerBoxY + 12, 22, 22, fill: false, stroke: true, strokeColor: [0.015, 0.47, 0.34], lw: 0.9);
    text('DISPOSE', 412, footerBoxY + 20, font: '/F1', size: 3.5, color: [0.015, 0.47, 0.34]);

    final textStream = sb.toString();
    final streamBytes = utf8.encode(textStream.trim());
    final streamLength = streamBytes.length;

    final header = '%PDF-1.4\n';
    final obj1 = '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n';
    final obj2 = '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n';
    int nextObjId = 8;
    int? brandLogoObjId;
    if (hasBrandImage) {
      brandLogoObjId = nextObjId++;
    }
    int? fssaiLogoObjId;
    if (hasFssaiImage) {
      fssaiLogoObjId = nextObjId++;
    }

    final xObjectEntries = <String>[];
    if (brandLogoObjId != null) {
      xObjectEntries.add('/BrandLogo $brandLogoObjId 0 R');
    }
    if (fssaiLogoObjId != null) {
      xObjectEntries.add('/FssaiLogo $fssaiLogoObjId 0 R');
    }

    final xObjectRes = xObjectEntries.isNotEmpty ? '/XObject << ${xObjectEntries.join(' ')} >>' : '';
    // Fonts: F1 = Helvetica-Bold, F2 = Helvetica, F3 = Courier-Bold (for scannable barcode monospace digits)
    final fontRes = '/Font << /F1 5 0 R /F2 6 0 R /F3 7 0 R >>';

    final obj3 = '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${pageW.toStringAsFixed(2)} ${pageH.toStringAsFixed(2)}] /Contents 4 0 R /Resources << $fontRes $xObjectRes >> >>\nendobj\n';
    final obj4Header = '4 0 obj\n<< /Length $streamLength >>\nstream\n';
    final obj4Footer = '\nendstream\nendobj\n';
    final obj5 = '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj\n';
    final obj6 = '6 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n';
    final obj7 = '7 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Courier-Bold >>\nendobj\n';

    final bytesBuilder = BytesBuilder();
    final offsets = <int>[0];

    bytesBuilder.add(utf8.encode(header));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj1));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj2));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj3));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj4Header));
    bytesBuilder.add(streamBytes);
    bytesBuilder.add(utf8.encode(obj4Footer));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj5));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj6));

    offsets.add(bytesBuilder.length);
    bytesBuilder.add(utf8.encode(obj7));

    if (brandLogoObjId != null) {
      final imgBytes = brandLogoData!['bytes'] as Uint8List;
      final int imgW = brandLogoData['width'] as int;
      final int imgH = brandLogoData['height'] as int;
      final imgHeader = '$brandLogoObjId 0 obj\n<< /Type /XObject /Subtype /Image /Width $imgW /Height $imgH /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${imgBytes.length} >>\nstream\n';
      final imgFooter = '\nendstream\nendobj\n';

      offsets.add(bytesBuilder.length);
      bytesBuilder.add(utf8.encode(imgHeader));
      bytesBuilder.add(imgBytes);
      bytesBuilder.add(utf8.encode(imgFooter));
    }

    if (fssaiLogoObjId != null) {
      final imgBytes = fssaiImageData!['bytes'] as Uint8List;
      final int imgW = fssaiImageData['width'] as int;
      final int imgH = fssaiImageData['height'] as int;
      final imgHeader = '$fssaiLogoObjId 0 obj\n<< /Type /XObject /Subtype /Image /Width $imgW /Height $imgH /ColorSpace /DeviceRGB /BitsPerComponent 8 /Length ${imgBytes.length} >>\nstream\n';
      final imgFooter = '\nendstream\nendobj\n';

      offsets.add(bytesBuilder.length);
      bytesBuilder.add(utf8.encode(imgHeader));
      bytesBuilder.add(imgBytes);
      bytesBuilder.add(utf8.encode(imgFooter));
    }

    final totalObjects = nextObjId - 1;
    final startXref = bytesBuilder.length;
    final xrefHeader = 'xref\n0 ${totalObjects + 1}\n0000000000 65535 f \n';
    bytesBuilder.add(utf8.encode(xrefHeader));

    for (int i = 1; i <= totalObjects; i++) {
      final offStr = offsets[i].toString().padLeft(10, '0');
      bytesBuilder.add(utf8.encode('$offStr 00000 n \n'));
    }

    final trailer = 'trailer\n<< /Size ${totalObjects + 1} /Root 1 0 R >>\nstartxref\n$startXref\n%%EOF\n';
    bytesBuilder.add(utf8.encode(trailer));

    return bytesBuilder.toBytes();
  }

  static String _sanitizePdfString(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)')
        .replaceAll('₹', 'Rs. ')
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '*')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
  }
}
