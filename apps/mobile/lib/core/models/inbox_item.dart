import 'label_verification_request.dart';
import 'regulator_complaint.dart';

enum InboxItemType {
  complaint,
  labelVerification,
}

/// Unified display model for the Regulator Inbox tab, merging citizen complaints
/// and business proactive label verification requests into a single sorted queue.
class InboxItem {
  final String id;
  final InboxItemType type; // complaint | labelVerification
  final String code;
  final String title;
  final String subtitle;
  final String? category;
  final String? locationOrBusiness;
  final String? imageUrl;
  final DateTime submittedAt;
  final String status;
  final String priorityOrTag;
  final dynamic rawItem; // RegulatorComplaint or LabelVerificationRequest

  const InboxItem({
    required this.id,
    required this.type,
    required this.code,
    required this.title,
    required this.subtitle,
    this.category,
    this.locationOrBusiness,
    this.imageUrl,
    required this.submittedAt,
    required this.status,
    required this.priorityOrTag,
    this.rawItem,
  });

  bool get isComplaint => type == InboxItemType.complaint;
  bool get isLabelVerification => type == InboxItemType.labelVerification;

  factory InboxItem.fromComplaint(RegulatorComplaint complaint) {
    return InboxItem(
      id: complaint.id,
      type: InboxItemType.complaint,
      code: complaint.complaintCode,
      title: complaint.productName.isNotEmpty
          ? complaint.productName
          : complaint.title,
      subtitle: complaint.companyName.isNotEmpty
          ? complaint.companyName
          : (complaint.category.isNotEmpty ? complaint.category : 'General Consumer Complaint'),
      category: complaint.category,
      locationOrBusiness: complaint.locationName.isNotEmpty
          ? complaint.locationName
          : complaint.companyName,
      imageUrl: complaint.evidencePhotos.isNotEmpty ? complaint.evidencePhotos.first : null,
      submittedAt: complaint.submittedAt,
      status: complaint.status,
      priorityOrTag: complaint.priority,
      rawItem: complaint,
    );
  }

  factory InboxItem.fromLabelRequest(LabelVerificationRequest request) {
    return InboxItem(
      id: request.id,
      type: InboxItemType.labelVerification,
      code: request.requestCode,
      title: request.productName,
      subtitle: request.businessName,
      category: request.category,
      locationOrBusiness: request.businessName,
      imageUrl: request.labelImageUrl,
      submittedAt: request.submittedAt,
      status: request.status,
      priorityOrTag: 'Label Review Request',
      rawItem: request,
    );
  }
}
