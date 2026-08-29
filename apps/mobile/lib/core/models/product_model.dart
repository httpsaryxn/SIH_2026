class ProductModel {
  final String id;
  final String? barcode;
  final String productName;
  final String brand;
  final String? category;
  final String? netQuantity;
  final double? mrp;
  final List<String> ingredients;
  final Map<String, dynamic> nutritionFacts;
  final String? manufacturerName;
  final String? manufacturerAddress;
  final String? fssaiLicenseNo;
  final String? imageUrl;
  final String complianceStatus; // 'compliant', 'warning', 'potential_violation', 'unverified'
  final List<Map<String, dynamic>> complianceIssues;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    this.barcode,
    required this.productName,
    required this.brand,
    this.category,
    this.netQuantity,
    this.mrp,
    this.ingredients = const [],
    this.nutritionFacts = const {},
    this.manufacturerName,
    this.manufacturerAddress,
    this.fssaiLicenseNo,
    this.imageUrl,
    this.complianceStatus = 'compliant',
    this.complianceIssues = const [],
    this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      barcode: json['barcode'] as String?,
      productName: json['product_name'] as String? ?? 'Unknown Product',
      brand: json['brand'] as String? ?? 'General Brand',
      category: json['category'] as String?,
      netQuantity: json['net_quantity'] as String?,
      mrp: (json['mrp'] != null) ? (json['mrp'] as num).toDouble() : null,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nutritionFacts: (json['nutrition_facts'] is Map)
          ? Map<String, dynamic>.from(json['nutrition_facts'] as Map)
          : {},
      manufacturerName: json['manufacturer_name'] as String?,
      manufacturerAddress: json['manufacturer_address'] as String?,
      fssaiLicenseNo: json['fssai_license_no'] as String?,
      imageUrl: json['image_url'] as String?,
      complianceStatus: json['compliance_status'] as String? ?? 'compliant',
      complianceIssues: (json['compliance_issues'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'product_name': productName,
      'brand': brand,
      'category': category,
      'net_quantity': netQuantity,
      'mrp': mrp,
      'ingredients': ingredients,
      'nutrition_facts': nutritionFacts,
      'manufacturer_name': manufacturerName,
      'manufacturer_address': manufacturerAddress,
      'fssai_license_no': fssaiLicenseNo,
      'image_url': imageUrl,
      'compliance_status': complianceStatus,
      'compliance_issues': complianceIssues,
    };
  }
}
