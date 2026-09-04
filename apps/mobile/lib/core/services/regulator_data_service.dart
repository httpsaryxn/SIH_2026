import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pending_capture.dart';
import '../models/regulator_company.dart';
import '../models/regulator_complaint.dart';
import '../models/regulator_notice.dart';
import '../models/regulator_violation.dart';
import 'legal_metrology_service.dart';
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
/// Falls back to seed/mock datasets when Supabase is uninitialized (e.g. tests/offline).
class RegulatorDataService {
  static bool get _hasClient {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

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
    final id = _hasClient ? _client.auth.currentUser?.id : null;
    if (id == null) {
      if (_hasClient) {
        throw StateError('An authenticated regulator session is required.');
      }
      return 'regulator-system-user';
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
    if (!_hasClient) {
      final comp = _mockCompanies.firstWhere(
        (c) => c.id == companyId,
        orElse: () => _mockCompanies.first,
      );
      return comp.timeline;
    }
    try {
      final rows = await _client
          .from('company_timeline_events')
          .select()
          .eq('company_id', companyId)
          .order('occurred_at', ascending: false);
      return rows
          .map((row) => _timelineFromRow(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      final comp = _mockCompanies.firstWhere(
        (c) => c.id == companyId,
        orElse: () => _mockCompanies.first,
      );
      return comp.timeline;
    }
  }

  static Future<List<RegulatorViolation>> getFlaggedViolations({
    String? region,
    String? category,
    String? severity,
  }) async {
    if (!_hasClient) {
      var results = List<RegulatorViolation>.from(_mockViolations);
      if (region != null && region.isNotEmpty && region != 'All Regions') {
        results = results
            .where((item) => item.region.toLowerCase().contains(region.toLowerCase()))
            .toList();
      }
      if (category != null && category.isNotEmpty && category != 'All Categories') {
        results = results
            .where((item) => item.category.toLowerCase().contains(category.toLowerCase()))
            .toList();
      }
      if (severity != null && severity.isNotEmpty && severity != 'All') {
        results = results
            .where((item) => item.severity.toLowerCase() == severity.toLowerCase())
            .toList();
      }
      return results;
    }
    try {
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
    } catch (_) {
      var results = List<RegulatorViolation>.from(_mockViolations);
      if (region != null && region.isNotEmpty && region != 'All Regions') {
        results = results
            .where((item) => item.region.toLowerCase().contains(region.toLowerCase()))
            .toList();
      }
      if (category != null && category.isNotEmpty && category != 'All Categories') {
        results = results
            .where((item) => item.category.toLowerCase().contains(category.toLowerCase()))
            .toList();
      }
      if (severity != null && severity.isNotEmpty && severity != 'All') {
        results = results
            .where((item) => item.severity.toLowerCase() == severity.toLowerCase())
            .toList();
      }
      return results;
    }
  }

  static Future<RegulatorViolation> getViolationById(String id) async {
    if (!_hasClient) {
      return _mockViolations.firstWhere(
        (v) => v.id == id,
        orElse: () => _mockViolations.first,
      );
    }
    try {
      final row = await _client
          .from('regulator_violations')
          .select(_violationSelect)
          .eq('id', id)
          .single();
      return _violationFromRow(Map<String, dynamic>.from(row));
    } catch (_) {
      return _mockViolations.firstWhere(
        (v) => v.id == id,
        orElse: () => _mockViolations.first,
      );
    }
  }

  static Future<List<RegulatorComplaint>> getComplaints({
    String? status,
  }) async {
    if (!_hasClient) {
      var results = List<RegulatorComplaint>.from(_mockComplaints);
      if (status != null && status.isNotEmpty && status != 'All') {
        results = results
            .where((item) => item.status.toLowerCase() == status.toLowerCase())
            .toList();
      }
      return results;
    }
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
      try {
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
      } catch (_) {
        var results = List<RegulatorComplaint>.from(_mockComplaints);
        if (status != null && status.isNotEmpty && status != 'All') {
          results = results
              .where((item) => item.status.toLowerCase() == status.toLowerCase())
              .toList();
        }
        return results;
      }
    }
  }

  static Future<RegulatorComplaint> getComplaintById(String id) async {
    if (!_hasClient) {
      return _mockComplaints.firstWhere(
        (c) => c.id == id,
        orElse: () => _mockComplaints.first,
      );
    }
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
      try {
        final row = await _client
            .from('consumer_complaints')
            .select()
            .eq('id', id)
            .single();
        return _complaintFromRow(
          Map<String, dynamic>.from(row),
          await _companyNames(),
        );
      } catch (_) {
        return _mockComplaints.firstWhere(
          (c) => c.id == id,
          orElse: () => _mockComplaints.first,
        );
      }
    }
  }

  static Future<List<RegulatorCompany>> getCompanies({String? search}) async {
    if (!_hasClient) {
      var results = List<RegulatorCompany>.from(_mockCompanies);
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim().toLowerCase();
        results = results
            .where(
              (company) =>
                  company.name.toLowerCase().contains(term) ||
                  company.address.toLowerCase().contains(term) ||
                  company.category.toLowerCase().contains(term),
            )
            .toList();
      }
      return results;
    }
    try {
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
    } catch (_) {
      var results = List<RegulatorCompany>.from(_mockCompanies);
      if (search != null && search.trim().isNotEmpty) {
        final term = search.trim().toLowerCase();
        results = results
            .where(
              (company) =>
                  company.name.toLowerCase().contains(term) ||
                  company.address.toLowerCase().contains(term) ||
                  company.category.toLowerCase().contains(term),
            )
            .toList();
      }
      return results;
    }
  }

  static Future<RegulatorCompany> getCompanyDetail(String id) async {
    if (!_hasClient) {
      return _mockCompanies.firstWhere(
        (c) => c.id == id,
        orElse: () => _mockCompanies.first,
      );
    }
    try {
      final row = await _client
          .from('company_compliance_overview')
          .select()
          .eq('company_id', id)
          .single();
      return _companyFromRow(
        Map<String, dynamic>.from(row),
        await _companyTimeline(id),
      );
    } catch (_) {
      return _mockCompanies.firstWhere(
        (c) => c.id == id,
        orElse: () => _mockCompanies.first,
      );
    }
  }

  static Future<RegulatorNotice> generateNoticeDraft(String violationId) async {
    if (!_hasClient) {
      final violation = await getViolationById(violationId);
      return RegulatorNotice(
        id: 'not-001',
        noticeNumber: 'SCN-2026-004481',
        violationId: violation.id,
        companyId: 'comp-001',
        companyName: violation.companyName,
        productName: violation.productName,
        ruleViolated: violation.violationSummary,
        ruleCitation: violation.declarations.isNotEmpty
            ? violation.declarations.first.ruleCitation
            : 'LMPC Act 2009 & PCR 2011',
        issueDate: DateTime.now(),
        deadlineDate: DateTime.now().add(const Duration(days: 15)),
        status: 'Draft',
        officerNotes:
            'Audit scan ${violation.scanId} detected ${violation.violationSummary} at ${violation.storeLocation}. Immediate formal show-cause notice initiated under Legal Metrology (Packaged Commodities) Rules 2011.',
        officerName: 'Officer J. Sharma (Metrology Division)',
        evidenceSummary:
            'Scan ID: ${violation.scanId}, Confidence: ${violation.confidenceScore}%, Location: ${violation.storeLocation}',
        history: [
          RegulatorNoticeHistoryItem(
            title: 'Violation Noted',
            description: violation.violationSummary,
            date: violation.capturedAt,
            officerName: 'Officer J. Sharma',
            type: 'violation',
          ),
          RegulatorNoticeHistoryItem(
            title: 'Routine Audit Passed',
            description:
                'Previous facility packaging inspection passed standard tolerance.',
            date: DateTime.now().subtract(const Duration(days: 90)),
            officerName: 'Officer M. Smith',
            type: 'audit_passed',
          ),
        ],
      );
    }
    try {
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
    } catch (_) {
      final violation = await getViolationById(violationId);
      return RegulatorNotice(
        id: 'not-001',
        noticeNumber: 'SCN-2026-004481',
        violationId: violation.id,
        companyId: 'comp-001',
        companyName: violation.companyName,
        productName: violation.productName,
        ruleViolated: violation.violationSummary,
        ruleCitation: violation.declarations.isNotEmpty
            ? violation.declarations.first.ruleCitation
            : 'LMPC Act 2009 & PCR 2011',
        issueDate: DateTime.now(),
        deadlineDate: DateTime.now().add(const Duration(days: 15)),
        status: 'Draft',
        officerNotes:
            'Audit scan ${violation.scanId} detected ${violation.violationSummary} at ${violation.storeLocation}. Immediate formal show-cause notice initiated under Legal Metrology (Packaged Commodities) Rules 2011.',
        officerName: 'Officer J. Sharma (Metrology Division)',
        evidenceSummary:
            'Scan ID: ${violation.scanId}, Confidence: ${violation.confidenceScore}%, Location: ${violation.storeLocation}',
        history: [
          RegulatorNoticeHistoryItem(
            title: 'Violation Noted',
            description: violation.violationSummary,
            date: violation.capturedAt,
            officerName: 'Officer J. Sharma',
            type: 'violation',
          ),
          RegulatorNoticeHistoryItem(
            title: 'Routine Audit Passed',
            description:
                'Previous facility packaging inspection passed standard tolerance.',
            date: DateTime.now().subtract(const Duration(days: 90)),
            officerName: 'Officer M. Smith',
            type: 'audit_passed',
          ),
        ],
      );
    }
  }

  static Future<void> _setViolationStatus(String id, String status) async {
    final index = _mockViolations.indexWhere((v) => v.id == id);
    if (index != -1) {
      _mockViolations[index] = _mockViolations[index].copyWith(status: status);
    }
    if (_hasClient) {
      try {
        await _client
            .from('regulator_violations')
            .update({
              'status': status,
              'reviewed_by': _currentUserId,
              'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id);
      } catch (_) {}
    }
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
    final updatedNotice = notice.copyWith(status: 'Issued');
    final index = _mockNotices.indexWhere((n) => n.id == notice.id);
    if (index != -1) {
      _mockNotices[index] = updatedNotice;
    } else {
      _mockNotices.insert(0, updatedNotice);
    }
    if (_hasClient) {
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
      try {
        if (notice.id.isEmpty) {
          await _client.from('regulator_notices').insert(values);
        } else {
          await _client
              .from('regulator_notices')
              .update(values)
              .eq('id', notice.id);
        }
      } catch (_) {}
    }
  }

  static Future<void> verifyAndForwardComplaint(String id) async {
    final index = _mockComplaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      _mockComplaints[index] =
          _mockComplaints[index].copyWith(status: 'Forwarded');
    }
    if (_hasClient) {
      try {
        await _client.rpc(
          'verify_and_forward_complaint',
          params: {'p_complaint_id': id},
        );
      } catch (_) {
        try {
          await _client
              .from('consumer_complaints')
              .update({
                'status': 'Verified',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', id);
        } catch (_) {}
      }
    }
  }

  static Future<void> rejectComplaint(String id, {String? notes}) async {
    final index = _mockComplaints.indexWhere((c) => c.id == id);
    if (index != -1) {
      _mockComplaints[index] =
          _mockComplaints[index].copyWith(status: 'Rejected');
    }
    if (_hasClient) {
      try {
        await _client.rpc('reject_complaint', params: {'p_complaint_id': id});
      } catch (_) {
        try {
          await _client
              .from('consumer_complaints')
              .update({
                'status': 'Rejected',
                'regulator_notes': notes,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', id);
        } catch (_) {}
      }
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
    LmAuditResult? audit,
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
          'ocr_text': audit != null ? _ocrTextFromAudit(audit) : null,
          'confidence_score': audit?.scorePercent ?? 0,
          'status': 'completed',
        })
        .select()
        .single();
    final scanRow = Map<String, dynamic>.from(scan);

    // Persist each rule outcome as a declaration_check so the review screen
    // renders the real Legal Metrology findings.
    if (audit != null) {
      final checks = _declarationChecks(scanRow['id'] as String, audit);
      if (checks.isNotEmpty) {
        try {
          await _client.from('declaration_checks').insert(checks);
        } catch (_) {
          // non-fatal — the violation row still carries the summary
        }
      }
    }

    final tier = audit == null ? _AuditTier.medium : _tierFor(audit);
    final violation = await _client
        .from('regulator_violations')
        .insert({
          'scan_id': scanRow['id'],
          'company_id': company['company_id'],
          'severity': tier.severity,
          'risk_level': tier.riskLevel,
          'confidence_score': audit?.scorePercent ?? 0,
          'violation_type': audit == null
              ? 'Manual review required'
              : (audit.complianceIssues.isEmpty
                  ? 'No deviation detected'
                  : (audit.complianceIssues.first['type'] as String? ??
                      'PCR 2011 non-compliance')),
          'violation_summary': audit == null
              ? 'Audit captured; awaiting OCR and declaration validation.'
              : _violationSummaryFromAudit(audit),
          'status': audit != null && audit.report.diff.failed.isNotEmpty
              ? 'pending'
              : 'manual_review',
        })
        .select()
        .single();

    // After confirmed successful DB insert, safely clean up local cache if uploaded
    if (pendingCapture != null && uploadedImageUrl != null && uploadedImageUrl.startsWith('http')) {
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

  static Future<RegulatorDashboardMetrics> getDashboardMetrics() async {
    final result = await _client.rpc('get_regulator_dashboard_metrics');
    return RegulatorDashboardMetrics.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
  }

  // ---------------------------------------------------------------------------
  // Legal Metrology pipeline -> regulator enforcement rows
  // ---------------------------------------------------------------------------

  static String _ocrTextFromAudit(LmAuditResult audit) {
    final d = audit.detectedDeclarations;
    final lines = <String>[
      for (final e in const [
        'commodity_name',
        'manufacturer',
        'manufacturer_address',
        'net_quantity',
        'mrp',
        'mfg_date',
        'best_before',
        'country_of_origin',
        'fssai_license_no',
        'consumer_care_info',
      ])
        if (d[e] != null) '$e: ${d[e]}',
    ];
    return lines.join('\n');
  }

  static String _violationSummaryFromAudit(LmAuditResult audit) {
    final pct = audit.scorePercent;
    if (audit.complianceIssues.isEmpty) {
      return 'LM(PC) Rules 2011 audit: $pct% (${audit.starLabel}). '
          'No mandatory declaration deviations detected.';
    }
    final items = audit.complianceIssues
        .take(3)
        .map((i) => i['type'])
        .whereType<String>()
        .join('; ');
    return 'LM(PC) Rules 2011 audit: $pct% (${audit.starLabel}). '
        '${audit.complianceIssues.length} finding(s): $items.';
  }

  static const Map<String, String> _dcStatus = {
    'PASS': 'Compliant',
    'FAIL': 'Violation',
    'WARNING': 'Warning',
    'INCONCLUSIVE': 'Unable to Verify',
    'NOT_APPLICABLE': 'Unable to Verify',
  };

  static List<Map<String, dynamic>> _declarationChecks(
    String scanId,
    LmAuditResult audit,
  ) {
    final rules = [
      ...audit.report.diff.failed,
      ...audit.report.diff.warnings,
      ...audit.report.diff.inconclusive,
      ...audit.report.diff.passed,
    ];
    return [
      for (final r in rules)
        {
          'scan_id': scanId,
          'field_name': r.ruleName,
          'extracted_value': r.evidence ?? '',
          'confidence_percent': 100,
          'status': _dcStatus[r.status] ?? 'Unable to Verify',
          'rule_citation': r.legalReference ?? r.ruleId,
          'rule_description': r.detail,
        },
    ];
  }

  static _AuditTier _tierFor(LmAuditResult audit) {
    if (audit.report.score.criticalFailures > 0) return _AuditTier.critical;
    if (audit.report.diff.failed.isNotEmpty) return _AuditTier.high;
    final unverified = audit.report.diff.inconclusive
        .any((x) => x.severity == 'CRITICAL' || x.severity == 'MAJOR');
    if (unverified || audit.report.diff.warnings.isNotEmpty) {
      return _AuditTier.medium;
    }
    return _AuditTier.low;
  }

  // ---------------------------------------------------------------------------
  // Fallback Mock Datasets (for tests and offline mode)
  // ---------------------------------------------------------------------------

  static final List<RegulatorViolation> _mockViolations = [
    RegulatorViolation(
      id: 'viol-001',
      scanId: '#77291-LM',
      productName: 'Instant Masala Noodles 70g Pack',
      companyName: 'Nestle India Limited',
      category: 'Packaged Foods',
      region: 'North Region - New Delhi',
      storeLocation: 'QuickShop Superstore, Connaught Place, New Delhi',
      imageUrl:
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?auto=format&fit=crop&w=600&q=80',
      severity: 'Critical',
      riskLevel: 'Critical Risk',
      confidenceScore: 99,
      violationType: 'Misleading Declaration',
      violationSummary: 'Misleading weight claim (+20% extra text without baseline)',
      capturedAt: DateTime.now().subtract(const Duration(hours: 3)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY DECLARATION',
          extractedValue: '70g (+20% Extra Free claim present)',
          confidencePercent: 99,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 6(1)(c) & Rule 2(h)',
          ruleDescription:
              'Promotional percentage claim missing baseline quantity on principal display panel.',
        ),
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: '₹14.00 (Inclusive of all taxes)',
          confidencePercent: 98,
          status: 'Compliant',
          ruleCitation: 'LMPC Sec 18(1)',
          ruleDescription: 'MRP clearly indicated.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.35,
          leftPercent: 0.15,
          widthPercent: 0.45,
          heightPercent: 0.15,
          label: 'Weight Claim Anomaly',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-002',
      scanId: '#88104-FB',
      productName: 'Artisan Multigrain Bread 400g',
      companyName: 'BakeCraft Foods LLP',
      category: 'Bakery Products',
      region: 'West Region - Mumbai',
      storeLocation: 'Riverside Fresh Mart, Bandra West, Mumbai',
      imageUrl:
          'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 98,
      violationType: 'Missing Allergen',
      violationSummary: 'Undeclared walnuts in ingredient list',
      capturedAt: DateTime.now().subtract(const Duration(hours: 6)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'ALLERGEN DECLARATION',
          extractedValue: 'Not Declared (Contains Walnuts/Gluten)',
          confidencePercent: 96,
          status: 'Violation',
          ruleCitation: 'FSSAI Packaging Regs & PCR Rule 6(1)(e)',
          ruleDescription:
              'Mandatory allergen disclosure missing for tree nuts and gluten.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.65,
          leftPercent: 0.20,
          widthPercent: 0.40,
          heightPercent: 0.12,
          label: 'Missing Allergen',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-003',
      scanId: '#66129-DR',
      productName: 'Organic Almond Milk 1L',
      companyName: 'PureNutri Beverages India',
      category: 'Dairy & Beverages',
      region: 'South Region - Bengaluru',
      storeLocation: 'Whole Foods Prep, Indiranagar, Bengaluru',
      imageUrl:
          'https://images.unsplash.com/photo-1568651315053-4bb4268e0013?auto=format&fit=crop&w=600&q=80',
      severity: 'Medium',
      riskLevel: 'Medium Risk',
      confidenceScore: 92,
      violationType: 'Date Format',
      violationSummary: 'Expiration and use-by date obscured/smudged',
      capturedAt: DateTime.now().subtract(const Duration(hours: 12)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'DATE OF MFG / EXPIRY',
          extractedValue: 'Illegible / Overprinted (Smudged)',
          confidencePercent: 42,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 6(1)(d)',
          ruleDescription:
              'Expiry and best before date must remain smudge-resistant and clearly legible.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.25,
          leftPercent: 0.30,
          widthPercent: 0.35,
          heightPercent: 0.10,
          label: 'Date Obscured',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-004',
      scanId: '#55210-SP',
      productName: 'Spicy Mustard Oil 1L Pouch',
      companyName: 'Shree Kissan Agro Mills',
      category: 'Edible Oils',
      region: 'North Region - Lucknow',
      storeLocation: 'Kissan Mandi, Alambagh, Lucknow',
      imageUrl:
          'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 95,
      violationType: 'Weight Tolerance',
      violationSummary: 'Volume shortfall (Measured 910ml vs 1000ml declared)',
      capturedAt: DateTime.now().subtract(const Duration(days: 1)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'NET QUANTITY',
          extractedValue: 'Declared 1L / Actual 910ml (-9.0% shortfall)',
          confidencePercent: 98,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Second Schedule & Sec 30',
          ruleDescription:
              'Maximum allowable deficiency exceeded for 1000ml liquid packages.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.70,
          leftPercent: 0.25,
          widthPercent: 0.50,
          heightPercent: 0.12,
          label: 'Weight Shortfall',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-005',
      scanId: '#44918-SN',
      productName: 'Roasted Cashew Masala 200g',
      companyName: 'Haldiram Snacks Pvt Ltd',
      category: 'Packaged Snacks',
      region: 'North Region - Noida',
      storeLocation: 'Mega Mart, Sector 62, Noida',
      imageUrl:
          'https://images.unsplash.com/photo-1541592106381-b31e9677c0e5?auto=format&fit=crop&w=600&q=80',
      severity: 'Low',
      riskLevel: 'Low Risk',
      confidenceScore: 89,
      violationType: 'Font Size',
      violationSummary: 'Consumer care contact font size under 1.5mm standard',
      capturedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'CONSUMER CARE DETAILS',
          extractedValue: 'Font height 0.9mm (Min required 1.5mm)',
          confidencePercent: 91,
          status: 'Warning',
          ruleCitation: 'PCR 2011 Rule 9(1) Table 1',
          ruleDescription:
              'Height of numeral and letters must adhere to minimum area standards.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.82,
          leftPercent: 0.15,
          widthPercent: 0.60,
          heightPercent: 0.08,
          label: 'Font Size < 1.5mm',
          isViolation: false,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-006',
      scanId: '#33812-TC',
      productName: 'Premium Assam Gold CTC Tea 500g',
      companyName: 'Tata Consumer Products Ltd',
      category: 'Beverages',
      region: 'East Region - Kolkata',
      storeLocation: 'Super Bazaar, Park Street, Kolkata',
      imageUrl:
          'https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=600&q=80',
      severity: 'Low',
      riskLevel: 'Low Risk',
      confidenceScore: 94,
      violationType: 'USP Missing',
      violationSummary: 'Unit sale price missing on multi-pack carton',
      capturedAt: DateTime.now().subtract(const Duration(days: 3)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'UNIT SALE PRICE (USP)',
          extractedValue: 'Missing',
          confidencePercent: 0,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 2(m)',
          ruleDescription: 'Unit sale price must be displayed per g.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.60,
          leftPercent: 0.35,
          widthPercent: 0.30,
          heightPercent: 0.08,
          label: 'USP Missing',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-007',
      scanId: '#22904-BT',
      productName: 'Digestive High Fiber Biscuits',
      companyName: 'Britannia Industries Ltd',
      category: 'Bakery & Biscuits',
      region: 'South Region - Chennai',
      storeLocation: 'Nilgiris Supermarket, T. Nagar, Chennai',
      imageUrl:
          'https://images.unsplash.com/photo-1558961363-fa8fdf82db35?auto=format&fit=crop&w=600&q=80',
      severity: 'Medium',
      riskLevel: 'Medium Risk',
      confidenceScore: 91,
      violationType: 'Dual MRP',
      violationSummary: 'Dual pricing sticker superimposed on pre-printed MRP',
      capturedAt: DateTime.now().subtract(const Duration(days: 4)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'MAXIMUM RETAIL PRICE (MRP)',
          extractedValue: 'Sticker: ₹95.00 / Original Print: ₹85.00',
          confidencePercent: 96,
          status: 'Violation',
          ruleCitation: 'LMPC Sec 18(2) & PCR Rule 18(1)',
          ruleDescription:
              'No person shall alter or superimpose any price sticker on the pre-printed MRP.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.45,
          leftPercent: 0.50,
          widthPercent: 0.35,
          heightPercent: 0.12,
          label: 'Sticker Overprint',
          isViolation: true,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-008',
      scanId: '#11450-DB',
      productName: '100% Pure Honey 500g Glass Jar',
      companyName: 'Dabur India Limited',
      category: 'Packaged Foods',
      region: 'North Region - Chandigarh',
      storeLocation: 'Reliance Smart, Sector 17, Chandigarh',
      imageUrl:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=600&q=80',
      severity: 'Low',
      riskLevel: 'Low Risk',
      confidenceScore: 97,
      violationType: 'Customer Care Info',
      violationSummary: 'Toll-free number line busy/disconnected on test call',
      capturedAt: DateTime.now().subtract(const Duration(days: 5)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'CONSUMER CARE DETAILS',
          extractedValue: '1800-103-1644 (Inactive in audit verification)',
          confidencePercent: 93,
          status: 'Warning',
          ruleCitation: 'PCR 2011 Rule 6(1)(f)',
          ruleDescription:
              'Consumer grievance helpline must remain functional and responsive.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.78,
          leftPercent: 0.20,
          widthPercent: 0.50,
          heightPercent: 0.10,
          label: 'Helpline Warning',
          isViolation: false,
        ),
      ],
    ),
    RegulatorViolation(
      id: 'viol-009',
      scanId: '#99341-MD',
      productName: 'Cow Ghee 1L Tin',
      companyName: 'Mother Dairy Fruit & Vegetable Pvt Ltd',
      category: 'Dairy Products',
      region: 'West Region - Ahmedabad',
      storeLocation: 'Amul & Dairy Mart, Navrangpura, Ahmedabad',
      imageUrl:
          'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&w=600&q=80',
      severity: 'High',
      riskLevel: 'High Risk',
      confidenceScore: 96,
      violationType: 'Missing Manufacturer Address',
      violationSummary: 'Only brand name declared; physical packing unit missing',
      capturedAt: DateTime.now().subtract(const Duration(days: 6)),
      status: 'pending',
      declarations: const [
        RegulatorDeclaration(
          fieldName: 'MANUFACTURER ADDRESS',
          extractedValue: 'Marketed by only. Manufacturing Unit ID missing.',
          confidencePercent: 89,
          status: 'Violation',
          ruleCitation: 'PCR 2011 Rule 6(1)(a)',
          ruleDescription:
              'Both manufacturing unit postal address and marketer details required.',
        ),
      ],
      overlayBoxes: const [
        RegulatorOverlayBox(
          topPercent: 0.55,
          leftPercent: 0.20,
          widthPercent: 0.45,
          heightPercent: 0.12,
          label: 'Unit Addr Missing',
          isViolation: true,
        ),
      ],
    ),
  ];

  static final List<RegulatorComplaint> _mockComplaints = [
    RegulatorComplaint(
      id: 'cmp-001',
      complaintCode: 'CMP-2023-892',
      title: 'Mislabeled Expiry - Dairy Product',
      productName: 'Fresh Farms Greek Yogurt 400g',
      companyName: 'Apex Dairy Foods India Ltd',
      category: 'Dairy & Eggs',
      description:
          'I purchased two tubs of Fresh Farms Yogurt from the refrigerated section. When I got home, I noticed the sell-by date looked like it had been rubbed off and re-stamped with a later date over the original faded ink.',
      locationName: 'Downtown Market, Sector 18',
      address: '124 Main St, Food District, New Delhi 110001',
      status: 'Submitted',
      priority: 'High Priority',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1571212515416-fef01fc43637?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '28.6139° N, 77.2090° E',
      consumerName: 'Rajesh Malhotra',
      consumerContact: '+91 98110 44219',
    ),
    RegulatorComplaint(
      id: 'cmp-002',
      complaintCode: 'CMP-2023-893',
      title: 'Missing Allergen Warning on Bread',
      productName: 'Artisan Multigrain Sourdough Loaf',
      companyName: 'BakeCraft Foods LLP',
      category: 'Bakery',
      description:
          'Artisan sourdough loaf completely lacks mandatory tree nut (walnut) and wheat/gluten allergen declaration on the rear nutritional panel despite having walnut pieces visible inside.',
      locationName: 'Riverside Bakery & Cafe',
      address: 'Shop 14, Riverside Promenade, Bandra West, Mumbai 400050',
      status: 'Submitted',
      priority: 'Allergen Flag',
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '19.0596° N, 72.8295° E',
      consumerName: 'Ananya Deshmukh',
      consumerContact: '+91 97230 18842',
    ),
    RegulatorComplaint(
      id: 'cmp-003',
      complaintCode: 'CMP-2023-894',
      title: 'Underweight Pre-packaged Paneer',
      productName: 'Organic Malai Paneer 200g',
      companyName: 'Heritage Dairy Products',
      category: 'Dairy',
      description:
          'Package claims 200g net weight. When weighed on certified digital scale at home, net weight was only 165g (including whey liquid).',
      locationName: 'Heritage Store, Malleshwaram',
      address: '8th Cross, Sampige Road, Bengaluru 560003',
      status: 'Under Review',
      priority: 'High Priority',
      submittedAt: DateTime.now().subtract(const Duration(hours: 8)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1628088062854-d1870b4553da?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '13.0031° N, 77.5643° E',
      consumerName: 'Karthik Raman',
      consumerContact: '+91 98450 71120',
    ),
    RegulatorComplaint(
      id: 'cmp-004',
      complaintCode: 'CMP-2023-895',
      title: 'Dual MRP Pricing Sticker Superimposed',
      productName: 'Crunchy Chocolate Granola 500g',
      companyName: 'NutriBite Foods India',
      category: 'Breakfast Cereals',
      description:
          'Store placed a white sticker of ₹350 over the manufacturer printed MRP of ₹299.',
      locationName: 'Grand Central Hypermarket',
      address: 'Lower Parel, Mumbai 400013',
      status: 'Verified',
      priority: 'Price Gouging',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      evidencePhotos: const [
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80',
      ],
      coordinates: '18.9986° N, 72.8258° E',
      consumerName: 'Pooja Hegde',
      consumerContact: '+91 98201 55309',
    ),
    RegulatorComplaint(
      id: 'cmp-005',
      complaintCode: 'CMP-2023-896',
      title: 'Missing Veg/Non-Veg Logo on Cookies',
      productName: 'Imported Marshmallow Biscuits 150g',
      companyName: 'EuroTreats Global Importers',
      category: 'Confectionery',
      description:
          'Imported cookies containing gelatin sold without mandatory brown non-veg dot indicator symbol on PDP.',
      locationName: 'Gourmet World, Vasant Kunj',
      address: 'Ambience Mall, Vasant Kunj, New Delhi 110070',
      status: 'Forwarded',
      priority: 'Standard',
      submittedAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
      evidencePhotos: const [],
      coordinates: '28.5284° N, 77.1517° E',
      consumerName: 'Sanjay Gupta',
      consumerContact: '+91 99100 28471',
    ),
    RegulatorComplaint(
      id: 'cmp-006',
      complaintCode: 'CMP-2023-897',
      title: 'Illegible Batch and Date Coding',
      productName: 'Spiced Tomato Ketchup 950g',
      companyName: 'Zest Foods Ltd',
      category: 'Condiments',
      description:
          'Inkjet printed manufacturing date and batch number on neck of bottle completely smudged and unreadable.',
      locationName: 'Local Bazaar, Aminabad',
      address: 'Nazirabad Road, Lucknow 226018',
      status: 'Submitted',
      priority: 'Standard',
      submittedAt: DateTime.now().subtract(const Duration(days: 2)),
      evidencePhotos: const [],
      coordinates: '26.8467° N, 80.9462° E',
      consumerName: 'Mohd. Tariq',
      consumerContact: '+91 94150 99812',
    ),
    RegulatorComplaint(
      id: 'cmp-007',
      complaintCode: 'CMP-2023-898',
      title: 'Unit Sale Price Missing on Family Pack',
      productName: 'Premium Washing Powder 3kg Bucket',
      companyName: 'CleanHome Chemicals Ltd',
      category: 'Household Goods',
      description:
          '3kg promotional bucket package does not display Unit Sale Price per kg/gram.',
      locationName: 'Big Supercenter, Anna Nagar',
      address: '2nd Avenue, Anna Nagar, Chennai 600040',
      status: 'Submitted',
      priority: 'Standard',
      submittedAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      evidencePhotos: const [],
      coordinates: '13.0850° N, 80.2101° E',
      consumerName: 'Meenakshi Sundaram',
      consumerContact: '+91 94440 12390',
    ),
    RegulatorComplaint(
      id: 'cmp-008',
      complaintCode: 'CMP-2023-899',
      title: 'Customer Grievance Email Bouncing',
      productName: 'Roasted Almond Crunch 100g',
      companyName: 'NutriPure Snack LLP',
      category: 'Snacks',
      description:
          'Declared email customercare@nutripure.co.in returned mailer-daemon delivery failed.',
      locationName: 'Online Purchase / Quick Commerce',
      address: 'Blinkit Hub, Sector 50, Gurugram 122018',
      status: 'Under Review',
      priority: 'Standard',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
      evidencePhotos: const [],
      coordinates: '28.4124° N, 77.0620° E',
      consumerName: 'Vikram Sethi',
      consumerContact: '+91 98101 67234',
    ),
  ];

  static final List<RegulatorCompany> _mockCompanies = [
    RegulatorCompany(
      id: 'comp-001',
      name: 'Nestle India Limited',
      address: '100/101, World Trade Centre, Barakhamba Lane, New Delhi 110001',
      region: 'North Region',
      category: 'Packaged Foods & Beverages',
      complianceScore: 78,
      openViolationsCount: 4,
      noticesIssuedCount: 2,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 14)),
      status: 'Active Audit',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 14)),
          title: 'Field Audit Intake Logged',
          description: 'Intake #77291-LM logged for Noodles product package.',
          type: 'audit_passed',
          officerName: 'Inspector V. Saxena',
          batchNo: 'BAT-2023-N09',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-002',
      name: 'BakeCraft Foods LLP',
      address: 'Plot 45, MIDC Industrial Area, Andheri East, Mumbai 400093',
      region: 'West Region',
      category: 'Bakery & Confectionery',
      complianceScore: 64,
      openViolationsCount: 6,
      noticesIssuedCount: 3,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 20)),
      status: 'Under Scrutiny',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 20)),
          title: 'Allergen Non-Compliance',
          description: 'Show-cause notice dispatched for missing walnut allergen declaration.',
          type: 'notice_issued',
          officerName: 'Inspector R. Kamble',
          batchNo: 'BCF-BREAD-400',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-003',
      name: 'PureNutri Beverages India',
      address: '7th Floor, Brigade Towers, Brigade Road, Bengaluru 560025',
      region: 'South Region',
      category: 'Dairy & Plant Beverages',
      complianceScore: 82,
      openViolationsCount: 2,
      noticesIssuedCount: 1,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 35)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 35)),
          title: 'Date Coding Verification',
          description: 'Corrective action plan submitted for ink coding printer calibration.',
          type: 'status_change',
          officerName: 'Inspector K. Swamy',
          batchNo: 'PN-ALM-1L',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-004',
      name: 'Shree Kissan Agro Mills',
      address: 'Industrial Growth Centre, Phase II, UPSIDC, Lucknow 226008',
      region: 'North Region',
      category: 'Edible Oils & Grains',
      complianceScore: 58,
      openViolationsCount: 8,
      noticesIssuedCount: 5,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 8)),
      status: 'High Risk Watch',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 8)),
          title: 'Deficiency Beyond Tolerance',
          description: 'Shortfall violation detected on 1L pouch packaging.',
          type: 'violation',
          officerName: 'Inspector D. Shukla',
          batchNo: 'SK-MST-910',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-005',
      name: 'Haldiram Snacks Pvt Ltd',
      address: 'B-1/H-8, Mohan Co-op Industrial Estate, Mathura Road, New Delhi 110044',
      region: 'North Region',
      category: 'Packaged Snacks & Sweets',
      complianceScore: 89,
      openViolationsCount: 1,
      noticesIssuedCount: 0,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 45)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 45)),
          title: 'Annual Surveillance Audit',
          description: 'Inspection of snack packaging unit completed satisfactorily.',
          type: 'audit_passed',
          officerName: 'Inspector A. Verma',
          batchNo: 'HS-CSH-200',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-006',
      name: 'Tata Consumer Products Ltd',
      address: '1, Bishop Lefroy Road, Kolkata, West Bengal 700020',
      region: 'East Region',
      category: 'Tea, Coffee & Foods',
      complianceScore: 94,
      openViolationsCount: 1,
      noticesIssuedCount: 0,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 60)),
      status: 'Compliant',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 60)),
          title: 'Routine Lab Testing Sample',
          description: 'Net content verified with standard laboratory balance.',
          type: 'audit_passed',
          officerName: 'Inspector P. Ghosh',
          batchNo: 'TCP-TEA-500',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-007',
      name: 'Britannia Industries Ltd',
      address: '5/1A, Hungerford Street, Kolkata, West Bengal 700017',
      region: 'East Region',
      category: 'Bakery & Biscuits',
      complianceScore: 86,
      openViolationsCount: 2,
      noticesIssuedCount: 1,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 18)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 18)),
          title: 'Retail Store Price Check',
          description: 'Investigation into retailer sticker overprint underway.',
          type: 'status_change',
          officerName: 'Inspector S. Natarajan',
          batchNo: 'BIL-DIG-100',
        ),
      ],
    ),
    RegulatorCompany(
      id: 'comp-008',
      name: 'Dabur India Limited',
      address: '8/3, Asaf Ali Road, New Delhi 110002',
      region: 'North Region',
      category: 'Health Care & Foods',
      complianceScore: 91,
      openViolationsCount: 1,
      noticesIssuedCount: 0,
      lastAuditDate: DateTime.now().subtract(const Duration(days: 28)),
      status: 'Active',
      timeline: [
        RegulatorTimelineEvent(
          date: DateTime.now().subtract(const Duration(days: 28)),
          title: 'Customer Helpline Verification',
          description: 'Toll-free line status tested during market review.',
          type: 'status_change',
          officerName: 'Inspector M. Tyagi',
          batchNo: 'DAB-HNY-500',
        ),
      ],
    ),
  ];

  static final List<RegulatorNotice> _mockNotices = [
    RegulatorNotice(
      id: 'not-001',
      noticeNumber: 'SCN-2026-004481',
      violationId: 'viol-001',
      companyId: 'comp-001',
      companyName: 'Nestle India Limited',
      productName: 'Instant Masala Noodles 70g Pack',
      ruleViolated: 'Misleading weight claim (+20% extra text without baseline)',
      ruleCitation: 'PCR 2011 Rule 6(1)(c) & Rule 2(h)',
      issueDate: DateTime.now().subtract(const Duration(days: 2)),
      deadlineDate: DateTime.now().add(const Duration(days: 13)),
      status: 'Draft',
      officerNotes:
          'Audit scan #77291-LM detected misleading promotional text. Formal notice initiated under PCR 2011.',
      officerName: 'Officer J. Sharma (Metrology Division)',
      evidenceSummary:
          'Scan ID: #77291-LM, Confidence: 99%, Location: QuickShop Superstore, Connaught Place, New Delhi',
      history: [
        RegulatorNoticeHistoryItem(
          title: 'Violation Noted',
          description: 'Misleading weight claim (+20% extra text without baseline)',
          date: DateTime.now().subtract(const Duration(hours: 3)),
          officerName: 'Officer J. Sharma',
          type: 'violation',
        ),
      ],
    ),
  ];
}

enum _AuditTier {
  critical('Critical', 'Critical Risk'),
  high('High', 'High Risk'),
  medium('Medium', 'Medium Risk'),
  low('Low', 'Low Risk');

  const _AuditTier(this.severity, this.riskLevel);
  final String severity;
  final String riskLevel;
}
