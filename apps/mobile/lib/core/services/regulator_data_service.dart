import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pending_capture.dart';
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

  static String get _currentUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('An authenticated regulator session is required.');
    }
    return id;
  }

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
    final rows = await _client
        .from('company_compliance_overview')
        .select('company_id, company_name');
    return {
      for (final row in rows)
        row['company_id'] as String: row['company_name'] as String? ?? '',
    };
  }

  static RegulatorComplaint _complaintFromRow(
    Map<String, dynamic> row,
    Map<String, String> companyNames,
  ) {
    final consumer = row['consumer'] is Map
        ? Map<String, dynamic>.from(row['consumer'] as Map)
        : const <String, dynamic>{};
    final profile = row['consumer_profile'] is Map
        ? Map<String, dynamic>.from(row['consumer_profile'] as Map)
        : const <String, dynamic>{};
    final evidence = (row['evidence_urls'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();
    final legacyImage = row['evidence_image_url'] as String?;
    if (evidence.isEmpty && legacyImage != null && legacyImage.isNotEmpty) {
      evidence.add(legacyImage);
    }
    final companyId = row['company_id'] as String?;
    return RegulatorComplaint(
      id: row['id'] as String,
      complaintCode: row['complaint_code'] as String? ?? '',
      title: row['title'] as String? ?? row['issue_category'] as String? ?? '',
      productName: row['product_name'] as String? ?? '',
      companyName: companyId == null
          ? (row['brand'] as String? ?? '')
          : (companyNames[companyId] ?? row['brand'] as String? ?? ''),
      category:
          row['category'] as String? ?? row['issue_category'] as String? ?? '',
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
    final rows = await _client
        .from('company_timeline_events')
        .select()
        .eq('company_id', companyId)
        .order('occurred_at', ascending: false);
    return rows
        .map((row) => _timelineFromRow(Map<String, dynamic>.from(row)))
        .toList();
  }

  static Future<List<RegulatorViolation>> getFlaggedViolations({
    String? region,
    String? category,
    String? severity,
  }) async {
    final rows = await _client
        .from('regulator_violations')
        .select(_violationSelect)
        .order('created_at', ascending: false);
    var results = rows
        .map((row) => _violationFromRow(Map<String, dynamic>.from(row)))
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
  }

  static Future<RegulatorViolation> getViolationById(String id) async {
    final row = await _client
        .from('regulator_violations')
        .select(_violationSelect)
        .eq('id', id)
        .single();
    return _violationFromRow(Map<String, dynamic>.from(row));
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
      final rows = await request.order('created_at', ascending: false);
      final companyNames = await _companyNames();
      return rows
          .map(
            (row) =>
                _complaintFromRow(Map<String, dynamic>.from(row), companyNames),
          )
          .toList();
    } catch (_) {
      var fallbackReq = _client.from('consumer_complaints').select();
      if (status != null && status.isNotEmpty && status != 'All') {
        fallbackReq = fallbackReq.eq('status', status);
      }
      final rows = await fallbackReq.order('created_at', ascending: false);
      final companyNames = await _companyNames();
      return rows
          .map(
            (row) =>
                _complaintFromRow(Map<String, dynamic>.from(row), companyNames),
          )
          .toList();
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
          .single();
      return _complaintFromRow(
        Map<String, dynamic>.from(row),
        await _companyNames(),
      );
    } catch (_) {
      final row = await _client
          .from('consumer_complaints')
          .select()
          .eq('id', id)
          .single();
      return _complaintFromRow(
        Map<String, dynamic>.from(row),
        await _companyNames(),
      );
    }
  }

  static Future<List<RegulatorCompany>> getCompanies({String? search}) async {
    final rows = await _client.from('company_compliance_overview').select();
    final events = await _client
        .from('company_timeline_events')
        .select()
        .order('occurred_at', ascending: false);
    final grouped = <String, List<RegulatorTimelineEvent>>{};
    for (final row in events) {
      final event = Map<String, dynamic>.from(row);
      grouped
          .putIfAbsent(event['company_id'] as String, () => [])
          .add(_timelineFromRow(event));
    }
    var companies = rows.map((row) {
      final item = Map<String, dynamic>.from(row);
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
    final draft = await _client.rpc(
      'generate_notice_draft',
      params: {'p_violation_id': violationId},
    );
    final row = Map<String, dynamic>.from(draft as Map);
    final events = await _client
        .from('company_timeline_events')
        .select()
        .eq('violation_id', violationId)
        .order('occurred_at', ascending: false);
    row['history'] = events.map((event) {
      final item = Map<String, dynamic>.from(event);
      return {
        'title': item['title'],
        'description': item['description'],
        'date': item['occurred_at'],
        'officer_name': item['actor_name'],
        'type': item['event_type'],
      };
    }).toList();
    return RegulatorNotice.fromJson(row);
  }

  static Future<void> _setViolationStatus(String id, String status) => _client
      .from('regulator_violations')
      .update({
        'status': status,
        'reviewed_by': _currentUserId,
        'reviewed_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', id);

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

    // If pendingCapture is provided, upload to Supabase Storage
    String? uploadedImageUrl = imageUrl;
    final tempScanCode = 'SCN-${DateTime.now().millisecondsSinceEpoch}';

    if (pendingCapture != null && pendingCapture.existsSync) {
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

    final scan = await _client
        .from('regulator_scans')
        .insert({
          'scan_code': tempScanCode,
          'company_id': company['company_id'],
          'captured_by': _currentUserId,
          'source_type': uploadedImageUrl?.isNotEmpty == true
              ? (imageUrl?.startsWith('http') == true ? 'ecommerce_url' : 'field_photo')
              : 'field_photo',
          'source_url': imageUrl,
          'image_url': uploadedImageUrl ?? imagePath,
          'product_name': productName.trim().isEmpty
              ? 'Unidentified packaged commodity'
              : productName.trim(),
          'company_name': company['company_name'],
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
              'Audit captured; awaiting OCR and declaration validation.',
          'status': 'manual_review',
        })
        .select()
        .single();

    // After confirmed successful DB insert, safely clean up local cache if uploaded
    if (pendingCapture != null && uploadedImageUrl != null && uploadedImageUrl.startsWith('http')) {
      await StorageService.deleteLocalCacheAfterSync(pendingCapture);
    }

    return getViolationById((violation as Map)['id'] as String);
  }

  static Stream<List<RegulatorViolation>> watchPriorityQueue() => _client
      .from('regulator_violations')
      .stream(primaryKey: ['id'])
      .asyncMap((_) => getFlaggedViolations());

  static Stream<List<RegulatorComplaint>> watchComplaints({String? status}) =>
      _client
          .from('consumer_complaints')
          .stream(primaryKey: ['id'])
          .asyncMap((_) => getComplaints(status: status));

  static Future<RegulatorDashboardMetrics> getDashboardMetrics() async {
    final result = await _client.rpc('get_regulator_dashboard_metrics');
    return RegulatorDashboardMetrics.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }
}
