import 'package:flutter/material.dart';
import '../core/format/money.dart';

import '../core/network/api_service.dart';
import '../core/state/wishlist_controller.dart';
import '../core/theme/ianova_spacing.dart';
import '../core/theme/ianova_theme.dart';
import '../models/product.dart';
import 'ianova_product_image.dart';

class IanovaProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onCartChanged;

  /// Makes the discount badge pulse every few seconds.
  final bool animateBadge;

  const IanovaProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavorite,
    this.onCartChanged,
    this.animateBadge = false,
  });

  @override
  State<IanovaProductCard> createState() => _IanovaProductCardState();
}

class _IanovaProductCardState extends State<IanovaProductCard>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  AnimationController? _badgePulse;
  Animation<double>? _badgeScale;

  @override
  void initState() {
    super.initState();

    if (widget.animateBadge) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      );

      // Start each card at a different point so badges do not pulse together.
      controller.value = (widget.product.id % 5) / 5;
      controller.repeat();

      _badgePulse = controller;
      _badgeScale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.16)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 10,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.16, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 14,
        ),
        TweenSequenceItem(
          tween: ConstantTween<double>(1.0),
          weight: 76,
        ),
      ]).animate(controller);
    }
  }
  final WishlistController _wishlist = WishlistController.instance;
  bool _addingToCart = false;

  Future<void> _toggleFavorite() async {
    final message = await _wishlist.toggle(widget.product.id);

    if (!mounted || message == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _badgePulse?.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_addingToCart || widget.product.stock < 1) {
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      await _api.addToCart(
        productId: widget.product.id,
      );

      if (!mounted) return;

      widget.onCartChanged?.call();
    } on ApiException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add product to cart.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  Widget _wrapPulse(Widget badge) {
    final scale = _badgeScale;

    if (scale == null) {
      return badge;
    }

    return ScaleTransition(scale: scale, child: badge);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(
        IanovaSpacing.radiusLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: IanovaProductImage(
                    image: product.image,
                    emoji: product.emoji,
                    backgroundColor: product.bgColor,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(
                      IanovaSpacing.radiusLarge,
                    ),
                  ),
                ),

                if (product.discountPercent > 0)
                  Positioned(
                    left: IanovaSpacing.sm,
                    top: IanovaSpacing.sm,
                    child: _wrapPulse(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: IanovaColors.danger,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  right: IanovaSpacing.sm,
                  top: IanovaSpacing.sm,
                  child: ListenableBuilder(
                    listenable: _wishlist,
                    builder: (context, _) {
                      final saved = _wishlist.contains(product.id);

                      return Material(
                        color: Colors.white.withValues(alpha: 0.94),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: widget.onFavorite ?? _toggleFavorite,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 19,
                              color: saved ? IanovaColors.danger : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],
            ),
          ),

          const SizedBox(height: IanovaSpacing.md),

          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
          ),

          const SizedBox(height: IanovaSpacing.xs),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                formatKsh(product.price),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              if (product.originalPrice > product.price) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    formatKsh(product.originalPrice),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: IanovaColors.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: IanovaSpacing.xs),

          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: IanovaColors.warning,
              ),
              const SizedBox(width: 3),
              Text(
                '${product.rating}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${product.reviewCount})',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: IanovaColors.muted,
                    ),
              ),
            ],
          ),

          if (product.stock > 0 && product.stock <= 5) ...[
            const SizedBox(height: 2),
            Text(
              'Only ${product.stock} left',
              style: const TextStyle(
                color: IanovaColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          const SizedBox(height: IanovaSpacing.sm),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton.icon(
              onPressed: product.stock > 0 && !_addingToCart
                  ? _addToCart
                  : null,
              icon: _addingToCart
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      size: 17,
                    ),
              label: Text(
                product.stock > 0 ? 'Add to Cart' : 'Sold out',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
