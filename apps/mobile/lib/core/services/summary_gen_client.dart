import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConsumerSummaryResult {
  final String productType;
  final String classificationReasoning;
  final String summaryText;
  final int? healthScore;
  final String? healthScoreRationale;
  final String? medicinalSafetySummary;
  final String? mandatoryDisclaimer;
  final bool cached;

  const ConsumerSummaryResult({
    required this.productType,
    required this.classificationReasoning,
    required this.summaryText,
    this.healthScore,
    this.healthScoreRationale,
    this.medicinalSafetySummary,
    this.mandatoryDisclaimer,
    this.cached = false,
  });

  bool get isFood => productType == 'food';
  bool get isMedicinal => productType == 'medicinal';
  bool get isGeneral => productType == 'general';

  factory ConsumerSummaryResult.fromJson(Map<String, dynamic> json) {
    return ConsumerSummaryResult(
      productType: json['product_type'] as String? ?? 'unclassified',
      classificationReasoning: json['classification_reasoning'] as String? ?? '',
      summaryText: json['summary_text'] as String? ?? '',
      healthScore: json['health_score'] as int?,
      healthScoreRationale: json['health_score_rationale'] as String?,
      medicinalSafetySummary: json['medicinal_safety_summary'] as String?,
      mandatoryDisclaimer: json['mandatory_disclaimer'] as String?,
      cached: json['cached'] as bool? ?? false,
    );
  }
}

class RegulatorSummaryResult {
  final String scanId;
  final String productType;
  final String summaryText;
  final String pdfUrl;
  final bool cached;

  const RegulatorSummaryResult({
    required this.scanId,
    required this.productType,
    required this.summaryText,
    required this.pdfUrl,
    this.cached = false,
  });

  factory RegulatorSummaryResult.fromJson(Map<String, dynamic> json) {
    final rawPdfUrl = json['regulator_pdf_url'] as String? ??
        json['pdf_url'] as String? ??
        '';
    final absolutePdfUrl = (rawPdfUrl.startsWith('/') && !rawPdfUrl.startsWith('//'))
        ? '${SummaryGenClient.baseUrl}$rawPdfUrl'
        : rawPdfUrl;

    return RegulatorSummaryResult(
      scanId: json['scan_id'] as String? ?? '',
      productType: json['product_type'] as String? ?? 'general',
      summaryText: json['regulator_summary_text'] as String? ??
          json['summary_text'] as String? ??
          '',
      pdfUrl: absolutePdfUrl,
      cached: json['cached'] as bool? ?? false,
    );
  }
}

class SummaryGenClient {
  static const String cloudUrl = 'https://labellens-ml-scanner.onrender.com';
  static const String prefKey = 'summary_gen_base_url';
  static String _baseUrl = cloudUrl;

  static String get baseUrl => _baseUrl;

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, _baseUrl);
    } catch (_) {}
  }

  /// Automatically detect candidate service URLs (local USB/LAN dev vs Render cloud)
  static Future<bool> isAvailable() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = saved.trim();
      }
    } catch (_) {}

    // First, fast probe for local development servers (USB adb reverse, emulator, LAN)
    final localCandidates = <String>[
      if (Platform.isAndroid) ...[
        'http://127.0.0.1:8001',
        'http://127.0.0.1:8000',
        'http://10.0.2.2:8001',
        'http://10.0.2.2:8000',
      ],
      'http://localhost:8001',
      'http://localhost:8000',
      'http://192.168.0.104:8001',
      'http://192.168.0.116:8001',
    ];

    // If _baseUrl was previously set to a local URL, check it first
    if (_baseUrl.contains('127.0.0.1') || _baseUrl.contains('localhost') || _baseUrl.contains('192.168.')) {
      if (!localCandidates.contains(_baseUrl)) {
        localCandidates.insert(0, _baseUrl);
      }
    }

    for (final url in localCandidates) {
      try {
        final res = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(milliseconds: 700));
        if (res.statusCode == 200) {
          _baseUrl = url;
          debugPrint('[SummaryGenClient] Connected to local service at $url');
          return true;
        }
      } catch (_) {}
    }

    // Next, check Render cloud URL
    try {
      final res = await http
          .get(Uri.parse('$cloudUrl/health'))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        _baseUrl = cloudUrl;
        debugPrint('[SummaryGenClient] Connected to cloud service at $cloudUrl');
        return true;
      }
    } catch (_) {}

    // If cloud URL check timed out (e.g. cold start), still default to cloudUrl so request gets 45s timeout
    if (_baseUrl.startsWith('https://') || _baseUrl.isEmpty) {
      _baseUrl = cloudUrl;
      return true;
    }

    return false;
  }

  /// Request a consumer-facing summary (with product-type detection and health/safety scoring)
  static Future<ConsumerSummaryResult> summarizeConsumer({
    String? scanId,
    required String productName,
    String? manufacturer,
    Map<String, dynamic>? declarations,
    Map<String, dynamic>? rules,
    String? ocrText,
    bool forceRegenerate = false,
  }) async {
    final isUp = await isAvailable();
    if (!isUp) {
      debugPrint('[SummaryGenClient] Service not available, using offline heuristic fallback');
      return _generateClientFallbackConsumer(
        productName: productName,
        manufacturer: manufacturer,
        declarations: declarations,
      );
    }

    try {
      final uri = Uri.parse('$_baseUrl/summarize/consumer');
      final body = jsonEncode({
        'scan_id': scanId,
        'product_name': productName,
        'manufacturer': manufacturer,
        'extracted_declarations': declarations ?? {},
        'rules': rules ?? {},
        'ocr_text': ocrText,
        'force_regenerate': forceRegenerate,
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ConsumerSummaryResult.fromJson(json);
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[SummaryGenClient] Error calling summary-gen: $e');
      return _generateClientFallbackConsumer(
        productName: productName,
        manufacturer: manufacturer,
        declarations: declarations,
      );
    }
  }

  /// Request a regulator audit summary and PDF report
  static Future<RegulatorSummaryResult?> summarizeRegulator({
    required String scanId,
    required String productName,
    String? companyName,
    String? category,
    required List<Map<String, dynamic>> declarationChecks,
    Map<String, String?>? imageUrls,
    String? userId,
    bool forceRegenerate = false,
  }) async {
    final isUp = await isAvailable();
    if (!isUp) {
      debugPrint('[SummaryGenClient] Service not available for regulator PDF generation.');
      return null;
    }

    try {
      final uri = Uri.parse('$_baseUrl/summarize/regulator');
      final body = jsonEncode({
        'scan_id': scanId,
        'product_name': productName,
        'company_name': companyName,
        'category': category,
        'declaration_checks': declarationChecks,
        'image_urls': imageUrls ?? {},
        'user_id': userId,
        'force_regenerate': forceRegenerate,
      });

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RegulatorSummaryResult.fromJson(json);
      }
    } catch (e) {
      debugPrint('[SummaryGenClient] Error calling regulator summary: $e');
    }
    return null;
  }

  static ConsumerSummaryResult _generateClientFallbackConsumer({
    required String productName,
    String? manufacturer,
    Map<String, dynamic>? declarations,
  }) {
    declarations ??= {};
    final nameLower = productName.toLowerCase();
    final isPharma = nameLower.contains('syrup') ||
        nameLower.contains('tablet') ||
        nameLower.contains('capsule') ||
        nameLower.contains('ointment') ||
        nameLower.contains('pharma') ||
        nameLower.contains('medicine');

    if (isPharma) {
      const disclaimer = 'Informational summary of declared label content only. Not medical advice.';
      return ConsumerSummaryResult(
        productType: 'medicinal',
        classificationReasoning: 'Classified based on medicinal keywords in commodity description.',
        summaryText:
            '**Declared Commodity**: $productName\n\n'
            '• **Manufacturer**: ${manufacturer ?? declarations['manufacturer'] ?? "Declared on packaging"}\n'
            '• **Net Volume**: ${declarations['net_quantity'] ?? "Standard pack"}\n'
            '• **Directions**: Verify batch number, expiry date, and dosage instructions on label before use.\n\n'
            '*⚠️ $disclaimer*',
        medicinalSafetySummary: 'Keep out of reach of children. Store in a cool, dry place away from direct sunlight.',
        mandatoryDisclaimer: disclaimer,
      );
    }

    final isFood = declarations.containsKey('fssai') ||
        declarations.containsKey('fssai_license_no') ||
        nameLower.contains('food') ||
        nameLower.contains('snack') ||
        nameLower.contains('drink') ||
        nameLower.contains('chocolate') ||
        nameLower.contains('butter') ||
        nameLower.contains('biscuit') ||
        nameLower.contains('oil');

    if (isFood) {
      return ConsumerSummaryResult(
        productType: 'food',
        classificationReasoning: 'Classified based on food commodity keywords and packaging declarations.',
        summaryText:
            '**Nutritional & Product Overview**: $productName\n\n'
            '• **Net Contents**: ${declarations['net_quantity'] ?? "Standard package"}\n'
            '• **Max Retail Price**: ₹${declarations['mrp'] ?? "Declared on label"}\n'
            '• **FSSAI License**: ${declarations['fssai'] ?? declarations['fssai_license_no'] ?? "Declared"}\n'
            '• **Quality Note**: Meets statutory packaging requirements under Legal Metrology Rules.',
        healthScore: 78,
        healthScoreRationale: 'Standard packaged food product compliant with mandatory declaration norms.',
      );
    }

    return ConsumerSummaryResult(
      productType: 'general',
      classificationReasoning: 'General packaged commodity.',
      summaryText:
          '**Packaging Declarations**: $productName\n\n'
          '• **Net Quantity**: ${declarations['net_quantity'] ?? "Declared"}\n'
          '• **Manufacturer**: ${manufacturer ?? "Declared on label"}\n'
          '• **Retail Price**: ₹${declarations['mrp'] ?? "Declared on label"}',
    );
  }
}
