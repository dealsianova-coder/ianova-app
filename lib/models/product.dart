class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final double originalPrice;
  final String emoji;
  final String bgColor;
  final double rating;
  final int reviewCount;
  final int stock;
  final bool isFlashDeal;
  final String sellerName;
  final String image;
  final int categoryId;
  final String subcategory;
  final String color;
  final String size;
  final int optionCount;
  final List<String> images;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.originalPrice,
    required this.emoji,
    required this.bgColor,
    required this.rating,
    required this.reviewCount,
    required this.stock,
    required this.isFlashDeal,
    required this.sellerName,
    required this.image,
    this.categoryId = 0,
    this.subcategory = '',
    this.color = '',
    this.size = '',
    this.optionCount = 1,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      originalPrice: double.tryParse(json['original_price'].toString()) ?? 0,
      emoji: json['emoji']?.toString() ?? '',
      bgColor: json['bg_color']?.toString() ?? '#F3F4F6',
      rating: double.tryParse(json['rating'].toString()) ?? 0,
      reviewCount: int.tryParse(json['review_count'].toString()) ?? 0,
      stock: int.tryParse(json['stock'].toString()) ?? 0,
      isFlashDeal:
          json['is_flash_deal'].toString() == '1' ||
          json['is_flash_deal'] == true,
      sellerName: json['seller_name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      categoryId: int.tryParse(json['category_id'].toString()) ?? 0,
      subcategory: json['subcategory']?.toString().trim() ?? '',
      color: json['color']?.toString().trim() ?? '',
      size: json['size']?.toString().trim() ?? '',
      optionCount: int.tryParse(json['option_count'].toString()) ?? 1,
      images: json['images'] is List
          ? (json['images'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }

  /// Every photo of this product, main photo first.
  List<String> get photos {
    final list = <String>[];

    for (final value in [...images, image]) {
      final v = value.trim();

      if (v.isNotEmpty && !list.contains(v)) list.add(v);
    }

    return list;
  }

  int get discountPercent {
    if (originalPrice <= 0 || originalPrice <= price) {
      return 0;
    }

    return ((originalPrice - price) / originalPrice * 100).round();
  }
}
