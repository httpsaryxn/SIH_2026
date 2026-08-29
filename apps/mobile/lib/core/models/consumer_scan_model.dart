class ConsumerScanModel {
  final String id;
  final String consumerId;
  final String? productId;
  final String productName;
  final String brand;
  final String netQuantity;
  final String? imageUrl;
  final String complianceStatus; // 'compliant', 'warning', 'potential_violation', 'unverified'
  final Map<String, dynamic> detectedDeclarations;
  final String? scanNotes;
  final DateTime scannedAt;

  ConsumerScanModel({
    required this.id,
    required this.consumerId,
    this.productId,
    required this.productName,
    this.brand = 'General Brand',
    this.netQuantity = '1 unit',
    this.imageUrl,
    this.complianceStatus = 'compliant',
    this.detectedDeclarations = const {},
    this.scanNotes,
    required this.scannedAt,
  });

  factory ConsumerScanModel.fromJson(Map<String, dynamic> json) {
    return ConsumerScanModel(
      id: json['id'] as String? ?? '',
      consumerId: json['consumer_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String? ?? 'Scanned Item',
      brand: json['brand'] as String? ?? 'Brand',
      netQuantity: json['net_quantity'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      complianceStatus: json['compliance_status'] as String? ?? 'compliant',
      detectedDeclarations: (json['detected_declarations'] is Map)
          ? Map<String, dynamic>.from(json['detected_declarations'] as Map)
          : {},
      scanNotes: json['scan_notes'] as String?,
      scannedAt: json['scanned_at'] != null
          ? DateTime.tryParse(json['scanned_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumer_id': consumerId,
      'product_id': productId,
      'product_name': productName,
      'brand': brand,
      'net_quantity': netQuantity,
      'image_url': imageUrl,
      'compliance_status': complianceStatus,
      'detected_declarations': detectedDeclarations,
      'scan_notes': scanNotes,
      'scanned_at': scannedAt.toIso8601String(),
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(scannedAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
