import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Response from the ML Scanner `/analyze` endpoint.
class MlScannerResult {
  final String scanId;
  final String timestamp;
  final String analysisMode;
  final String engineDescription;
  final MlScannerScore score;
  final MlScannerRules rules;
  final Map<String, dynamic> barcode;
  final Map<String, dynamic> product;
  final List<String> recommendations;
  final String? reportId;
  final Map<String, bool> imagesUsed;

  const MlScannerResult({
    required this.scanId,
    required this.timestamp,
    required this.analysisMode,
    required this.engineDescription,
    required this.score,
    required this.rules,
    required this.barcode,
    required this.product,
    required this.recommendations,
    this.reportId,
    required this.imagesUsed,
  });

  factory MlScannerResult.fromJson(Map<String, dynamic> json) {
    return MlScannerResult(
      scanId: json['scan_id'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      analysisMode: json['analysis_mode'] as String? ?? 'unknown',
      engineDescription: json['engine_description'] as String? ?? '',
      score: MlScannerScore.fromJson(
          json['score'] as Map<String, dynamic>? ?? {}),
      rules: MlScannerRules.fromJson(
          json['rules'] as Map<String, dynamic>? ?? {}),
      barcode: (json['barcode'] as Map<String, dynamic>?) ?? {},
      product: (json['product'] as Map<String, dynamic>?) ?? {},
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      reportId: json['report_id'] as String?,
      imagesUsed: (json['images_used'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v as bool? ?? false)) ??
          {},
    );
  }

  /// Overall compliance status derived from the score.
  String get complianceStatus {
    if (score.failedRules > 0 && score.finalScore < 60) {
      return 'potential_violation';
    }
    if (score.failedRules > 0) return 'warning';
    if (score.finalScore >= 85) return 'compliant';
    return 'warning';
  }

  /// Converts the ML results into declaration checks conforming to the app schema:
  /// (field_name, extracted_value, status, rule_citation, confidence_pct, rule_description)
  List<Map<String, dynamic>> toDeclarationChecks(String scanId) {
    final allRules = [
      ...rules.failed,
      ...rules.warnings,
      ...rules.inconclusive,
      ...rules.passed,
    ];
    return [
      for (final r in allRules)
        {
          'scan_id': scanId,
          'field_name': r.ruleName,
          'extracted_value': r.evidence ?? '',
          'confidence_percent': (score.finalScore).round(),
          'status': r.standardStatus,
          'rule_citation': r.legalReference ?? r.ruleId,
          'rule_description': r.detail,
        },
    ];
  }
}

class MlScannerScore {
  final double finalScore;
  final int starRating;
  final String starLabel;
  final double ebmScore;
  final double ruleScore;
  final int passedRules;
  final int failedRules;

  const MlScannerScore({
    required this.finalScore,
    required this.starRating,
    required this.starLabel,
    required this.ebmScore,
    required this.ruleScore,
    required this.passedRules,
    required this.failedRules,
  });

  factory MlScannerScore.fromJson(Map<String, dynamic> json) {
    return MlScannerScore(
      finalScore: (json['final_score'] as num?)?.toDouble() ?? 0.0,
      starRating: json['star_rating'] as int? ?? 1,
      starLabel: json['star_label'] as String? ?? 'Unknown',
      ebmScore: (json['ebm_score'] as num?)?.toDouble() ?? 0.0,
      ruleScore: (json['rule_score'] as num?)?.toDouble() ?? 0.0,
      passedRules: json['passed_rules'] as int? ?? 0,
      failedRules: json['failed_rules'] as int? ?? 0,
    );
  }
}

class MlRuleResult {
  final String ruleId;
  final String ruleName;
  final String status;
  final String severity;
  final String detail;
  final String? evidence;
  final String? legalReference;

  const MlRuleResult({
    required this.ruleId,
    required this.ruleName,
    required this.status,
    required this.severity,
    required this.detail,
    this.evidence,
    this.legalReference,
  });

  String get standardStatus {
    switch (status.toUpperCase()) {
      case 'PASS':
        return 'Compliant';
      case 'FAIL':
        return 'Violation';
      case 'WARNING':
        return 'Warning';
      default:
        return 'Unable to Verify';
    }
  }

  factory MlRuleResult.fromJson(Map<String, dynamic> json) {
    return MlRuleResult(
      ruleId: json['rule_id'] as String? ?? '',
      ruleName: json['rule_name'] as String? ?? '',
      status: json['status'] as String? ?? 'INCONCLUSIVE',
      severity: json['severity'] as String? ?? 'MINOR',
      detail: json['detail'] as String? ?? '',
      evidence: json['evidence'] as String?,
      legalReference: json['legal_reference'] as String?,
    );
  }
}

class MlScannerRules {
  final List<MlRuleResult> passed;
  final List<MlRuleResult> failed;
  final List<MlRuleResult> warnings;
  final List<MlRuleResult> notApplicable;
  final List<MlRuleResult> inconclusive;

  const MlScannerRules({
    required this.passed,
    required this.failed,
    required this.warnings,
    required this.notApplicable,
    required this.inconclusive,
  });

  factory MlScannerRules.fromJson(Map<String, dynamic> json) {
    List<MlRuleResult> parseRules(dynamic list) =>
        (list as List<dynamic>?)
            ?.map((e) =>
                MlRuleResult.fromJson(e as Map<String, dynamic>? ?? {}))
            .toList() ??
        [];
    return MlScannerRules(
      passed: parseRules(json['passed']),
      failed: parseRules(json['failed']),
      warnings: parseRules(json['warnings']),
      notApplicable: parseRules(json['not_applicable']),
      inconclusive: parseRules(json['inconclusive']),
    );
  }

  int get totalRules =>
      passed.length +
      failed.length +
      warnings.length +
      notApplicable.length +
      inconclusive.length;
}

/// HTTP client for the ML Scanner FastAPI service.
///
/// Sends captured label images to the server for real compliance analysis.
class MlScannerClient {
  MlScannerClient._();

  static const String prefKey = 'ml_scanner_base_url';

  /// Active base URL of the ML Scanner service.
  static String _baseUrl = _defaultBaseUrl();

  /// Returns the current active base URL.
  static String get baseUrl => _baseUrl;

  static String _defaultBaseUrl() {
    return 'https://labellens-ml-scanner.onrender.com';
  }

  /// Allow overriding the base URL and persisting it to SharedPreferences.
  static Future<void> setBaseUrl(String url) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    _baseUrl = cleanUrl;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, cleanUrl);
    } catch (_) {}
  }

  /// Ping a specific candidate URL's `/health` endpoint.
  static Future<bool> testConnection(String url) async {
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    try {
      final res = await http
          .get(Uri.parse('$cleanUrl/health'))
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Check if the ML scanner service is reachable, auto-detecting between
  /// stored URL, host LAN IP, physical device reverse proxy, and Android emulator loopback.
  static Future<bool> isAvailable() async {
    // Try to read saved user preference first
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = saved.trim();
      }
    } catch (_) {}

    final candidates = <String>[
      _baseUrl,
      'https://labellens-ml-scanner.onrender.com', // Cloud hosted on Render
      'http://192.168.0.116:8000', // Workstation LAN IP (reachable by physical phone on same Wi-Fi)
      if (Platform.isAndroid) ...[
        'http://127.0.0.1:8000', // Physical Android phone via `adb reverse tcp:8000 tcp:8000`
        'http://10.0.2.2:8000',  // Android emulator loopback
      ],
      'http://127.0.0.1:8000',
      'http://localhost:8000',
    ];

    debugPrint('[MlScannerClient] Probing ML Scanner health across candidate URLs: $candidates');

    for (final url in candidates.toSet()) {
      try {
        final uri = Uri.parse('$url/health');
        final timeout = url.startsWith('https://')
            ? const Duration(seconds: 8)
            : const Duration(seconds: 2);
        final response = await http.get(uri).timeout(timeout);
        if (response.statusCode == 200) {
          debugPrint('[MlScannerClient] ✓ Connected to ML Scanner service at $url');
          _baseUrl = url;
          // Persist working URL
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(prefKey, url);
          } catch (_) {}
          return true;
        }
      } catch (e) {
        debugPrint('[MlScannerClient] ✗ Candidate $url unreachable: $e');
      }
    }

    debugPrint('[MlScannerClient] Could not reach ML Scanner at any candidate URL.');
    return false;
  }

  /// Analyze label images via the ML scanner service.
  ///
  /// Sends all provided images (`front`, `back`, `ruler`) directly to FastAPI `/analyze`.
  /// Returns an [MlScannerResult] on success, or throws an [MlScannerException].
  static Future<MlScannerResult> analyzeLabels({
    required String frontImagePath,
    String? backImagePath,
    String? rulerImagePath,
    String? barcodeNumber,
    String? geminiApiKey,
  }) async {
    final uri = Uri.parse('$_baseUrl/analyze');
    debugPrint('[MlScannerClient] POST $uri — uploading captured evidence...');
    final request = http.MultipartRequest('POST', uri);

    // 1. Attach front image (required)
    final frontFile = File(frontImagePath);
    if (!frontFile.existsSync()) {
      throw MlScannerException(
        statusCode: 400,
        message: 'Front image does not exist on disk: $frontImagePath',
      );
    }
    final frontSizeKb = (frontFile.lengthSync() / 1024).toStringAsFixed(1);
    debugPrint('  → Front Image: $frontImagePath ($frontSizeKb KB)');
    request.files.add(
      await http.MultipartFile.fromPath('front', frontImagePath),
    );

    // 2. Attach back / curved surface image (optional)
    if (backImagePath != null && backImagePath.isNotEmpty) {
      final backFile = File(backImagePath);
      if (backFile.existsSync()) {
        final backSizeKb = (backFile.lengthSync() / 1024).toStringAsFixed(1);
        debugPrint('  → Back Image: $backImagePath ($backSizeKb KB)');
        request.files.add(
          await http.MultipartFile.fromPath('back', backImagePath),
        );
      } else {
        debugPrint('  → Back Image provided but file not found on disk: $backImagePath');
      }
    }

    // 3. Attach scale / ruler image (optional)
    if (rulerImagePath != null && rulerImagePath.isNotEmpty) {
      final rulerFile = File(rulerImagePath);
      if (rulerFile.existsSync()) {
        final rulerSizeKb = (rulerFile.lengthSync() / 1024).toStringAsFixed(1);
        debugPrint('  → Ruler Image: $rulerImagePath ($rulerSizeKb KB)');
        request.files.add(
          await http.MultipartFile.fromPath('ruler', rulerImagePath),
        );
      } else {
        debugPrint('  → Ruler Image provided but file not found on disk: $rulerImagePath');
      }
    }

    // Form fields
    if (barcodeNumber != null && barcodeNumber.isNotEmpty) {
      request.fields['barcode_number'] = barcodeNumber;
      debugPrint('  → Barcode Number: $barcodeNumber');
    }

    // API key via header
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      request.headers['X-Gemini-Api-Key'] = geminiApiKey;
    }

    final stopwatch = Stopwatch()..start();
    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );
    } catch (e) {
      debugPrint('[MlScannerClient] Network error during upload to $uri: $e');
      throw MlScannerException(
        statusCode: 503,
        message: 'Failed to connect to ML Scanner service at $_baseUrl ($e)',
      );
    }

    final response = await http.Response.fromStream(streamedResponse);
    stopwatch.stop();
    debugPrint('[MlScannerClient] Received HTTP ${response.statusCode} in ${stopwatch.elapsedMilliseconds}ms');

    if (response.statusCode != 200) {
      String errorMessage = 'Server returned HTTP ${response.statusCode}';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = body['error'] as String? ?? errorMessage;
      } catch (_) {}
      throw MlScannerException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = MlScannerResult.fromJson(json);
    debugPrint(
      '[MlScannerClient] ML Analysis Parsed Successfully: '
      'Score: ${result.score.finalScore}% (${result.score.starLabel}), '
      'Passed: ${result.rules.passed.length}, Failed: ${result.rules.failed.length}, '
      'Warnings: ${result.rules.warnings.length}',
    );
    return result;
  }

  /// Verify a barcode number via the ML scanner service.
  static Future<Map<String, dynamic>> scanBarcode(String code) async {
    final uri = Uri.parse('$_baseUrl/scan-barcode');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'barcode_number': code,
            'lookup': true,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw MlScannerException(
        statusCode: response.statusCode,
        message: body['error'] as String? ?? 'Unknown error',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}


/// Exception thrown when the ML Scanner service returns an error.
class MlScannerException implements Exception {
  final int statusCode;
  final String message;

  const MlScannerException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'MlScannerException($statusCode): $message';
}
