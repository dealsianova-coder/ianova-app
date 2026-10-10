import 'package:flutter/material.dart';

import '../../core/format/color_names.dart';
import '../../core/format/money.dart';
import '../../core/network/api_service.dart';
import '../../core/state/wishlist_controller.dart';
import '../../core/storage/recent_products.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../models/product_detail.dart';
import '../../models/product_variant.dart';
import '../../models/store_settings.dart';
import '../../widgets/ianova_product_card.dart';
import '../../widgets/ianova_product_image.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    this.onCartChanged,
  });

  final int productId;
  final VoidCallback? onCartChanged;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ApiService _api = ApiService();

  ProductDetail? _detail;
  ProductVariant? _selectedVariant;
  StoreSettings? _settings;
  bool _isLoading = true;
  bool _adding = false;
  bool _switching = false;
  late int _currentId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentId = widget.productId;
    RecentProducts.add(widget.productId);
    _loadProduct();
    _loadSettings();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadProduct({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final detail = await _api.getProductDetail(_currentId);

      if (!mounted) return;

      setState(() {
        _detail = detail;
        _selectedVariant =
            detail.variants.isEmpty ? null : detail.variants.first;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load this product.';
        _isLoading = false;
      });
    }
  }

  /// Switches to another color or size of the same product.
  Future<void> _switchTo(Product option) async {
    if (option.id == _currentId || _switching) return;

    setState(() {
      _currentId = option.id;
      _switching = true;
    });

    await _loadProduct(silent: true);

    if (!mounted) return;

    RecentProducts.add(option.id);
    setState(() {
      _switching = false;
    });
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _api.getStoreSettings();

      if (!mounted) return;

      setState(() {
        _settings = settings;
      });
    } catch (_) {
      // The delivery card is simply hidden when settings cannot be loaded.
    }
  }

  double get _currentPrice {
    return _selectedVariant?.price ?? _detail?.product.price ?? 0;
  }

  double? get _currentOriginalPrice {
    return _selectedVariant?.originalPrice ??
        (_detail?.product.originalPrice ?? 0);
  }

  int get _currentStock {
    return _selectedVariant?.stock ?? _detail?.product.stock ?? 0;
  }

  Future<void> _addToCart() async {
    final detail = _detail;

    if (detail == null || _currentStock < 1 || _adding) {
      return;
    }

    setState(() {
      _adding = true;
    });

    String? message;

    try {
      await _api.addToCart(productId: detail.product.id);
      widget.onCartChanged?.call();
      message = 'Added to cart';
    } on ApiException catch (error) {
      message = error.statusCode == 401
          ? 'Please sign in to add items to your cart.'
          : error.message;
    } catch (_) {
      message = 'Unable to add product to cart.';
    }

    if (!mounted) return;

    setState(() {
      _adding = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openRelated(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          onCartChanged: widget.onCartChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    if (_isLoading || _error != null || detail == null) {
      return Scaffold(
        backgroundColor: IanovaColors.background,
        appBar: AppBar(),
        body: _buildStateBody(),
      );
    }

    return Scaffold(
      backgroundColor: IanovaColors.background,
      body: _buildContent(detail),
      bottomNavigationBar: _BottomPurchaseBar(
        price: _currentPrice,
        originalPrice: _currentOriginalPrice ?? 0,
        stock: _currentStock,
        adding: _adding,
        onAddToCart: _currentStock > 0 ? _addToCart : null,
      ),
    );
  }

  Widget _buildStateBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _loadProduct,
      );
    }

    return const Center(child: Text('Product not found.'));
  }

  /// One slide per color of this product, so the main photo can be swiped.
  /// Returns an empty list when the product has no other colors.
  List<Product> _colorSlides(List<Product> options, Product current) {
    if (current.color.isEmpty) return const [];

    final byColor = <String, Product>{};

    for (final item in options) {
      if (item.color.isEmpty) continue;

      final existing = byColor[item.color];

      if (existing == null) {
        byColor[item.color] = item;
        continue;
      }

      // Several sizes in one color: show the one matching the current size,
      // otherwise one that is in stock.
      final sameSize = item.size == current.size;
      final existingSameSize = existing.size == current.size;

      if (sameSize != existingSameSize) {
        if (sameSize) byColor[item.color] = item;
      } else if (item.stock > 0 && existing.stock <= 0) {
        byColor[item.color] = item;
      }
    }

    byColor[current.color] = current;

    return byColor.length > 1 ? byColor.values.toList() : const [];
  }

  Widget _buildContent(ProductDetail detail) {
    final product = detail.product;
    final price = _currentPrice;
    final original = _currentOriginalPrice ?? 0;
    final hasDiscount = original > price;
    final savings = hasDiscount ? original - price : 0.0;
    final percent = hasDiscount ? ((savings / original) * 100).round() : 0;
    final settings = _settings;

    return RefreshIndicator(
      onRefresh: _loadProduct,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          _Gallery(
            productId: product.id,
            image: product.image,
            emoji: product.emoji,
            backgroundColor: product.bgColor,
            discountPercent: percent,
            isFlashDeal: product.isFlashDeal,
            slides: _colorSlides(detail.options, product),
            activeId: _currentId,
            busy: _switching,
            onSlide: _switchTo,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.xl,
              IanovaSpacing.xl,
              IanovaSpacing.xl,
              IanovaSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: IanovaSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: IanovaColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.rating}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '(${product.reviewCount} reviews)',
                      style: const TextStyle(color: IanovaColors.muted),
                    ),
                    if (product.sellerName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Sold by ${product.sellerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: IanovaColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: IanovaSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatKsh(price),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          formatKsh(original),
                          style: const TextStyle(
                            fontSize: 15,
                            color: IanovaColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasDiscount)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'You save ${formatKsh(savings)}',
                      style: const TextStyle(
                        color: IanovaColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: IanovaSpacing.md),
                _StockChip(stock: _currentStock),
                if (detail.options.length > 1) ...[
                  const SizedBox(height: IanovaSpacing.xl),
                  _OptionPicker(
                    current: product,
                    options: detail.options,
                    busy: _switching,
                    onSelect: _switchTo,
                  ),
                ],
                if (detail.hasVariants) ...[
                  const SizedBox(height: IanovaSpacing.xxl),
                  _VariantSelector(
                    variants: detail.variants,
                    selected: _selectedVariant,
                    onSelected: (variant) {
                      setState(() {
                        _selectedVariant = variant;
                      });
                    },
                  ),
                ],
                if (settings != null) _DeliveryCard(settings: settings),
                const SizedBox(height: IanovaSpacing.xxl),
                const Text(
                  'About this product',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: IanovaSpacing.sm),
                Text(
                  product.description.isEmpty
                      ? 'No description available.'
                      : product.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: IanovaColors.secondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: IanovaSpacing.xxl),
                _InfoCard(
                  icon: Icons.storefront_outlined,
                  title: 'Sold by',
                  value: product.sellerName.isEmpty
                      ? 'IANOVA'
                      : product.sellerName,
                ),
                if (detail.related.isNotEmpty) ...[
                  const SizedBox(height: IanovaSpacing.xxl),
                  const Text(
                    'You may also like',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: IanovaSpacing.md),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: detail.related.length,
                    itemBuilder: (context, index) {
                      final item = detail.related[index];

                      return IanovaProductCard(
                        product: item,
                        onTap: () => _openRelated(item),
                        onCartChanged: widget.onCartChanged,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.productId,
    required this.image,
    required this.emoji,
    required this.backgroundColor,
    required this.discountPercent,
    required this.isFlashDeal,
    this.slides = const [],
    this.activeId = 0,
    this.busy = false,
    this.onSlide,
  });

  final int productId;
  final String image;
  final String emoji;
  final String backgroundColor;
  final int discountPercent;
  final bool isFlashDeal;

  /// One product per color. With two or more, the photo can be swiped.
  final List<Product> slides;
  final int activeId;
  final bool busy;
  final ValueChanged<Product>? onSlide;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  static const double _height = 400;
  static const BorderRadius _imageRadius = BorderRadius.vertical(
    bottom: Radius.circular(32),
  );

  late final PageController _controller;

  bool get _swipeable => widget.slides.length > 1;

  int get _index {
    final i = widget.slides.indexWhere((slide) => slide.id == widget.activeId);

    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant _Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_swipeable || !_controller.hasClients) return;

    // A color chip was tapped (or a swipe could not switch): follow it.
    final page = _controller.page?.round() ?? _index;

    if (page != _index) {
      _controller.animateToPage(
        _index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int delta) {
    if (widget.busy) return;

    final target = _index + delta;

    if (target < 0 || target >= widget.slides.length) return;

    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Widget _photo() {
    if (!_swipeable) {
      return IanovaProductImage(
        image: widget.image,
        emoji: widget.emoji,
        backgroundColor: widget.backgroundColor,
        width: double.infinity,
        height: _height,
        borderRadius: _imageRadius,
      );
    }

    return SizedBox(
      width: double.infinity,
      height: _height,
      child: PageView.builder(
        controller: _controller,
        physics: widget.busy
            ? const NeverScrollableScrollPhysics()
            : const PageScrollPhysics(),
        itemCount: widget.slides.length,
        onPageChanged: (i) {
          final slide = widget.slides[i];

          if (slide.id != widget.activeId) {
            widget.onSlide?.call(slide);
          }
        },
        itemBuilder: (_, i) {
          final slide = widget.slides[i];

          return IanovaProductImage(
            image: slide.image,
            emoji: slide.emoji,
            backgroundColor: slide.bgColor,
            width: double.infinity,
            height: _height,
            borderRadius: _imageRadius,
          );
        },
      ),
    );
  }

  Widget _dots() {
    final index = _index;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.slides.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: i == index ? 1 : 0.55,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final wishlist = WishlistController.instance;
    final index = _index;

    return Stack(
      children: [
        _photo(),
        Positioned(
          top: top + 8,
          left: 16,
          child: _RoundButton(
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
              final saved = wishlist.contains(widget.productId);

              return _RoundButton(
                icon: saved
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: saved ? IanovaColors.danger : null,
                tooltip: 'Wishlist',
                onTap: () async {
                  final message = await wishlist.toggle(widget.productId);

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
        if (_swipeable && index > 0)
          Positioned(
            left: 12,
            top: _height / 2 - 21,
            child: _RoundButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'Previous color',
              onTap: () => _go(-1),
            ),
          ),
        if (_swipeable && index < widget.slides.length - 1)
          Positioned(
            right: 12,
            top: _height / 2 - 21,
            child: _RoundButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'Next color',
              onTap: () => _go(1),
            ),
          ),
        if (_swipeable) _dots(),
        if (widget.discountPercent > 0)
          Positioned(
            left: 16,
            bottom: 16,
            child: _Pill(
              label: '-${widget.discountPercent}%',
              background: IanovaColors.danger,
              foreground: Colors.white,
            ),
          ),
        if (widget.isFlashDeal)
          const Positioned(
            right: 16,
            bottom: 16,
            child: _Pill(
              label: 'Flash deal',
              icon: Icons.bolt_rounded,
              background: Colors.white,
              foreground: IanovaColors.primary,
            ),
          ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
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
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: IanovaColors.danger),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    final String label;

    if (stock <= 0) {
      color = IanovaColors.danger;
      icon = Icons.remove_circle_outline_rounded;
      label = 'Out of stock';
    } else if (stock <= 5) {
      color = IanovaColors.danger;
      icon = Icons.local_fire_department_rounded;
      label = 'Only $stock left';
    } else {
      color = IanovaColors.success;
      icon = Icons.check_circle_outline_rounded;
      label = 'In stock';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delivery and returns facts, taken from the store's own admin settings.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.settings});

  final StoreSettings settings;

  IconData _iconFor(String key) {
    switch (key) {
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'returns':
        return Icons.assignment_return_outlined;
      case 'verified':
        return Icons.verified_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (final point in settings.trust) {
      rows.add(
        _PolicyRow(
          icon: _iconFor(point.key),
          title: point.title,
          text: point.text,
        ),
      );

      // The free-delivery limit sits right under the delivery row.
      if (point.key == 'delivery' && settings.freeDeliveryThreshold > 0) {
        rows.add(
          _PolicyRow(
            icon: Icons.redeem_rounded,
            title: 'Free delivery',
            text: 'On orders over ${formatKsh(settings.freeDeliveryThreshold)}',
          ),
        );
      }
    }

    if (rows.isEmpty && settings.freeDeliveryThreshold > 0) {
      rows.add(
        _PolicyRow(
          icon: Icons.redeem_rounded,
          title: 'Free delivery',
          text: 'On orders over ${formatKsh(settings.freeDeliveryThreshold)}',
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: IanovaSpacing.xxl),
      padding: const EdgeInsets.symmetric(
        horizontal: IanovaSpacing.lg,
        vertical: IanovaSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: IanovaColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: IanovaColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: IanovaColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: IanovaColors.soft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: IanovaColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionPicker extends StatelessWidget {
  const _OptionPicker({
    required this.current,
    required this.options,
    required this.busy,
    required this.onSelect,
  });

  final Product current;
  final List<Product> options;
  final bool busy;
  final ValueChanged<Product> onSelect;

  /// The listing to open for a chip: keeps the other choice when it can
  /// and prefers something in stock.
  Product _target(
    List<Product> list,
    String Function(Product) other,
    String want,
  ) {
    for (final item in list) {
      if (other(item) == want && item.stock > 0) return item;
    }
    for (final item in list) {
      if (item.stock > 0) return item;
    }
    return list.first;
  }

  Widget _group({
    required String title,
    required String value,
    required Map<String, List<Product>> groups,
    required String Function(Product) other,
    required String otherValue,
    required bool swatches,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: IanovaColors.secondary,
            ),
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: IanovaColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in groups.entries)
              _OptionChip(
                label: entry.key,
                swatch: swatches ? colorFromName(entry.key) : null,
                selected: entry.key == value,
                available: entry.value.any((item) => item.stock > 0),
                onTap: busy
                    ? null
                    : () => onSelect(
                          _target(entry.value, other, otherValue),
                        ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = <String, List<Product>>{};
    final sizes = <String, List<Product>>{};

    for (final option in options) {
      if (option.color.isNotEmpty) {
        colors.putIfAbsent(option.color, () => []).add(option);
      }
      if (option.size.isNotEmpty) {
        sizes.putIfAbsent(option.size, () => []).add(option);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (colors.length > 1)
          _group(
            title: 'Color',
            value: current.color,
            groups: colors,
            other: (item) => item.size,
            otherValue: current.size,
            swatches: true,
          ),
        if (colors.length > 1 && sizes.length > 1)
          const SizedBox(height: IanovaSpacing.lg),
        if (sizes.length > 1)
          _group(
            title: 'Size',
            value: current.size,
            groups: sizes,
            other: (item) => item.color,
            otherValue: current.color,
            swatches: false,
          ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.available,
    required this.onTap,
    this.swatch,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback? onTap;
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final disabled = !available;

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? IanovaColors.soft
              : (disabled ? IanovaColors.background : IanovaColors.surface),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? IanovaColors.primary : IanovaColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: disabled ? IanovaColors.muted : IanovaColors.primary,
                decoration: disabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductVariant> variants;
  final ProductVariant? selected;
  final ValueChanged<ProductVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: IanovaSpacing.md),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: variants.map((variant) {
            final isSelected = selected?.id == variant.id;

            return ChoiceChip(
              label: Text(
                variant.label.isEmpty
                    ? variant.sku
                    : variant.label,
              ),
              selected: isSelected,
              onSelected: variant.isInStock
                  ? (_) => onSelected(variant)
                  : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: BoxDecoration(
        color: IanovaColors.surface,
        borderRadius: BorderRadius.circular(
          IanovaSpacing.radiusMedium,
        ),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined),
          const SizedBox(width: IanovaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: IanovaColors.muted,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPurchaseBar extends StatelessWidget {
  const _BottomPurchaseBar({
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.adding,
    required this.onAddToCart,
  });

  final double price;
  final double originalPrice;
  final int stock;
  final bool adding;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          IanovaSpacing.xl,
          IanovaSpacing.md,
          IanovaSpacing.xl,
          IanovaSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: IanovaColors.surface,
          border: Border(
            top: BorderSide(color: IanovaColors.border),
          ),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (originalPrice > price)
                  Text(
                    formatKsh(originalPrice),
                    style: const TextStyle(
                      fontSize: 12,
                      color: IanovaColors.muted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                Text(
                  formatKsh(price),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
            const SizedBox(width: IanovaSpacing.lg),
            Expanded(
              child: FilledButton.icon(
                onPressed: adding ? null : onAddToCart,
                icon: adding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.shopping_bag_outlined),
                label: Text(stock > 0 ? 'Add to cart' : 'Out of stock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          IanovaSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
            ),
            const SizedBox(height: IanovaSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: IanovaSpacing.lg),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
