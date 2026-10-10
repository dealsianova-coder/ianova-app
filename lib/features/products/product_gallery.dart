import 'package:flutter/material.dart';

import '../../core/state/wishlist_controller.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_image.dart';

class _Slide {
  const _Slide(this.product, this.image);

  final Product product;
  final String image;
}

/// Swipeable photo gallery for the product page.
///
/// Shows every photo of the product (front, back, sides...). When the
/// product has other colors, swiping past the last photo continues into
/// the next color, and the page switches to that color automatically.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.product,
    required this.options,
    required this.discountPercent,
    required this.activeId,
    required this.busy,
    required this.onSwitch,
  });

  final Product product;
  final List<Product> options;
  final int discountPercent;
  final int activeId;
  final bool busy;
  final ValueChanged<Product> onSwitch;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  static const double _height = 400;
  static const BorderRadius _radius = BorderRadius.vertical(
    bottom: Radius.circular(32),
  );

  late final PageController _controller;
  int _page = 0;
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    _page = _activeIndex(_slides());
    _controller = PageController(initialPage: _page);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _activeColor() {
    for (final option in widget.options) {
      if (option.id == widget.activeId) return option.color;
    }

    return widget.product.color;
  }

  List<_Slide> _slides() {
    final current = widget.product;
    final products = <Product>[];

    if (current.color.isEmpty) {
      products.add(current);
    } else {
      final byColor = <String, Product>{};

      for (final item in widget.options) {
        if (item.color.isEmpty) continue;

        final existing = byColor[item.color];

        if (existing == null) {
          byColor[item.color] = item;
          continue;
        }

        final sameSize = item.size == current.size;
        final existingSameSize = existing.size == current.size;

        if (sameSize != existingSameSize) {
          if (sameSize) byColor[item.color] = item;
        } else if (item.stock > 0 && existing.stock <= 0) {
          byColor[item.color] = item;
        }
      }

      byColor[current.color] = current;
      products.addAll(byColor.values);
    }

    final slides = <_Slide>[];

    for (final item in products) {
      final photos = item.photos;

      if (photos.isEmpty) {
        slides.add(_Slide(item, ''));
      } else {
        for (final photo in photos) {
          slides.add(_Slide(item, photo));
        }
      }
    }

    return slides;
  }

  int _activeIndex(List<_Slide> slides) {
    var i = slides.indexWhere((s) => s.product.id == widget.activeId);

    if (i >= 0) return i;

    final color = _activeColor();

    if (color.isNotEmpty) {
      i = slides.indexWhere((s) => s.product.color == color);
    }

    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(covariant ProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);

    final slides = _slides();

    if (_page >= slides.length) _page = slides.length - 1;

    // A color chip was tapped (or a swipe could not switch): follow it.
    if (slides[_page].product.color != _activeColor()) {
      final target = _activeIndex(slides);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _jumpTo(target);
      });
    }
  }

  void _jumpTo(int target) {
    if (_controller.hasClients) {
      _programmatic = true;
      _controller.jumpToPage(target);
      _programmatic = false;
    }

    setState(() => _page = target);
  }

  void _onPageChanged(int i) {
    if (_programmatic) return;

    final slides = _slides();

    if (i < 0 || i >= slides.length) return;

    setState(() => _page = i);

    final slide = slides[i];

    if (slide.product.id != widget.activeId &&
        slide.product.color != _activeColor()) {
      widget.onSwitch(slide.product);
    }
  }

  void _goTo(int index, int count) {
    if (widget.busy || index < 0 || index >= count) return;

    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides();
    final page = _page.clamp(0, slides.length - 1);
    final owner = slides[page].product;
    final mine = <int>[
      for (var i = 0; i < slides.length; i++)
        if (slides[i].product.id == owner.id) i,
    ];
    final multi = slides.length > 1;
    final hasColors = slides.map((s) => s.product.color).toSet().length > 1;
    final top = MediaQuery.of(context).padding.top;
    final wishlist = WishlistController.instance;
    final productId = widget.product.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: _height,
              child: PageView.builder(
                controller: _controller,
                physics: (widget.busy || !multi)
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (_, i) {
                  final slide = slides[i];

                  return IanovaProductImage(
                    image: slide.image,
                    emoji: slide.product.emoji,
                    backgroundColor: slide.product.bgColor,
                    width: double.infinity,
                    height: _height,
                    borderRadius: _radius,
                  );
                },
              ),
            ),
            Positioned(
              top: top + 8,
              left: 16,
              child: _GalleryButton(
                icon: Icons.arrow_back_ios_new_rounded,
                tooltip: 'Back',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              top: top + 8,
              right: 16,
              child: ListenableBuilder(
                listenable: wishlist,
                builder: (context, _) {
                  final saved = wishlist.contains(productId);

                  return _GalleryButton(
                    icon: saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: saved ? IanovaColors.danger : null,
                    tooltip: 'Wishlist',
                    onTap: () async {
                      final message = await wishlist.toggle(productId);

                      if (message != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            if (hasColors && owner.color.isNotEmpty)
              Positioned(
                top: top + 14,
                left: 70,
                right: 70,
                child: Center(
                  child: _GalleryPill(
                    label: owner.color,
                    background: Colors.black.withValues(alpha: 0.55),
                    foreground: Colors.white,
                  ),
                ),
              ),
            if (multi && page > 0)
              Positioned(
                left: 12,
                top: _height / 2 - 21,
                child: _GalleryButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous photo',
                  onTap: () => _goTo(page - 1, slides.length),
                ),
              ),
            if (multi && page < slides.length - 1)
              Positioned(
                right: 12,
                top: _height / 2 - 21,
                child: _GalleryButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next photo',
                  onTap: () => _goTo(page + 1, slides.length),
                ),
              ),
            if (mine.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 20,
                child: Center(child: _dots(mine, page)),
              ),
            if (widget.discountPercent > 0)
              Positioned(
                left: 16,
                bottom: 16,
                child: _GalleryPill(
                  label: '-${widget.discountPercent}%',
                  background: IanovaColors.danger,
                  foreground: Colors.white,
                ),
              ),
            if (widget.product.isFlashDeal)
              const Positioned(
                right: 16,
                bottom: 16,
                child: _GalleryPill(
                  label: 'Flash deal',
                  icon: Icons.bolt_rounded,
                  background: Colors.white,
                  foreground: IanovaColors.primary,
                ),
              ),
          ],
        ),
        if (mine.length > 1) _thumbs(slides, mine, page),
      ],
    );
  }

  Widget _dots(List<int> mine, int page) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final index in mine)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: index == page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: index == page ? 1 : 0.55,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }

  Widget _thumbs(List<_Slide> slides, List<int> mine, int page) {
    return SizedBox(
      height: 76,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: mine.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, k) {
          final index = mine[k];
          final slide = slides[index];
          final selected = index == page;

          return GestureDetector(
            onTap: () => _goTo(index, slides.length),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? IanovaColors.primary : IanovaColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: IanovaProductImage(
                  image: slide.image,
                  emoji: slide.product.emoji,
                  backgroundColor: slide.product.bgColor,
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: color ?? IanovaColors.primary),
          ),
        ),
      ),
    );
  }
}

class _GalleryPill extends StatelessWidget {
  const _GalleryPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
