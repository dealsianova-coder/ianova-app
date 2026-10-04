import 'product.dart';
import 'product_variant.dart';

class ProductDetail {
  const ProductDetail({
    required this.product,
    required this.variants,
    required this.variantCount,
  });

  final Product product;
  final List<ProductVariant> variants;
  final int variantCount;

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];

    if (productJson is! Map) {
      throw const FormatException('Missing product data.');
    }

    final rawVariants = json['variants'];

    final variants = rawVariants is List
        ? rawVariants
            .whereType<Map>()
            .map(
              (item) => ProductVariant.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <ProductVariant>[];

    return ProductDetail(
      product: Product.fromJson(
        Map<String, dynamic>.from(productJson),
      ),
      variants: variants,
      variantCount:
          int.tryParse(json['variant_count'].toString()) ??
          variants.length,
    );
  }

  bool get hasVariants => variants.isNotEmpty;

  List<String> get colors {
    return variants
        .map((variant) => variant.color.trim())
        .where((color) => color.isNotEmpty)
        .toSet()
        .toList();
  }

  List<String> get sizes {
    return variants
        .map((variant) => variant.size.trim())
        .where((size) => size.isNotEmpty)
        .toSet()
        .toList();
  }
}
