class RegulatorComplaint {
  final String id;
  final String complaintCode;
  final String title;
  final String productName;
  final String companyName;
  final String category;
  final String description;
  final String locationName;
  final String address;
  final String status; // 'Submitted', 'Under Review', 'Verified', 'Forwarded', 'Rejected'
  final String priority; // 'High Priority', 'Allergen Flag', 'Weight Discrepancy', 'Pricing Violation', 'Medium Priority', 'Low Priority'
  final DateTime submittedAt;
  final List<String> evidencePhotos;
  final String coordinates;
  final String consumerName;
  final String consumerContact;

  const RegulatorComplaint({
    required this.id,
    required this.complaintCode,
    required this.title,
    required this.productName,
    required this.companyName,
    required this.category,
    required this.description,
    required this.locationName,
    required this.address,
    required this.status,
    required this.priority,
    required this.submittedAt,
    this.evidencePhotos = const [],
    this.coordinates = '',
    this.consumerName = 'Anonymous Consumer',
    this.consumerContact = 'N/A',
  });

  RegulatorComplaint copyWith({
    String? id,
    String? complaintCode,
    String? title,
    String? productName,
    String? companyName,
    String? category,
    String? description,
    String? locationName,
    String? address,
    String? status,
    String? priority,
    DateTime? submittedAt,
    List<String>? evidencePhotos,
    String? coordinates,
    String? consumerName,
    String? consumerContact,
  }) {
    return RegulatorComplaint(
      id: id ?? this.id,
      complaintCode: complaintCode ?? this.complaintCode,
      title: title ?? this.title,
      productName: productName ?? this.productName,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      description: description ?? this.description,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      submittedAt: submittedAt ?? this.submittedAt,
      evidencePhotos: evidencePhotos ?? this.evidencePhotos,
      coordinates: coordinates ?? this.coordinates,
      consumerName: consumerName ?? this.consumerName,
      consumerContact: consumerContact ?? this.consumerContact,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'complaint_code': complaintCode,
        'title': title,
        'product_name': productName,
        'company_name': companyName,
        'category': category,
        'description': description,
        'location_name': locationName,
        'address': address,
        'status': status,
        'priority': priority,
        'submitted_at': submittedAt.toIso8601String(),
        'evidence_photos': evidencePhotos,
        'coordinates': coordinates,
        'consumer_name': consumerName,
        'consumer_contact': consumerContact,
      };

  factory RegulatorComplaint.fromJson(Map<String, dynamic> json) =>
      RegulatorComplaint(
        id: json['id'] as String? ?? '',
        complaintCode: json['complaint_code'] as String? ?? '',
        title: json['title'] as String? ?? '',
        productName: json['product_name'] as String? ?? '',
        companyName: json['company_name'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        locationName: json['location_name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        status: json['status'] as String? ?? 'Submitted',
        priority: json['priority'] as String? ?? 'Medium Priority',
        submittedAt: json['submitted_at'] != null
            ? DateTime.parse(json['submitted_at'] as String)
            : DateTime.now(),
        evidencePhotos: (json['evidence_photos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        coordinates: json['coordinates'] as String? ?? '',
        consumerName: json['consumer_name'] as String? ?? 'Anonymous Consumer',
        consumerContact: json['consumer_contact'] as String? ?? 'N/A',
      );
}
