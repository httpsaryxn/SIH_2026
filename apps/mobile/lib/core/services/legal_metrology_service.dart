import 'package:flutter/foundation.dart';
import 'package:legal_metrology/legal_metrology.dart';

import '../models/multi_capture_payload.dart';
import '../models/pending_capture.dart';
import 'ml_scanner_client.dart';

/// Result of an on-device Legal Metrology audit, mapped into the vocabulary the
/// app already uses (`compliance_status`, `compliance_issues`,
/// `detected_declarations`).
class LmAuditResult {
  /// One of: `compliant`, `warning`, `potential_violation`, `unverified`.
  final String complianceStatus;

  /// `[{type, severity, message, rule_id, legal_reference}, ...]`
  final List<Map<String, dynamic>> complianceIssues;

  /// The declarations the pipeline actually read/resolved from the label + GTIN.
  final Map<String, dynamic> detectedDeclarations;

  /// The full report, for a detailed results screen.
  final ComplianceReport report;

  const LmAuditResult({
    required this.complianceStatus,
    required this.complianceIssues,
    required this.detectedDeclarations,
    required this.report,
  });

  int get scorePercent => (report.score.finalScore * 100).round();
  String get starLabel => report.score.starLabel;
  String? get firstIssueMessage =>
      complianceIssues.isNotEmpty ? complianceIssues.first['message'] as String? : null;
}

/// Wraps the `legal_metrology` package for use from the consumer / regulator
/// scan flows. All calls are offline-capable; registry enrichment happens only
/// when a network is available.
class LegalMetrologyService {
  LegalMetrologyService._();

  static final LabelOcrService _ocr = LabelOcrService();
  static final BarcodeScannerService _barcode = BarcodeScannerService();

  /// Audit a captured packaging photo. OCR + bar code are read on device; the
  /// user's typed fields (from ScannerModalSheet) seed anything OCR missed.
  static Future<LmAuditResult> auditCapture({
    required PendingCapture capture,
    String? productName,
    String? netQuantity,
    double? mrp,
    String? gs1IndiaKey,
  }) async {
    final path = capture.localPath;

    final ocr = await _ocr.recognise(path);
    final parsed = parseOcr(ocr);
    final pkg = toPackageData(parsed);

    pkg.commodityName ??= (productName != null && productName.trim().isNotEmpty)
        ? productName.trim()
        : null;
    if (pkg.mrpValue == null && mrp != null) {
      pkg.mrpValue = mrp;
    }
    if (pkg.netQuantityValue == null &&
        netQuantity != null &&
        netQuantity.trim().isNotEmpty) {
      final q = parseQuantity(netQuantity);
      if (q.value != null) {
        pkg.netQuantityValue = q.value;
        pkg.netQuantityUnit = q.unit;
      }
    }

    String? barcode;
    try {
      final codes = await _barcode.scanFile(path);
      if (codes.isNotEmpty) barcode = codes.first.value;
    } catch (_) {
      // no bar code on the photo — fine
    }

    final report = await runLabelAudit(
      pkg,
      barcode: barcode,
      lookupConfig: LookupConfig(gs1IndiaKey: gs1IndiaKey),
    );
    return _map(report);
  }

  /// Attempt a full compliance audit via the remote ML Scanner service.
  ///
  /// Sends front/back/ruler images as multipart form data to the FastAPI
  /// endpoint.  Falls back to the on-device [auditCapture] when the service
  /// is unreachable or returns an error.
  static Future<MlScannerResult?> auditCaptureRemote({
    required PendingCapture capture,
    MultiCapturePayload? multiCapture,
    String? productName,
    String? geminiApiKey,
  }) async {
    final isUp = await MlScannerClient.isAvailable();
    if (!isUp) {
      debugPrint('[LegalMetrologyService] ML Scanner service is not reachable at ${MlScannerClient.baseUrl}');
      throw Exception('Server health check failed at ${MlScannerClient.baseUrl}/health');
    }

    final frontPath = multiCapture?.frontLabel?.localPath ?? capture.localPath;
    final backPath = multiCapture?.curvedSurface?.localPath;
    final rulerPath = multiCapture?.scaleReference?.localPath;

    debugPrint('[LegalMetrologyService] Transmitting 3 captured samples to ML Scanner:');
    debugPrint('  - Front: $frontPath');
    debugPrint('  - Back/Side: $backPath');
    debugPrint('  - Ruler/Scale: $rulerPath');

    return await MlScannerClient.analyzeLabels(
      frontImagePath: frontPath,
      backImagePath: backPath,
      rulerImagePath: rulerPath,
      geminiApiKey: geminiApiKey,
    );
  }

  /// Deterministic audit from a bar code / GTIN alone (no photo).
  static Future<LmAuditResult> auditBarcode(
    String code, {
    String? gs1IndiaKey,
  }) async {
    final report = await runBarcodeAudit(
      code,
      lookupConfig: LookupConfig(gs1IndiaKey: gs1IndiaKey),
    );
    return _map(report);
  }

  // ---------------------------------------------------------------------------
  // Mapping into the app's vocabulary
  // ---------------------------------------------------------------------------
  static LmAuditResult _map(ComplianceReport r) => LmAuditResult(
        complianceStatus: _status(r),
        complianceIssues: _issues(r),
        detectedDeclarations: _declarations(r),
        report: r,
      );

  static String _status(ComplianceReport r) {
    if (r.score.criticalFailures > 0) return 'potential_violation';
    if (r.diff.failed.isNotEmpty) return 'warning';
    final unverifiedMandatory = r.diff.inconclusive.any(
      (x) => x.severity == 'CRITICAL' || x.severity == 'MAJOR',
    );
    if (unverifiedMandatory) return 'unverified';
    if (r.diff.warnings.isNotEmpty) return 'warning';
    return 'compliant';
  }

  static String _severity(String ruleSeverity) {
    switch (ruleSeverity) {
      case 'CRITICAL':
        return 'potential_violation';
      case 'MAJOR':
        return 'warning';
      default:
        return 'warning';
    }
  }

  static Map<String, dynamic> _issue(RuleResult x, {String? severityOverride}) => {
        'type': x.ruleName,
        'severity': severityOverride ?? _severity(x.severity),
        'message': x.detail,
        'rule_id': x.ruleId,
        'legal_reference': x.legalReference,
      };

  static List<Map<String, dynamic>> _issues(ComplianceReport r) => [
        for (final x in r.diff.failed) _issue(x),
        for (final x in r.diff.warnings) _issue(x, severityOverride: 'warning'),
        for (final x in r.diff.inconclusive
            .where((x) => x.severity == 'CRITICAL' || x.severity == 'MAJOR'))
          _issue(x, severityOverride: 'unverified'),
      ];

  static Map<String, dynamic> _declarations(ComplianceReport r) {
    final p = r.packageData;
    final netQty = p.netQuantityValue == null
        ? null
        : '${p.netQuantityValue} ${p.netQuantityUnit ?? ''}'.trim();
    final care = [p.consumerCarePhone, p.consumerCareEmail]
        .where((e) => e != null && e.isNotEmpty)
        .join(' | ');
    return {
      'commodity_name': p.commodityName,
      'manufacturer': p.manufacturerName,
      'manufacturer_address': p.manufacturerAddress,
      'net_quantity': netQty,
      'mrp': p.mrpValue,
      'mrp_inclusive_of_taxes': p.mrpIncludesTax,
      'mfg_date': p.manufactureDate,
      'best_before': p.bestBefore,
      'country_of_origin': p.countryOfOrigin,
      'fssai_license_no': p.fssaiLicenseNumber,
      'consumer_care_info': care.isEmpty ? null : care,
      'barcode': {
        'value': p.barcodeValue,
        'gtin_format': p.barcodeGtinFormat,
        'checksum_valid': p.barcodeChecksumValid,
        'gs1_india': p.barcodeIsGs1India,
        'restricted': p.barcodeIsRestricted,
        'issuing_country': p.barcodeIssuingCountry,
      },
      'identified_in': p.productDataSources,
      'score_pct': (r.score.finalScore * 100).round(),
      'star_rating': r.score.starRating,
      'star_label': r.score.starLabel,
      'recommendations': r.recommendations,
    };
  }
}
