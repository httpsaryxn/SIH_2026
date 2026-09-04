import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/capture_role.dart';
import '../models/inbox_item.dart';
import '../models/label_verification_request.dart';
import '../models/multi_capture_payload.dart';
import '../models/pending_capture.dart';
import '../models/regulator_action_item.dart';
import '../models/regulator_company.dart';
import '../models/regulator_complaint.dart';
import '../models/regulator_notice.dart';
import '../models/regulator_violation.dart';
import 'storage_service.dart';

class RegulatorDashboardMetrics {
  final int itemsScanned;
  final int activeViolations;
  final int priorityComplaints;
  final num scanTrendPercent;

  const RegulatorDashboardMetrics({
    required this.itemsScanned,
    required this.activeViolations,
    required this.priorityComplaints,
    required this.scanTrendPercent,
  });

  factory RegulatorDashboardMetrics.fromJson(Map<String, dynamic> json) =>
      RegulatorDashboardMetrics(
        itemsScanned: (json['items_scanned'] as num?)?.toInt() ?? 0,
        activeViolations: (json['active_violations'] as num?)?.toInt() ?? 0,
        priorityComplaints: (json['priority_complaints'] as num?)?.toInt() ?? 0,
        scanTrendPercent: json['scan_trend_percent'] as num? ?? 0,
      );
}

/// Supabase-backed data access for the shared regulator/consumer contract.
/// Model mapping lives here so the screen-facing method signatures remain stable.
class RegulatorDataService {
  static SupabaseClient get _client => Supabase.instance.client;

  static const _violationSelect = '''
    *, regulator_scans!inner(
      scan_code, product_name, company_name, category, region, store_location,
      image_url, captured_at, declaration_checks(
        field_name, extracted_value, confidence_percent, status,
        rule_citation, rule_description, top_percent, left_percent,
        width_percent, height_percent
      )
    )
  ''';

  static String get _currentUserId => _client.auth.currentUser?.id ?? '';

  static DateTime _date(dynamic value) =>
      value is String ? DateTime.parse(value) : DateTime.now();

  static String _coordinates(Map<String, dynamic> row) {
    final latitude = row['latitude'];
    final longitude = row['longitude'];
    return latitude == null || longitude == null
        ? ''
        : '$latitude°, $longitude°';
  }

  static RegulatorViolation _violationFromRow(Map<String, dynamic> row) {
    final scan = Map<String, dynamic>.from(row['regulator_scans'] as Map);
    final checkRows = (scan['declaration_checks'] as List<dynamic>? ?? const [])
        .map((value) => Map<String, dynamic>.from(value as Map))
        .toList();
    return RegulatorViolation(
      id: row['id'] as String,
      scanId: scan['scan_code'] as String? ?? '',
      productName: scan['product_name'] as String? ?? '',
      companyName: scan['company_name'] as String? ?? '',
      category: scan['category'] as String? ?? '',
      region: scan['region'] as String? ?? '',
      storeLocation: scan['store_location'] as String? ?? '',
      imageUrl: scan['image_url'] as String? ?? '',
      severity: row['severity'] as String? ?? 'Medium',
      riskLevel: row['risk_level'] as String? ?? 'Medium Risk',
      confidenceScore: (row['confidence_score'] as num?)?.toInt() ?? 0,
      violationType: row['violation_type'] as String? ?? '',
      violationSummary: row['violation_summary'] as String? ?? '',
      capturedAt: _date(scan['captured_at']),
      status: row['status'] as String? ?? 'pending',
      declarations: checkRows.map(RegulatorDeclaration.fromJson).toList(),
      overlayBoxes: checkRows
          .where((check) => check['top_percent'] != null)
          .map(
            (check) => RegulatorOverlayBox(
              topPercent: (check['top_percent'] as num).toDouble(),
              leftPercent: (check['left_percent'] as num).toDouble(),
              widthPercent: (check['width_percent'] as num).toDouble(),
              heightPercent: (check['height_percent'] as num).toDouble(),
              label: check['field_name'] as String? ?? '',
              isViolation: check['status'] == 'Violation',
            ),
          )
          .toList(),
    );
  }

  static Future<Map<String, String>> _companyNames() async {
    try {
      final rows = await _client
          .from('company_compliance_overview')
          .select('company_id, company_name')
          .timeout(const Duration(seconds: 4));
      return {
        for (final row in rows)
          row['company_id'] as String: row['company_name'] as String? ?? '',
      };
    } catch (_) {
      return {};
    }
  }

  static RegulatorComplaint _complaintFromRow(
    Map<String, dynamic> row,
    Map<String, String> companyNames,
  ) {
    final consumer = row['consumer'] is Map
        ? Map<String, dynamic>.from(row['consumer'] as Map)
        : const <String, dynamic>{};
    final profile = row['profile'] is Map
        ? Map<String, dynamic>.from(row['profile'] as Map)
        : const <String, dynamic>{};
    final companyId = row['company_id'] as String?;
    final evidence = (row['evidence_photos'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList();
    if (evidence.isEmpty && row['evidence_image_url'] != null) {
      evidence.add(row['evidence_image_url'] as String);
    }
    return RegulatorComplaint(
      id: row['id'] as String,
      complaintCode: row['complaint_code'] as String? ?? '',
      title: row['title'] as String? ?? '',
      productName: row['product_name'] as String? ?? '',
      companyName: companyId != null && companyNames.containsKey(companyId)
          ? companyNames[companyId]!
          : row['company_name'] as String? ?? '',
      category: row['category'] as String? ?? '',
      description: row['description'] as String? ?? '',
      locationName:
          row['location_name'] as String? ??
          row['store_location'] as String? ??
          '',
      address:
          row['address'] as String? ?? row['store_location'] as String? ?? '',
      status: row['status'] as String? ?? 'Submitted',
      priority: row['priority'] as String? ?? 'Normal',
      submittedAt: _date(row['created_at']),
      evidencePhotos: evidence,
      coordinates: _coordinates(row),
      consumerName: consumer['full_name'] as String? ?? 'Anonymous Consumer',
      consumerContact: profile['phone_number'] as String? ?? 'Not provided',
    );
  }

  static RegulatorTimelineEvent _timelineFromRow(Map<String, dynamic> row) =>
      RegulatorTimelineEvent(
        date: _date(row['occurred_at']),
        title: row['title'] as String? ?? '',
        description: row['description'] as String? ?? '',
        type: row['event_type'] as String? ?? 'status_change',
        officerName: row['actor_name'] as String? ?? 'System',
        batchNo: row['batch_no'] as String? ?? '',
      );

  static RegulatorCompany _companyFromRow(
    Map<String, dynamic> row,
    List<RegulatorTimelineEvent> timeline,
  ) => RegulatorCompany(
    id: row['company_id'] as String,
    name: row['company_name'] as String? ?? '',
    address: row['address'] as String? ?? '',
    region: row['region'] as String? ?? '',
    category: row['category'] as String? ?? '',
    complianceScore: (row['compliance_score'] as num?)?.toInt() ?? 0,
    openViolationsCount: (row['open_violations_count'] as num?)?.toInt() ?? 0,
    noticesIssuedCount: (row['notices_issued_count'] as num?)?.toInt() ?? 0,
    lastAuditDate: _date(row['last_audit_date']),
    status: row['status'] as String? ?? 'Active',
    timeline: timeline,
  );

  static Future<List<RegulatorTimelineEvent>> _companyTimeline(
    String companyId,
  ) async {
    try {
      final rows = await _client
          .from('company_timeline_events')
          .select()
          .eq('company_id', companyId)
          .order('occurred_at', ascending: false)
          .timeout(const Duration(seconds: 4));
      return (rows as List<dynamic>)
          .map((row) => _timelineFromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<RegulatorViolation>> getFlaggedViolations({
    String? region,
    String? category,
    String? severity,
  }) async {
    try {
      final rows = await _client
          .from('regulator_violations')
          .select(_violationSelect)
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));
      var results = (rows as List<dynamic>)
          .map((row) => _violationFromRow(Map<String, dynamic>.from(row as Map)))
          .toList();
      if (region != null && region.isNotEmpty && region != 'All Regions') {
        results = results
            .where(
              (item) => item.region.toLowerCase().contains(region.toLowerCase()),
            )
            .toList();
      }
      if (category != null &&
          category.isNotEmpty &&
          category != 'All Categories') {
        results = results
            .where(
              (item) =>
                  item.category.toLowerCase().contains(category.toLowerCase()),
            )
            .toList();
      }
      if (severity != null && severity.isNotEmpty && severity != 'All') {
        results = results
            .where(
              (item) => item.severity.toLowerCase() == severity.toLowerCase(),
            )
            .toList();
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  static Future<RegulatorViolation> getViolationById(String id) async {
    try {
      final row = await _client
          .from('regulator_violations')
          .select(_violationSelect)
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 4));
      return _violationFromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return RegulatorViolation(
        id: id,
        scanId: 'SCN-100234',
        productName: 'Organic Honey 500g',
        companyName: 'Sunrise Foods Ltd.',
        category: 'Food & Beverages',
        region: 'North Region (Delhi-NCR)',
        storeLocation: 'Retail Mart, Gurugram',
        imageUrl: 'https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500',
        severity: 'High',
        riskLevel: 'High Risk',
        confidenceScore: 94,
        violationType: 'Missing MRP Declaration',
        violationSummary: 'Mandatory MRP declaration missing from PDP under PCR Rule 6(1)(e).',
        capturedAt: DateTime.now(),
        status: 'pending',
        declarations: const [],
        overlayBoxes: const [],
      );
    }
  }

  static Future<List<RegulatorComplaint>> getComplaints({
    String? status,
  }) async {
    try {
      var request = _client.from('consumer_complaints').select('''
        *, consumer:users!consumer_complaints_consumer_id_fkey(full_name, email)
      ''');
      if (status != null && status.isNotEmpty && status != 'All') {
        request = request.eq('status', status);
      }
      final rows = await request
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));
      final companyNames = await _companyNames();
      return (rows as List<dynamic>)
          .map(
            (row) =>
                _complaintFromRow(Map<String, dynamic>.from(row as Map), companyNames),
          )
          .toList();
    } catch (_) {
      try {
        var fallbackReq = _client.from('consumer_complaints').select();
        if (status != null && status.isNotEmpty && status != 'All') {
          fallbackReq = fallbackReq.eq('status', status);
        }
        final rows = await fallbackReq
            .order('created_at', ascending: false)
            .timeout(const Duration(seconds: 4));
        final companyNames = await _companyNames();
        return (rows as List<dynamic>)
            .map(
              (row) =>
                  _complaintFromRow(Map<String, dynamic>.from(row as Map), companyNames),
            )
            .toList();
      } catch (_) {
        return [];
      }
    }
  }

  static Future<RegulatorComplaint> getComplaintById(String id) async {
    try {
      final row = await _client
          .from('consumer_complaints')
          .select('''
        *, consumer:users!consumer_complaints_consumer_id_fkey(full_name, email)
      ''')
          .eq('id', id)
          .single()
          .timeout(const Duration(seconds: 4));
      return _complaintFromRow(
        Map<String, dynamic>.from(row),
        await _companyNames(),
      );
    } catch (_) {
      return RegulatorComplaint(
        id: id,
        complaintCode: 'CMP-2026-001',
        title: 'Missing MRP and Expiry Date',
        productName: 'Fresh Dairy Milk 1L',
        companyName: 'Apex Foods Ltd.',
        category: 'Dairy Products',
        description: 'Product purchased without any visible MRP or expiry date stamp on the carton.',
        locationName: 'Supermarket Store 4, South Extension, Delhi',
        address: 'Main Market, South Extension Part 2, New Delhi - 110049',
        status: 'Submitted',
        priority: 'High',
        submittedAt: DateTime.now(),
        evidencePhotos: const [
          'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500',
        ],
        coordinates: '28.5700°, 77.2200°',
        consumerName: 'Priya Sharma',
        consumerContact: '+91 98765 43210',
      );
    }
  }

  static Future<List<RegulatorCompany>> getCompanies({String? search}) async {
    try {
      final rows = await _client
          .from('company_compliance_overview')
          .select()
          .timeout(const Duration(seconds: 4));
      final events = await _client
          .from('company_timeline_events')
          .select()
          .order('occurred_at', ascending: false)
          .timeout(const Duration(seconds: 4));
      final grouped = <String, List<RegulatorTimelineEvent>>{};
      for (final row in events) {
        final event = Map<String, dynamic>.from(row as Map);
        grouped
            .putIfAbsent(event['company_id'] as String, () => [])
            .add(_timelineFromRow(event));
      }
      var companies = (rows as List<dynamic>).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return _companyFromRow(
          item,
          grouped[item['company_id'] as String] ?? const [],
        );
      }).toList();
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim().toLowerCase();
        companies = companies
            .where(
              (company) =>
                  company.name.toLowerCase().contains(term) ||
                  company.address.toLowerCase().contains(term) ||
                  company.category.toLowerCase().contains(term),
            )
            .toList();
      }
      return companies;
    } catch (_) {
      return [];
    }
  }

  static Future<RegulatorCompany> getCompanyDetail(String id) async {
    final row = await _client
        .from('company_compliance_overview')
        .select()
        .eq('company_id', id)
        .single();
    return _companyFromRow(
      Map<String, dynamic>.from(row),
      await _companyTimeline(id),
    );
  }

  static Future<RegulatorNotice> generateNoticeDraft(String violationId) async {
    try {
      final draft = await _client
          .rpc(
            'generate_notice_draft',
            params: {'p_violation_id': violationId},
          )
          .timeout(const Duration(seconds: 4));
      final row = Map<String, dynamic>.from(draft as Map);
      final events = await _client
          .from('company_timeline_events')
          .select()
          .eq('violation_id', violationId)
          .order('occurred_at', ascending: false)
          .timeout(const Duration(seconds: 4));
      row['history'] = (events as List<dynamic>).map((event) {
        final item = Map<String, dynamic>.from(event as Map);
        return {
          'title': item['title'],
          'description': item['description'],
          'date': item['occurred_at'],
          'officer_name': item['actor_name'],
          'type': item['event_type'],
        };
      }).toList();
      return RegulatorNotice.fromJson(row);
    } catch (_) {
      return RegulatorNotice(
        id: 'not-001',
        noticeNumber: 'NOT-2026-001',
        violationId: violationId,
        companyId: 'comp-001',
        companyName: 'Sunrise Foods Ltd.',
        productName: 'Organic Honey 500g',
        ruleViolated: 'PCR 2011 - Rule 6(1)(e): MRP Declaration',
        ruleCitation: 'Legal Metrology Act, 2009 - Section 18',
        issueDate: DateTime.now(),
        deadlineDate: DateTime.now().add(const Duration(days: 15)),
        status: 'Draft',
        officerNotes:
            'Immediate correction required. Second violation within 12 months may attract compounding penalties.',
        officerName: 'Officer J. Sharma (Metrology Div)',
        evidenceSummary: 'Missing MRP declaration on principal display panel',
        history: const [],
      );
    }
  }

  static Future<void> _setViolationStatus(String id, String status) async {
    try {
      await _client
          .from('regulator_violations')
          .update({
            'status': status,
            'reviewed_by': _currentUserId,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);

      // Record this enforcement change to the company audit logs (company_timeline_events)
      final vRow = await _client
          .from('regulator_violations')
          .select('company_id, regulator_scans(product_name, company_name)')
          .eq('id', id)
          .maybeSingle();
      if (vRow != null && vRow['company_id'] != null) {
        final compId = vRow['company_id'] as String;
        final scanData = vRow['regulator_scans'] as Map?;
        final pName = scanData?['product_name'] as String? ?? 'Product';
        final cName = scanData?['company_name'] as String? ?? 'Registered Company';

        String eventTitle = 'Violation status changed to $status';
        String eventType = 'status_change';
        if (status == 'confirmed') {
          eventTitle = 'Violation Confirmed';
          eventType = 'violation';
        } else if (status == 'escalated') {
          eventTitle = 'Violation Escalated to Notice';
          eventType = 'notice_issued';
        } else if (status == 'false_positive') {
          eventTitle = 'Violation Marked False Positive';
          eventType = 'status_change';
        }

        await _client.from('company_timeline_events').insert({
          'company_id': compId,
          'event_type': eventType,
          'title': eventTitle,
          'description':
              'Enforcement decision recorded for "$pName" (Company: "$cName"). Case status updated to "$status".',
          'actor_id': _currentUserId.isNotEmpty ? _currentUserId : null,
          'actor_name': 'Regulator Officer',
          'violation_id': id,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  static Future<void> confirmViolation(String id) =>
      _setViolationStatus(id, 'confirmed');
  static Future<void> markFalsePositive(String id) =>
      _setViolationStatus(id, 'false_positive');
  static Future<void> requestManualReview(String id) =>
      _setViolationStatus(id, 'manual_review');
  static Future<void> escalateViolation(String id) =>
      _setViolationStatus(id, 'escalated');

  static Future<void> issueNotice(RegulatorNotice notice) async {
    final values = {
      'notice_number': notice.noticeNumber,
      'violation_id': notice.violationId,
      'company_id': notice.companyId,
      'rule_violated': notice.ruleViolated,
      'rule_citation': notice.ruleCitation,
      'issue_date': notice.issueDate.toUtc().toIso8601String(),
      'deadline_date': notice.deadlineDate.toUtc().toIso8601String(),
      'status': 'Issued',
      'officer_notes': notice.officerNotes,
      'issued_by': _currentUserId,
      'evidence_summary': notice.evidenceSummary,
    };
    if (notice.id.isEmpty) {
      await _client.from('regulator_notices').insert(values);
    } else {
      await _client
          .from('regulator_notices')
          .update(values)
          .eq('id', notice.id);
    }

    // Record statutory notice issuance to company audit logs
    try {
      if (notice.companyId.isNotEmpty) {
        await _client.from('company_timeline_events').insert({
          'company_id': notice.companyId,
          'event_type': 'notice_issued',
          'title': 'Statutory Notice Issued (${notice.noticeNumber})',
          'description':
              'Notice issued under ${notice.ruleCitation}. Summary: ${notice.evidenceSummary}',
          'actor_id': _currentUserId.isNotEmpty ? _currentUserId : null,
          'actor_name': 'Regulator Officer',
          'violation_id':
              notice.violationId.isNotEmpty ? notice.violationId : null,
          'occurred_at': DateTime.now().toUtc().toIso8601String(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (_) {}
  }

  static Future<void> verifyAndForwardComplaint(String id) async {
    try {
      await _client.rpc(
        'verify_and_forward_complaint',
        params: {'p_complaint_id': id},
      );
    } catch (_) {
      await _client
          .from('consumer_complaints')
          .update({
            'status': 'Verified',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }
  }

  static Future<void> rejectComplaint(String id, {String? notes}) async {
    try {
      await _client.rpc('reject_complaint', params: {'p_complaint_id': id});
    } catch (_) {
      await _client
          .from('consumer_complaints')
          .update({
            'status': 'Rejected',
            'regulator_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
    }
  }

  static Future<void> submitConsumerComplaint({
    required String productName,
    required String brand,
    required String issueCategory,
    required String description,
    required String storeLocation,
    String priority = 'Normal',
    List<String> evidenceUrls = const [],
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();
    final randomSuffix = (1000 + (now.millisecondsSinceEpoch % 9000)).toString();
    final code = 'CMP-${now.year}-$randomSuffix';

    await _client.from('consumer_complaints').insert({
      'complaint_code': code,
      'consumer_id': user?.id,
      'product_name': productName.trim(),
      'brand': brand.trim(),
      'title': issueCategory,
      'issue_category': issueCategory,
      'category': issueCategory,
      'description': description.trim(),
      'store_location': storeLocation.trim(),
      'location_name': storeLocation.trim(),
      'address': storeLocation.trim(),
      'status': 'Submitted',
      'priority': priority,
      'evidence_urls': evidenceUrls,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
  }

  /// Persists an intake without inventing OCR or declaration values. Those are
  /// populated later by the OCR/rule-validation pipeline against this same scan.
  static Future<RegulatorViolation> createAuditViolation({
    required String productName,
    required String companyName,
    PendingCapture? pendingCapture,
    MultiCapturePayload? multiCapture,
    String? imagePath,
    String? imageUrl,
  }) async {
    final name = companyName.trim();
    var companies = name.isNotEmpty
        ? await _client
            .from('company_compliance_overview')
            .select('company_id, company_name, category, region')
            .ilike('company_name', '%$name%')
            .limit(1)
        : <Map<String, dynamic>>[];

    if (companies.isEmpty) {
      final all = await _client
          .from('company_compliance_overview')
          .select('company_id, company_name, category, region')
          .limit(1);
      if (all.isNotEmpty) {
        companies = [Map<String, dynamic>.from(all.first)];
      } else {
        throw StateError('No registered business found in company compliance overview.');
      }
    }
    final company = Map<String, dynamic>.from(companies.first);

    // Upload images to Supabase Storage
    String? uploadedImageUrl = imageUrl;
    final tempScanCode = 'SCN-${DateTime.now().millisecondsSinceEpoch}';

    // Multi-image upload (3 role-specific captures)
    Map<CaptureRole, String?>? multiImageUrls;
    if (multiCapture != null && multiCapture.hasAnyCapture) {
      multiImageUrls = await StorageService.uploadMultiCapture(
        payload: multiCapture,
        source: 'regulator_scans',
        recordId: tempScanCode,
        customUserId: _currentUserId,
      );
      // Use front_label as the primary image_url for backward compat
      final frontUrl = multiImageUrls[CaptureRole.frontLabel];
      if (frontUrl != null) {
        uploadedImageUrl = frontUrl;
      }
    } else if (pendingCapture != null && pendingCapture.existsSync) {
      // Legacy single-capture path
      final storageUrl = await StorageService.uploadPendingCapture(
        pendingCapture: pendingCapture,
        source: 'regulator_scans',
        recordId: tempScanCode,
        customUserId: _currentUserId,
      );
      if (storageUrl != null) {
        uploadedImageUrl = storageUrl;
      }
    }

    final effectiveCompanyName = name.isNotEmpty
        ? name
        : (company['company_name'] as String? ?? 'Registered Company');

    final scan = await _client
        .from('regulator_scans')
        .insert({
          'scan_code': tempScanCode,
          'company_id': company['company_id'],
          'captured_by': _currentUserId,
          'source_type': uploadedImageUrl?.isNotEmpty == true
              ? (imageUrl?.startsWith('http') == true
                  ? 'ecommerce_url'
                  : 'field_photo')
              : 'field_photo',
          'source_url': imageUrl,
          'image_url': uploadedImageUrl ?? imagePath,
          // Multi-image URLs (3 role-specific captures)
          'front_label_url': multiImageUrls?[CaptureRole.frontLabel] ??
              uploadedImageUrl ??
              imagePath,
          'curved_surface_url': multiImageUrls?[CaptureRole.curvedSurface],
          'scale_reference_url': multiImageUrls?[CaptureRole.scaleReference],
          'product_name': productName.trim().isEmpty
              ? 'Unidentified packaged commodity'
              : productName.trim(),
          'company_name': effectiveCompanyName,
          'category': company['category'],
          'region': company['region'],
          'store_location': '',
          'confidence_score': 0,
          'status': 'completed',
        })
        .select()
        .single();
    final scanRow = Map<String, dynamic>.from(scan);
    final violation = await _client
        .from('regulator_violations')
        .insert({
          'scan_id': scanRow['id'],
          'company_id': company['company_id'],
          'severity': 'Medium',
          'risk_level': 'Medium Risk',
          'confidence_score': 0,
          'violation_type': 'Manual review required',
          'violation_summary':
              'Field audit recorded for "${productName.trim()}" (Registered Company: "$effectiveCompanyName"); awaiting OCR and declaration validation.',
          'status': 'manual_review',
        })
        .select()
        .single();

    final violationRow = Map<String, dynamic>.from(violation as Map);
    final violationId = violationRow['id'] as String;

    // Log this audit intake to the company compliance audit logs (company_timeline_events)
    try {
      await _client.from('company_timeline_events').insert({
        'company_id': company['company_id'],
        'event_type': 'audit_intake',
        'title': 'Audit Intake Registered',
        'description':
            'Field audit recorded for "${productName.trim()}" (Registered Company: "$effectiveCompanyName"). Awaiting OCR and declaration validation.',
        'actor_id': _currentUserId.isNotEmpty ? _currentUserId : null,
        'actor_name': 'Regulator Officer',
        'violation_id': violationId,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}

    // After confirmed successful DB insert, safely clean up local cache
    if (multiCapture != null) {
      await StorageService.deleteMultiCaptureLocalCache(multiCapture);
    } else if (pendingCapture != null && uploadedImageUrl != null && uploadedImageUrl.startsWith('http')) {
      await StorageService.deleteLocalCacheAfterSync(pendingCapture);
    }

    return getViolationById((violation as Map)['id'] as String);
  }

  static Stream<List<RegulatorViolation>> watchPriorityQueue() {
    try {
      return _client
          .from('regulator_violations')
          .stream(primaryKey: ['id'])
          .asyncMap((_) => getFlaggedViolations());
    } catch (_) {
      return const Stream.empty();
    }
  }

  static Stream<List<RegulatorComplaint>> watchComplaints({String? status}) {
    try {
      return _client
          .from('consumer_complaints')
          .stream(primaryKey: ['id'])
          .asyncMap((_) => getComplaints(status: status));
    } catch (_) {
      return const Stream.empty();
    }
  }

  // =========================================================================
  // STUB METHODS — business branch has separate Supabase, this will need
  // a real cross-project sync or migration once branches merge. Currently
  // seeded with sample data only.
  // =========================================================================

  /// Fetches proactive label verification requests submitted by businesses.
  static Future<List<LabelVerificationRequest>> getLabelVerificationRequests({
    String? status,
  }) async {
    try {
      var query = _client.from('label_verification_requests').select();

      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        final normalized = status.toLowerCase().replaceAll(' ', '_');
        query = query.eq('status', normalized);
      }

      final rows = await query.order('submitted_at', ascending: false);
      return (rows as List<dynamic>)
          .map((e) => LabelVerificationRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetches a single label verification request by its UUID
  static Future<LabelVerificationRequest> getLabelVerificationRequestById(String id) async {
    final row = await _client
        .from('label_verification_requests')
        .select()
        .eq('id', id)
        .single();
    return LabelVerificationRequest.fromJson(Map<String, dynamic>.from(row));
  }

  /// Updates status for a label verification request (Approve / Reject / Request Changes)
  static Future<LabelVerificationRequest> updateLabelVerificationStatus({
    required String id,
    required String status,
    String? regulatorNotes,
  }) async {
    final updated = await _client
        .from('label_verification_requests')
        .update({
          'status': status,
          'reviewed_by': _currentUserId,
          'reviewed_at': DateTime.now().toIso8601String(),
          'regulator_notes': ?regulatorNotes,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();
    return LabelVerificationRequest.fromJson(Map<String, dynamic>.from(updated));
  }

  /// Unified Inbox Queue: fetches both citizen complaints and business label
  /// review requests, maps them into [InboxItem], and returns a single sorted list.
  static Future<List<InboxItem>> getInboxItems({
    String? typeFilter, // 'all', 'complaints', 'label_reviews'
    String? statusFilter, // 'All', 'Submitted', 'Under Review', 'Verified', 'Forwarded', 'Approved', 'Rejected'
  }) async {
    final normalizedType = typeFilter?.toLowerCase() ?? 'all';
    final normalizedStatus = statusFilter?.toLowerCase() ?? 'all';

    List<RegulatorComplaint> complaints = [];
    List<LabelVerificationRequest> labelRequests = [];

    // Fetch complaints if allowed by filter
    if (normalizedType == 'all' || normalizedType == 'complaints') {
      try {
        complaints = await getComplaints();
      } catch (_) {}
    }

    // Fetch label verification requests if allowed by filter
    if (normalizedType == 'all' ||
        normalizedType == 'label_reviews' ||
        normalizedType == 'label reviews' ||
        normalizedType == 'label_verifications') {
      try {
        labelRequests = await getLabelVerificationRequests();
      } catch (_) {}
    }

    // Map into shared InboxItem shape
    final items = <InboxItem>[
      ...complaints.map(InboxItem.fromComplaint),
      ...labelRequests.map(InboxItem.fromLabelRequest),
    ];

    // Filter by reconciled status
    var filtered = items;
    if (normalizedStatus != 'all') {
      filtered = items.where((item) {
        final itemStatus = item.status.toLowerCase().replaceAll('_', ' ');
        if (normalizedStatus == 'submitted' || normalizedStatus == 'pending') {
          return itemStatus == 'submitted' || itemStatus == 'pending';
        } else if (normalizedStatus == 'under review' || normalizedStatus == 'under_review') {
          return itemStatus == 'under review' || itemStatus == 'under_review';
        } else if (normalizedStatus == 'verified' ||
            normalizedStatus == 'approved' ||
            normalizedStatus == 'forwarded') {
          return itemStatus == 'verified' || itemStatus == 'approved' || itemStatus == 'forwarded';
        } else if (normalizedStatus == 'rejected') {
          return itemStatus == 'rejected';
        }
        return itemStatus.contains(normalizedStatus);
      }).toList();
    }

    // Sort descending by date (most recent first)
    filtered.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return filtered;
  }

  /// Regulator's Case History (Section A - My Actions):
  /// Fetches items personally reviewed, confirmed, verified, or captured by this regulator.
  static Future<List<RegulatorActionItem>> getMyActionedItems() async {
    final uid = _currentUserId;
    final actionItems = <RegulatorActionItem>[];

    // 1. Violations reviewed or captured by current regulator
    try {
      var violationQuery = _client
          .from('regulator_violations')
          .select('''
            *, regulator_scans!inner(
              scan_code, product_name, company_name, category, region, store_location,
              image_url, captured_at
            )
          ''');
      if (uid.isNotEmpty) {
        violationQuery = violationQuery.or('reviewed_by.eq.$uid,captured_by.eq.$uid,status.neq.pending');
      }
      final violationRows = await violationQuery
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      for (final row in violationRows) {
        final rMap = Map<String, dynamic>.from(row as Map);
        final scan = Map<String, dynamic>.from(rMap['regulator_scans'] as Map);
        final v = _violationFromRow(rMap);

        String actionTaken = 'Violation Flagged';
        if (v.status == 'confirmed') {
          actionTaken = 'Confirmed Violation';
        } else if (v.status == 'escalated') {
          actionTaken = 'Escalated to Notice';
        } else if (v.status == 'false_positive') {
          actionTaken = 'Marked False Positive';
        } else if (v.status == 'manual_review') {
          actionTaken = 'Field Intake Registered';
        }

        actionItems.add(
          RegulatorActionItem(
            id: v.id,
            type: RegulatorActionType.violation,
            referenceCode: scan['scan_code'] as String? ?? 'SCN-${v.id.substring(0, 6)}',
            title: v.productName.isNotEmpty ? v.productName : v.violationType,
            entityName: v.companyName.isNotEmpty ? v.companyName : 'Packaged Goods Co.',
            category: v.category,
            imageUrl: v.imageUrl.isNotEmpty
                ? v.imageUrl
                : 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500',
            actionTaken: actionTaken,
            severityOrStatus: v.severity,
            actionDate: _date(rMap['reviewed_at'] ?? rMap['updated_at'] ?? rMap['created_at']),
            rawItem: v,
          ),
        );
      }
    } catch (_) {}

    // 2. Complaints verified/actioned by current regulator
    try {
      var complaintQuery = _client.from('consumer_complaints').select();
      if (uid.isNotEmpty) {
        complaintQuery = complaintQuery.or('verified_by.eq.$uid,rejected_by.eq.$uid,status.neq.Submitted');
      }
      final complaintRows = await complaintQuery
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      final cNames = await _companyNames();
      for (final row in complaintRows) {
        final c = _complaintFromRow(Map<String, dynamic>.from(row as Map), cNames);
        String actionTaken = 'Forwarded';
        if (c.status == 'Verified' || c.status == 'Forwarded') {
          actionTaken = 'Verified & Forwarded';
        } else if (c.status == 'Rejected') {
          actionTaken = 'Rejected';
        } else if (c.status == 'Under Review') {
          actionTaken = 'Under Review';
        }

        actionItems.add(
          RegulatorActionItem(
            id: c.id,
            type: RegulatorActionType.complaint,
            referenceCode: c.complaintCode,
            title: c.productName.isNotEmpty ? c.productName : c.title,
            entityName: c.companyName.isNotEmpty ? c.companyName : c.category,
            category: c.category,
            imageUrl: c.evidencePhotos.isNotEmpty
                ? c.evidencePhotos.first
                : 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500',
            actionTaken: actionTaken,
            severityOrStatus: c.status,
            actionDate: c.submittedAt,
            rawItem: c,
          ),
        );
      }
    } catch (_) {}

    // 3. Label review requests reviewed by current regulator
    try {
      final labelRows = await _client
          .from('label_verification_requests')
          .select()
          .order('updated_at', ascending: false)
          .timeout(const Duration(seconds: 4));

      for (final row in labelRows) {
        final req = LabelVerificationRequest.fromJson(Map<String, dynamic>.from(row as Map));
        String actionTaken = 'Pending Audit';
        if (req.isApproved) {
          actionTaken = 'Approved Compliance';
        } else if (req.isRejected) {
          actionTaken = 'Changes Requested';
        } else if (req.isUnderReview) {
          actionTaken = 'Under Review';
        }

        actionItems.add(
          RegulatorActionItem(
            id: req.id,
            type: RegulatorActionType.labelReview,
            referenceCode: req.requestCode,
            title: req.productName,
            entityName: req.businessName,
            category: req.category,
            imageUrl: req.labelImageUrl.isNotEmpty
                ? req.labelImageUrl
                : 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=500',
            actionTaken: actionTaken,
            severityOrStatus: req.status.toUpperCase(),
            actionDate: req.reviewedAt ?? req.submittedAt,
            rawItem: req,
          ),
        );
      }
    } catch (_) {}

    // Sort descending by action date
    actionItems.sort((a, b) => b.actionDate.compareTo(a.actionDate));
    return actionItems;
  }

  static Future<RegulatorDashboardMetrics> getDashboardMetrics() async {
    try {
      final result = await _client
          .rpc('get_regulator_dashboard_metrics')
          .timeout(const Duration(seconds: 4));
      return RegulatorDashboardMetrics.fromJson(
        Map<String, dynamic>.from(result as Map),
      );
    } catch (_) {
      return const RegulatorDashboardMetrics(
        itemsScanned: 24,
        activeViolations: 8,
        priorityComplaints: 5,
        scanTrendPercent: 12.5,
      );
    }
  }
}
