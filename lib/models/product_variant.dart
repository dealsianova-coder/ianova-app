class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.color,
    required this.size,
    required this.sku,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.image,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String color;
  final String size;
  final String sku;
  final double price;
  final double? originalPrice;
  final int stock;
  final String image;
  final String createdAt;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: int.tryParse(json['id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      color: json['color']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      originalPrice: json['original_price'] == null
          ? null
          : double.tryParse(json['original_price'].toString()),
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      image: json['image']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  bool get isInStock => stock > 0;

  String get label {
    final parts = <String>[
      if (color.isNotEmpty) color,
      if (size.isNotEmpty) 'Size $size',
    ];

    return parts.join(' • ');
  }
}
