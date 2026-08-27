class RegulatorTimelineEvent {
  final DateTime date;
  final String title;
  final String description;
  final String type; // 'violation', 'audit_passed', 'notice_issued', 'response_received', 'corrective_action', 're_audit'
  final String officerName;
  final String batchNo;

  const RegulatorTimelineEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.type,
    this.officerName = 'Officer J. Sharma',
    this.batchNo = '',
  });

  bool get isViolation => type == 'violation';
  bool get isAuditPassed => type == 'audit_passed';
  bool get isNoticeIssued => type == 'notice_issued';
  bool get isCorrectiveAction => type == 'corrective_action' || type == 're_audit';

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'title': title,
        'description': description,
        'type': type,
        'officer_name': officerName,
        'batch_no': batchNo,
      };

  factory RegulatorTimelineEvent.fromJson(Map<String, dynamic> json) =>
      RegulatorTimelineEvent(
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        type: json['type'] as String? ?? 'audit_passed',
        officerName: json['officer_name'] as String? ?? 'Officer J. Sharma',
        batchNo: json['batch_no'] as String? ?? '',
      );
}

class RegulatorCompany {
  final String id;
  final String name;
  final String address;
  final String region;
  final String category;
  final int complianceScore;
  final int openViolationsCount;
  final int noticesIssuedCount;
  final DateTime lastAuditDate;
  final String status; // 'Active', 'Under Investigation', 'Compliant', 'Action Required'
  final List<RegulatorTimelineEvent> timeline;

  const RegulatorCompany({
    required this.id,
    required this.name,
    required this.address,
    required this.region,
    required this.category,
    required this.complianceScore,
    required this.openViolationsCount,
    required this.noticesIssuedCount,
    required this.lastAuditDate,
    required this.status,
    this.timeline = const [],
  });

  RegulatorCompany copyWith({
    String? id,
    String? name,
    String? address,
    String? region,
    String? category,
    int? complianceScore,
    int? openViolationsCount,
    int? noticesIssuedCount,
    DateTime? lastAuditDate,
    String? status,
    List<RegulatorTimelineEvent>? timeline,
  }) {
    return RegulatorCompany(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      region: region ?? this.region,
      category: category ?? this.category,
      complianceScore: complianceScore ?? this.complianceScore,
      openViolationsCount: openViolationsCount ?? this.openViolationsCount,
      noticesIssuedCount: noticesIssuedCount ?? this.noticesIssuedCount,
      lastAuditDate: lastAuditDate ?? this.lastAuditDate,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'region': region,
        'category': category,
        'compliance_score': complianceScore,
        'open_violations_count': openViolationsCount,
        'notices_issued_count': noticesIssuedCount,
        'last_audit_date': lastAuditDate.toIso8601String(),
        'status': status,
        'timeline': timeline.map((t) => t.toJson()).toList(),
      };

  factory RegulatorCompany.fromJson(Map<String, dynamic> json) =>
      RegulatorCompany(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        region: json['region'] as String? ?? '',
        category: json['category'] as String? ?? '',
        complianceScore: json['compliance_score'] as int? ?? 80,
        openViolationsCount: json['open_violations_count'] as int? ?? 0,
        noticesIssuedCount: json['notices_issued_count'] as int? ?? 0,
        lastAuditDate: json['last_audit_date'] != null
            ? DateTime.parse(json['last_audit_date'] as String)
            : DateTime.now(),
        status: json['status'] as String? ?? 'Active',
        timeline: (json['timeline'] as List<dynamic>?)
                ?.map((t) =>
                    RegulatorTimelineEvent.fromJson(t as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
