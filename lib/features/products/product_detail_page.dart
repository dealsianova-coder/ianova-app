import 'package:flutter/material.dart';
import '../../core/format/money.dart';
import '../../core/storage/recent_products.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product_detail.dart';
import '../../models/product_variant.dart';

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

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    RecentProducts.add(widget.productId);
    _loadProduct();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _api.getProductDetail(widget.productId);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.shopping_bag_outlined),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _detail == null || _isLoading
          ? null
          : _BottomPurchaseBar(
              price: _currentPrice,
              stock: _currentStock,
              onAddToCart: _currentStock > 0
                  ? _addToCart
                  : null,
            ),
    );
  }

  Future<void> _addToCart() async {
    final detail = _detail;

    if (detail == null || _currentStock < 1) {
      return;
    }

    try {
      await _api.addToCart(
        productId: detail.product.id,
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
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _loadProduct,
      );
    }

    final detail = _detail;

    if (detail == null) {
      return const Center(
        child: Text('Product not found.'),
      );
    }

    final product = detail.product;

    return RefreshIndicator(
      onRefresh: _loadProduct,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          bottom: IanovaSpacing.xl,
        ),
        children: [
          _ProductImage(
            image: product.image,
            emoji: product.emoji,
            backgroundColor: product.bgColor,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.xl,
              IanovaSpacing.xl,
              IanovaSpacing.xl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.isFlashDeal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: IanovaColors.primary,
                      borderRadius: BorderRadius.circular(
                        IanovaSpacing.radiusSmall,
                      ),
                    ),
                    child: const Text(
                      'FLASH DEAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                const SizedBox(height: IanovaSpacing.md),
                Text(
                  product.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '(${product.reviewCount} reviews)',
                      style: const TextStyle(
                        color: IanovaColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IanovaSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatKsh(_currentPrice),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    if ((_currentOriginalPrice ?? 0) > _currentPrice) ...[
                      const SizedBox(width: 10),
                      Text(
                        formatKsh(_currentOriginalPrice!),
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: IanovaColors.muted,
                              decoration:
                                  TextDecoration.lineThrough,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: IanovaSpacing.md),
                _StockLabel(stock: _currentStock),
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
                const SizedBox(height: IanovaSpacing.xxl),
                Text(
                  'Description',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: IanovaSpacing.sm),
                Text(
                  product.description.isEmpty
                      ? 'No description available.'
                      : product.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.image,
    required this.emoji,
    required this.backgroundColor,
  });

  final String image;
  final String emoji;
  final String backgroundColor;

  @override
  Widget build(BuildContext context) {
    final parsedColor = _parseColor(backgroundColor);

    return Container(
      height: 360,
      width: double.infinity,
      color: parsedColor,
      child: image.trim().isEmpty
          ? Center(
              child: Text(
                emoji.isEmpty ? '📦' : emoji,
                style: const TextStyle(fontSize: 100),
              ),
            )
          : Image.network(
              IanovaApiConfig.imageUrl(image),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return Center(
                  child: Text(
                    emoji.isEmpty ? '📦' : emoji,
                    style: const TextStyle(fontSize: 100),
                  ),
                );
              },
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
    );
  }

  Color _parseColor(String value) {
    try {
      final cleaned = value.replaceAll('#', '');

      if (cleaned.length != 6) {
        return IanovaColors.soft;
      }

      return Color(
        int.parse('FF$cleaned', radix: 16),
      );
    } catch (_) {
      return IanovaColors.soft;
    }
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

class _StockLabel extends StatelessWidget {
  const _StockLabel({
    required this.stock,
  });

  final int stock;

  @override
  Widget build(BuildContext context) {
    final inStock = stock > 0;

    return Row(
      children: [
        Icon(
          inStock
              ? Icons.check_circle_outline_rounded
              : Icons.remove_circle_outline_rounded,
          size: 18,
          color: inStock
              ? IanovaColors.success
              : IanovaColors.danger,
        ),
        const SizedBox(width: 6),
        Text(
          inStock ? '$stock available' : 'Out of stock',
          style: TextStyle(
            color: inStock
                ? IanovaColors.success
                : IanovaColors.danger,
            fontWeight: FontWeight.w700,
          ),
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
    required this.stock,
    required this.onAddToCart,
  });

  final double price;
  final int stock;
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
        decoration: BoxDecoration(
          color: IanovaColors.surface,
          border: const Border(
            top: BorderSide(
              color: IanovaColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(
                      color: IanovaColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    formatKsh(price),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAddToCart,
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                ),
                label: Text(
                  stock > 0 ? 'Add to cart' : 'Out of stock',
                ),
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
