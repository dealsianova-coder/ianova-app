import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_promo_banner.dart';

/// Swipeable pastel banners built from the featured products.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  static const _colors = [
    IanovaColors.blush,
    IanovaColors.sky,
    IanovaColors.sand,
  ];

  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.products.take(3).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 172,
          child: PageView.builder(
            controller: _controller,
            itemCount: items.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final product = items[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: IanovaSpacing.xl,
                ),
                child: IanovaPromoBanner(
                  title: product.name,
                  subtitle: product.discountPercent > 0
                      ? 'Up to ${product.discountPercent}% off'
                      : formatKsh(product.price),
                  image: product.image,
                  emoji: product.emoji,
                  imageBackground: product.bgColor,
                  color: _colors[index % _colors.length],
                  onPressed: () => widget.onProductTap(product),
                ),
              );
            },
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? IanovaColors.primary
                        : IanovaColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: IanovaSpacing.sm),
      ],
    );
  }
}
