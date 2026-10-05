import 'package:flutter/material.dart';

import '../core/theme/ianova_spacing.dart';
import '../core/theme/ianova_theme.dart';
import 'ianova_product_image.dart';

/// A soft pastel banner with a headline, a pill button and a product photo.
class IanovaPromoBanner extends StatelessWidget {
  const IanovaPromoBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.emoji,
    required this.imageBackground,
    this.color = IanovaColors.blush,
    this.buttonLabel = 'Shop now',
    this.onPressed,
  });

  final String title;
  final String subtitle;
  final String image;
  final String emoji;
  final String imageBackground;
  final Color color;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(IanovaSpacing.radiusXLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 0, 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.5,
                      color: IanovaColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: IanovaColors.secondary,
                    ),
                  ),
                  if (onPressed != null) ...[
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 38),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(buttonLabel),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(26),
              ),
              child: IanovaProductImage(
                image: image,
                emoji: emoji,
                backgroundColor: imageBackground,
                width: 112,
                height: 112,
                borderRadius: BorderRadius.circular(23),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
