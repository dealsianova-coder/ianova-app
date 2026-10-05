import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../widgets/product_browser.dart';

/// The "See all" and "View all" pages.
class ProductListPage extends StatelessWidget {
  const ProductListPage({
    super.key,
    required this.title,
    required this.products,
    this.onProductTap,
    this.onCartChanged,
  });

  final String title;
  final List<Product> products;
  final ValueChanged<Product>? onProductTap;
  final VoidCallback? onCartChanged;

  @override
  Widget build(BuildContext context) {
    return ProductBrowserPage(
      title: title,
      products: products,
      onProductTap: onProductTap,
      onCartChanged: onCartChanged,
    );
  }
}
