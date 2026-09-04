// STUB TABLE MODEL — business branch has separate Supabase, this will need a real cross-project sync or migration once branches merge. Currently seeded with sample data only.

class LabelVerificationRequest {
  final String id;
  final String requestCode;
  final String? businessId;
  final String businessName;
  final String productName;
  final String? brand;
  final String? category;
  final String labelImageUrl;
  final List<Map<String, dynamic>> declarations;
  final String status; // 'pending', 'under_review', 'approved', 'rejected'
  final String priority; // 'High Priority', 'Normal', 'Urgent'
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? regulatorNotes;
  final DateTime submittedAt;
  final DateTime createdAt;

  const LabelVerificationRequest({
    required this.id,
    required this.requestCode,
    this.businessId,
    required this.businessName,
    required this.productName,
    this.brand,
    this.category,
    required this.labelImageUrl,
    this.declarations = const [],
    this.status = 'pending',
    this.priority = 'Normal',
    this.reviewedBy,
    this.reviewedAt,
    this.regulatorNotes,
    required this.submittedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isUnderReview => status == 'under_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory LabelVerificationRequest.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> decs = [];
    if (json['declarations'] is List) {
      decs = (json['declarations'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    return LabelVerificationRequest(
      id: json['id'] as String,
      requestCode: json['request_code'] as String? ?? 'LVR-${json['id'].toString().substring(0, 6)}',
      businessId: json['business_id'] as String?,
      businessName: json['business_name'] as String? ?? 'Registered Enterprise',
      productName: json['product_name'] as String? ?? 'Packaged Commodity',
      brand: json['brand'] as String?,
      category: json['category'] as String? ?? 'Packaged Food',
      labelImageUrl: json['label_image_url'] as String? ?? '',
      declarations: decs,
      status: json['status'] as String? ?? 'pending',
      priority: json['priority'] as String? ?? 'Normal',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'] as String) : null,
      regulatorNotes: json['regulator_notes'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'request_code': requestCode,
        'business_id': businessId,
        'business_name': businessName,
        'product_name': productName,
        'brand': brand,
        'category': category,
        'label_image_url': labelImageUrl,
        'declarations': declarations,
        'status': status,
        'priority': priority,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
        'regulator_notes': regulatorNotes,
        'submitted_at': submittedAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}
