enum RegulatorActionType {
  violation,
  complaint,
  labelReview,
  auditScan,
}

/// Model representing an enforcement action, intake review, or field audit
/// actioned personally by the logged-in regulator.
class RegulatorActionItem {
  final String id;
  final RegulatorActionType type;
  final String referenceCode;
  final String title;
  final String entityName;
  final String? category;
  final String? imageUrl;
  final String actionTaken;
  final String severityOrStatus;
  final DateTime actionDate;
  final dynamic rawItem;

  const RegulatorActionItem({
    required this.id,
    required this.type,
    required this.referenceCode,
    required this.title,
    required this.entityName,
    this.category,
    this.imageUrl,
    required this.actionTaken,
    required this.severityOrStatus,
    required this.actionDate,
    this.rawItem,
  });

  bool get isViolation => type == RegulatorActionType.violation;
  bool get isComplaint => type == RegulatorActionType.complaint;
  bool get isLabelReview => type == RegulatorActionType.labelReview;
  bool get isAuditScan => type == RegulatorActionType.auditScan;
}
