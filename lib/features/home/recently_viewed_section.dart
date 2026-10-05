import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_image.dart';

/// A short row of the products the shopper looked at last.
class RecentlyViewedSection extends StatelessWidget {
  const RecentlyViewedSection({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            IanovaSpacing.xl,
            IanovaSpacing.sm,
            IanovaSpacing.xl,
            IanovaSpacing.sm,
          ),
          child: Text(
            'Recently viewed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: IanovaSpacing.xl,
            ),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];

              return SizedBox(
                width: 112,
                child: InkWell(
                  onTap: () => onProductTap(product),
                  borderRadius: BorderRadius.circular(
                    IanovaSpacing.radiusMedium,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IanovaProductImage(
                        image: product.image,
                        emoji: product.emoji,
                        backgroundColor: product.bgColor,
                        width: 112,
                        height: 112,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        formatKsh(product.price),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: IanovaSpacing.md),
      ],
    );
  }
}
