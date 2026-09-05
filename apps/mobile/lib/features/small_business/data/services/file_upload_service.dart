import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Conditional import for web HTML vs non-web
import 'file_upload_service_stub.dart'
    if (dart.library.html) 'file_upload_service_web.dart' as platform_picker;

class UploadedFilePayload {
  final String name;
  final int sizeInBytes;
  final String? dataUrl;
  final String extension;

  const UploadedFilePayload({
    required this.name,
    required this.sizeInBytes,
    this.dataUrl,
    required this.extension,
  });

  String get formattedSize {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DetectedLabReportData {
  final String fileName;
  final String laboratoryName;
  final String reportDate;
  final String sampleDescription;
  final List<DetectedIngredient> ingredients;
  final List<String> allergens;
  final Map<String, String> nutrients;

  const DetectedLabReportData({
    required this.fileName,
    required this.laboratoryName,
    required this.reportDate,
    required this.sampleDescription,
    required this.ingredients,
    required this.allergens,
    required this.nutrients,
  });
}

class DetectedIngredient {
  final String name;
  final double percentage;

  const DetectedIngredient({required this.name, required this.percentage});
}

class FileUploadService {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Opens the system file manager/gallery to pick an image (PNG, JPG, JPEG, WEBP)
  static Future<UploadedFilePayload?> pickImage() async {
    try {
      if (kIsWeb) {
        return await platform_picker.pickFile(
          acceptedTypes: 'image/png,image/jpeg,image/jpg,image/webp,image/svg+xml',
        );
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return null;

      final bytes = await image.readAsBytes();
      final ext = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'png';
      final mimeType = (ext == 'jpg' || ext == 'jpeg')
          ? 'image/jpeg'
          : (ext == 'webp' ? 'image/webp' : 'image/png');
      final base64Str = base64Encode(bytes);
      final dataUrl = 'data:$mimeType;base64,$base64Str';

      return UploadedFilePayload(
        name: image.name,
        sizeInBytes: bytes.length,
        dataUrl: dataUrl,
        extension: '.$ext',
      );
    } catch (e) {
      debugPrint('Error opening system file picker for image: $e');
      return null;
    }
  }

  /// Opens the system file manager to pick a document (PDF, PNG, JPG, JPEG, DOCX)
  static Future<UploadedFilePayload?> pickLabReportDocument() async {
    try {
      if (kIsWeb) {
        return await platform_picker.pickFile(
          acceptedTypes: 'application/pdf,image/png,image/jpeg,image/jpg,.pdf,.png,.jpg,.jpeg',
        );
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'pdf';
        return UploadedFilePayload(
          name: image.name.isNotEmpty ? image.name : 'NABL_Accredited_Lab_Report.pdf',
          sizeInBytes: bytes.length,
          dataUrl: 'data:application/pdf;base64,${base64Encode(bytes)}',
          extension: '.$ext',
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error opening system file picker for document: $e');
      return null;
    }
  }

  /// Opens the system file manager or chooser modal for Lab Reports / CoA
  static Future<UploadedFilePayload?> pickLabReportChooser(BuildContext context) async {
    final selected = await showModalBottomSheet<UploadedFilePayload>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upload Lab Report / CoA',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a file from device or load a verified NABL Certificate of Analysis:',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFDCFCE7),
                  child: Icon(Icons.upload_file_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Browse File / Scan from Device', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: const Text('Upload PDF, JPG, PNG from device', style: TextStyle(fontSize: 11.5)),
                onTap: () async {
                  Navigator.of(ctx).pop(await pickLabReportDocument());
                },
              ),
              const Divider(height: 10),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFEF3C7),
                  child: Icon(Icons.science_outlined, color: Color(0xFFD97706)),
                ),
                title: const Text('Sample: Mango Pickle CoA (NABL Certified)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: const Text('8 ingredients, mustard allergen & full nutritional profile', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.of(ctx).pop(
                    UploadedFilePayload(
                      name: 'NABL_Pickle_Lab_Report.pdf',
                      sizeInBytes: 245000,
                      dataUrl: '',
                      extension: '.pdf',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE0E7FF),
                  child: Icon(Icons.science_outlined, color: Color(0xFF4F46E5)),
                ),
                title: const Text('Sample: Potato Chips / Snack CoA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: const Text('Potato formulation, energy 536 kcal, fat & sodium profile', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.of(ctx).pop(
                    UploadedFilePayload(
                      name: 'Potato_Chips_Analysis_CoA.pdf',
                      sizeInBytes: 312000,
                      dataUrl: '',
                      extension: '.pdf',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFCE7F3),
                  child: Icon(Icons.science_outlined, color: Color(0xFFDB2777)),
                ),
                title: const Text('Sample: Raw Organic Honey CoA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: const Text('Forest honey test with carbohydrates & trace pollen', style: TextStyle(fontSize: 11.5)),
                onTap: () {
                  Navigator.of(ctx).pop(
                    UploadedFilePayload(
                      name: 'Organic_Honey_NABL_CoA.pdf',
                      sizeInBytes: 189000,
                      dataUrl: '',
                      extension: '.pdf',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    return selected;
  }

  /// AI / OCR Simulation parser for Certificate of Analysis (CoA) & Accredited Lab Reports
  static Future<DetectedLabReportData> parseLabReport(UploadedFilePayload file) async {
    // Simulate brief OCR analysis delay
    await Future.delayed(const Duration(milliseconds: 600));

    final nameLower = file.name.toLowerCase();

    if (nameLower.contains('chip') || nameLower.contains('snack') || nameLower.contains('potato')) {
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'NABL Accredited Food Quality Assurance Lab',
        reportDate: 'Aug 2026',
        sampleDescription: 'Crispy Potato Chips CoA',
        ingredients: const [
          DetectedIngredient(name: 'Potato', percentage: 81.0),
          DetectedIngredient(name: 'Edible Vegetable Oil (Palmolein)', percentage: 14.0),
          DetectedIngredient(name: 'Seasoning (Milk Solids, Spices, Iodised Salt)', percentage: 5.0),
        ],
        allergens: const ['Milk Solids'],
        nutrients: const {
          'Calories': '536',
          'Total Fat': '33.7',
          'Saturated Fat': '15.0',
          'Trans Fat': '0.1',
          'Sodium': '512',
          'Carbohydrates': '54.2',
          'Dietary Fiber': '4.1',
          'Total Sugars': '1.2',
          'Added Sugars': '0',
          'Protein': '6.8',
        },
      );
    } else if (nameLower.contains('honey') || nameLower.contains('sweet')) {
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'NABL Accredited Testing Laboratory (ISO 17025)',
        reportDate: 'Aug 2026',
        sampleDescription: 'Raw Forest Honey CoA',
        ingredients: const [
          DetectedIngredient(name: 'Raw Wild Forest Honey', percentage: 99.5),
          DetectedIngredient(name: 'Natural Pollen Extracts', percentage: 0.5),
        ],
        allergens: const ['Pollen Allergens (trace)'],
        nutrients: const {
          'Calories': '304',
          'Total Fat': '0',
          'Saturated Fat': '0',
          'Sodium': '4',
          'Carbohydrates': '82.4',
          'Dietary Fiber': '0.2',
          'Total Sugars': '82.1',
          'Added Sugars': '0',
          'Protein': '0.3',
          'Potassium (K)': '52',
          'Iron (Fe)': '0.42',
        },
      );
    } else if (nameLower.contains('oil') || nameLower.contains('ghee')) {
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'FSSAI Certified Food Analysis Lab',
        reportDate: 'Aug 2026',
        sampleDescription: 'Cold Pressed Mustard Oil CoA',
        ingredients: const [
          DetectedIngredient(name: 'Cold Pressed Mustard Oil (Kachi Ghani)', percentage: 99.8),
          DetectedIngredient(name: 'Natural Vitamin E (Antioxidant)', percentage: 0.2),
        ],
        allergens: const ['Mustard & Mustard Seeds'],
        nutrients: const {
          'Calories': '884',
          'Total Fat': '100',
          'Saturated Fat': '11.6',
          'Monounsaturated Fatty Acids (MUFA)': '59.2',
          'Polyunsaturated Fatty Acids (PUFA)': '21.2',
          'Trans Fat': '0',
          'Sodium': '0',
          'Carbohydrates': '0',
          'Protein': '0',
          'Vitamin E (Tocopherol)': '34',
        },
      );
    } else {
      // Default: Comprehensive Spices / Pickle / General Formulation CoA
      return DetectedLabReportData(
        fileName: file.name,
        laboratoryName: 'Agmark / NABL Accredited Food Analytical Lab',
        reportDate: 'Aug 2026',
        sampleDescription: 'Artisanal Formulation Test Certificate',
        ingredients: const [
          DetectedIngredient(name: 'Raw Mango Pieces (Farm Fresh)', percentage: 61.5),
          DetectedIngredient(name: 'Cold Pressed Mustard Oil', percentage: 18.2),
          DetectedIngredient(name: 'Iodised Salt', percentage: 12.0),
          DetectedIngredient(name: 'Red Chilli Powder (Lal Mirch)', percentage: 4.1),
          DetectedIngredient(name: 'Fenugreek Seeds (Methi)', percentage: 1.8),
          DetectedIngredient(name: 'Turmeric Powder (Haldi)', percentage: 1.4),
          DetectedIngredient(name: 'Asafoetida (Compounded Hing)', percentage: 0.6),
          DetectedIngredient(name: 'Acidity Regulator (INS 260)', percentage: 0.4),
        ],
        allergens: const [
          'Mustard & Mustard Seeds',
          'Wheat / Gluten (in Compounded Hing)',
        ],
        nutrients: const {
          'Calories': '188',
          'Total Fat': '14.5',
          'Saturated Fat': '1.8',
          'Trans Fat': '0',
          'Sodium': '2450',
          'Carbohydrates': '12.4',
          'Dietary Fiber': '3.2',
          'Total Sugars': '2.1',
          'Added Sugars': '0',
          'Protein': '2.4',
          'Vitamin C (Ascorbic Acid)': '18.5',
          'Iron (Fe)': '1.4',
        },
      );
    }
  }
}
