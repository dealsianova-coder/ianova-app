import 'package:flutter/material.dart';

import '../../core/theme/ianova_spacing.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_card.dart';

/// A plain grid of products, used by the "See all" and "View all" links.
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: products.isEmpty
          ? const Center(child: Text('No products found.'))
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                IanovaSpacing.xl,
                IanovaSpacing.sm,
                IanovaSpacing.xl,
                IanovaSpacing.xxxl,
              ),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.66,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                return IanovaProductCard(
                  product: product,
                  onTap: () => onProductTap?.call(product),
                  onCartChanged: onCartChanged,
                );
              },
            ),
    );
  }
}
