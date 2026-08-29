class ConsumerComplaintModel {
  final String id;
  final String complaintCode;
  final String consumerId;
  final String productName;
  final String? brand;
  final String issueCategory;
  final String description;
  final String? evidenceImageUrl;
  final String? storeLocation;
  final String status; // 'submitted', 'under_review', 'verified', 'forwarded_to_company', 'action_required', 'resolved', 'rejected'
  final String? regulatorNotes;
  final DateTime createdAt;

  ConsumerComplaintModel({
    required this.id,
    required this.complaintCode,
    required this.consumerId,
    required this.productName,
    this.brand,
    required this.issueCategory,
    required this.description,
    this.evidenceImageUrl,
    this.storeLocation,
    this.status = 'submitted',
    this.regulatorNotes,
    required this.createdAt,
  });

  factory ConsumerComplaintModel.fromJson(Map<String, dynamic> json) {
    return ConsumerComplaintModel(
      id: json['id'] as String? ?? '',
      complaintCode: json['complaint_code'] as String? ?? 'CMP-2026-001284',
      consumerId: json['consumer_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Product',
      brand: json['brand'] as String?,
      issueCategory: json['issue_category'] as String? ?? 'Misleading Declaration',
      description: json['description'] as String? ?? '',
      evidenceImageUrl: json['evidence_image_url'] as String?,
      storeLocation: json['store_location'] as String?,
      status: json['status'] as String? ?? 'submitted',
      regulatorNotes: json['regulator_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'complaint_code': complaintCode,
      'consumer_id': consumerId,
      'product_name': productName,
      'brand': brand,
      'issue_category': issueCategory,
      'description': description,
      'evidence_image_url': evidenceImageUrl,
      'store_location': storeLocation,
      'status': status,
      'regulator_notes': regulatorNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
  }

  String get displayStatus {
    switch (status) {
      case 'under_review':
        return 'Under Review';
      case 'verified':
        return 'Verified';
      case 'forwarded_to_company':
        return 'Forwarded to Company';
      case 'action_required':
        return 'Action Required';
      case 'resolved':
        return 'Resolved';
      case 'rejected':
        return 'Rejected / Insufficient Evidence';
      case 'submitted':
      default:
        return 'Submitted';
    }
  }

  int get currentStepIndex {
    switch (status) {
      case 'submitted':
        return 0;
      case 'under_review':
        return 1;
      case 'verified':
      case 'forwarded_to_company':
        return 2;
      case 'action_required':
        return 3;
      case 'resolved':
      case 'rejected':
        return 4;
      default:
        return 0;
    }
  }
}
