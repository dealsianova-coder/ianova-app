import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_image.dart';

/// Auto-playing banners. Each product floats gently and its discount pops in.
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
  Timer? _timer;
  bool _dragging = false;
  int _index = 0;

  List<Product> get _items => widget.products.take(3).toList();

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _dragging || !_controller.hasClients) return;
      if (_items.length < 2) return;

      _controller.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dragging = true;
    } else if (notification is ScrollEndNotification && _dragging) {
      _dragging = false;
      _startAutoPlay();
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeDot = _index % items.length;

    return Column(
      children: [
        SizedBox(
          height: 176,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final slot = index % items.length;
                final product = items[slot];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IanovaSpacing.xl,
                  ),
                  child: _HeroSlide(
                    product: product,
                    color: _colors[slot % _colors.length],
                    active: index == _index,
                    onTap: () => widget.onProductTap(product),
                  ),
                );
              },
            ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == activeDot ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == activeDot
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

class _HeroSlide extends StatefulWidget {
  const _HeroSlide({
    required this.product,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final Product product;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_HeroSlide> createState() => _HeroSlideState();
}

class _HeroSlideState extends State<_HeroSlide>
    with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _pop;
  late final Animation<double> _popScale;

  @override
  void initState() {
    super.initState();

    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _popScale = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);

    if (widget.active) {
      _pop.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _HeroSlide oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.active && !oldWidget.active) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final hasDiscount = product.discountPercent > 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(IanovaSpacing.radiusXLarge),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -30,
              top: -44,
              child: _SoftCircle(size: 150, alpha: 0.38),
            ),
            Positioned(
              left: -28,
              bottom: -56,
              child: _SoftCircle(size: 120, alpha: 0.26),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 0, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TagChip(
                          label: product.isFlashDeal
                              ? 'Flash deal'
                              : 'Featured',
                          icon: product.isFlashDeal
                              ? Icons.bolt_rounded
                              : Icons.auto_awesome_rounded,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -0.4,
                            color: IanovaColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              formatKsh(product.price),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: IanovaColors.primary,
                              ),
                            ),
                            if (hasDiscount) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  formatKsh(product.originalPrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: IanovaColors.secondary,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: widget.onTap,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Shop now'),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: AnimatedBuilder(
                    animation: _float,
                    builder: (context, child) {
                      final t = Curves.easeInOut.transform(_float.value);

                      return Transform.translate(
                        offset: Offset(0, -6 + 12 * t),
                        child: Transform.rotate(
                          angle: -0.05 + 0.04 * t,
                          child: child,
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: IanovaProductImage(
                            image: product.image,
                            emoji: product.emoji,
                            backgroundColor: product.bgColor,
                            width: 112,
                            height: 112,
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        if (hasDiscount)
                          Positioned(
                            top: -10,
                            left: -14,
                            child: ScaleTransition(
                              scale: _popScale,
                              child: _DiscountBadge(
                                text: '-${product.discountPercent}%',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  const _SoftCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: IanovaColors.danger),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: IanovaColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: IanovaColors.danger,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: IanovaColors.danger.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
