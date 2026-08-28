class RegulatorNoticeHistoryItem {
  final String title;
  final String description;
  final DateTime date;
  final String officerName;
  final String type; // 'violation', 'audit_passed', 'notice_issued'

  const RegulatorNoticeHistoryItem({
    required this.title,
    required this.description,
    required this.date,
    required this.officerName,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'officer_name': officerName,
        'type': type,
      };

  factory RegulatorNoticeHistoryItem.fromJson(Map<String, dynamic> json) =>
      RegulatorNoticeHistoryItem(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        date: json['date'] != null
            ? DateTime.parse(json['date'] as String)
            : DateTime.now(),
        officerName: json['officer_name'] as String? ?? 'Officer J. Doe',
        type: json['type'] as String? ?? 'violation',
      );
}

class RegulatorNotice {
  final String id;
  final String noticeNumber;
  final String violationId;
  final String companyId;
  final String companyName;
  final String productName;
  final String ruleViolated;
  final String ruleCitation;
  final DateTime issueDate;
  final DateTime deadlineDate;
  final String status; // 'Draft', 'Issued', 'Acknowledged', 'Resolved'
  final String officerNotes;
  final String officerName;
  final String evidenceSummary;
  final List<RegulatorNoticeHistoryItem> history;

  const RegulatorNotice({
    required this.id,
    required this.noticeNumber,
    required this.violationId,
    required this.companyId,
    required this.companyName,
    required this.productName,
    required this.ruleViolated,
    required this.ruleCitation,
    required this.issueDate,
    required this.deadlineDate,
    required this.status,
    required this.officerNotes,
    this.officerName = 'Officer J. Sharma (Metrology Div)',
    this.evidenceSummary = '',
    this.history = const [],
  });

  RegulatorNotice copyWith({
    String? id,
    String? noticeNumber,
    String? violationId,
    String? companyId,
    String? companyName,
    String? productName,
    String? ruleViolated,
    String? ruleCitation,
    DateTime? issueDate,
    DateTime? deadlineDate,
    String? status,
    String? officerNotes,
    String? officerName,
    String? evidenceSummary,
    List<RegulatorNoticeHistoryItem>? history,
  }) {
    return RegulatorNotice(
      id: id ?? this.id,
      noticeNumber: noticeNumber ?? this.noticeNumber,
      violationId: violationId ?? this.violationId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      productName: productName ?? this.productName,
      ruleViolated: ruleViolated ?? this.ruleViolated,
      ruleCitation: ruleCitation ?? this.ruleCitation,
      issueDate: issueDate ?? this.issueDate,
      deadlineDate: deadlineDate ?? this.deadlineDate,
      status: status ?? this.status,
      officerNotes: officerNotes ?? this.officerNotes,
      officerName: officerName ?? this.officerName,
      evidenceSummary: evidenceSummary ?? this.evidenceSummary,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'notice_number': noticeNumber,
        'violation_id': violationId,
        'company_id': companyId,
        'company_name': companyName,
        'product_name': productName,
        'rule_violated': ruleViolated,
        'rule_citation': ruleCitation,
        'issue_date': issueDate.toIso8601String(),
        'deadline_date': deadlineDate.toIso8601String(),
        'status': status,
        'officer_notes': officerNotes,
        'officer_name': officerName,
        'evidence_summary': evidenceSummary,
        'history': history.map((h) => h.toJson()).toList(),
      };

  factory RegulatorNotice.fromJson(Map<String, dynamic> json) => RegulatorNotice(
        id: json['id'] as String? ?? '',
        noticeNumber: json['notice_number'] as String? ?? '',
        violationId: json['violation_id'] as String? ?? '',
        companyId: json['company_id'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        productName: json['product_name'] as String? ?? '',
        ruleViolated: json['rule_violated'] as String? ?? '',
        ruleCitation: json['rule_citation'] as String? ?? '',
        issueDate: json['issue_date'] != null
            ? DateTime.parse(json['issue_date'] as String)
            : DateTime.now(),
        deadlineDate: json['deadline_date'] != null
            ? DateTime.parse(json['deadline_date'] as String)
            : DateTime.now().add(const Duration(days: 15)),
        status: json['status'] as String? ?? 'Draft',
        officerNotes: json['officer_notes'] as String? ?? '',
        officerName: json['officer_name'] as String? ?? 'Officer J. Sharma (Metrology Div)',
        evidenceSummary: json['evidence_summary'] as String? ?? '',
        history: (json['history'] as List<dynamic>?)
                ?.map((h) => RegulatorNoticeHistoryItem.fromJson(
                    h as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
