class ConsumerSavedProduct {
  final String id;
  final String consumerId;
  final String productId;
  final String productName;
  final String brand;
  final String? category;
  final String? quantity;
  final String? imageUrl;
  final DateTime savedAt;

  ConsumerSavedProduct({
    required this.id,
    required this.consumerId,
    required this.productId,
    required this.productName,
    required this.brand,
    this.category,
    this.quantity,
    this.imageUrl,
    required this.savedAt,
  });

  factory ConsumerSavedProduct.fromJson(Map<String, dynamic> json) {
    return ConsumerSavedProduct(
      id: json['id'] as String? ?? '',
      consumerId: json['consumer_id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? 'Saved Product',
      brand: json['brand'] as String? ?? 'Brand',
      category: json['category'] as String?,
      quantity: json['quantity'] as String?,
      imageUrl: json['image_url'] as String?,
      savedAt: json['saved_at'] != null
          ? DateTime.tryParse(json['saved_at'] as String) ?? DateTime.now()
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
      'category': category,
      'quantity': quantity,
      'image_url': imageUrl,
      'saved_at': savedAt.toIso8601String(),
    };
  }
}
