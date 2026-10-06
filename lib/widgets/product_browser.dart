import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/ianova_spacing.dart';
import '../core/theme/ianova_theme.dart';
import '../features/search/search_page.dart';
import '../models/product.dart';
import 'ianova_product_card.dart';
import 'ianova_promo_banner.dart';

enum ProductSort { popular, priceLow, priceHigh, rating, discount }

enum ProductFilter { all, onSale, flash, inStock }

String _sortLabel(ProductSort sort) {
  switch (sort) {
    case ProductSort.popular:
      return 'Popular';
    case ProductSort.priceLow:
      return 'Price: low to high';
    case ProductSort.priceHigh:
      return 'Price: high to low';
    case ProductSort.rating:
      return 'Top rated';
    case ProductSort.discount:
      return 'Biggest discount';
  }
}

String _filterLabel(ProductFilter filter) {
  switch (filter) {
    case ProductFilter.all:
      return 'All';
    case ProductFilter.onSale:
      return 'On sale';
    case ProductFilter.flash:
      return 'Flash deals';
    case ProductFilter.inStock:
      return 'In stock';
  }
}

/// App bar with a centered title, a product count and a search button.
PreferredSizeWidget buildBrowserAppBar(
  BuildContext context, {
  required String title,
  required int? count,
  ValueChanged<Product>? onProductTap,
  VoidCallback? onCartChanged,
}) {
  final subtitle = count == null
      ? null
      : (count == 1 ? '1 product' : '$count products');

  return AppBar(
    toolbarHeight: 64,
    centerTitle: true,
    title: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: IanovaColors.secondary,
            ),
          ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: 'Search',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SearchPage(
                onProductTap: onProductTap,
                onCartChanged: onCartChanged,
              ),
            ),
          );
        },
        icon: const Icon(Icons.search_rounded),
      ),
      const SizedBox(width: 4),
    ],
  );
}

/// A full page of products with a banner, quick filters, sorting and a
/// grid / large-card switch.
class ProductBrowserPage extends StatelessWidget {
  const ProductBrowserPage({
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
      appBar: buildBrowserAppBar(
        context,
        title: title,
        count: products.length,
        onProductTap: onProductTap,
        onCartChanged: onCartChanged,
      ),
      body: ProductBrowser(
        products: products,
        bannerTitle: title,
        onProductTap: (product) => onProductTap?.call(product),
        onCartChanged: onCartChanged,
      ),
    );
  }
}

class ProductBrowser extends StatefulWidget {
  const ProductBrowser({
    super.key,
    required this.products,
    required this.onProductTap,
    this.onCartChanged,
    this.bannerTitle,
    this.onRefresh,
  });

  final List<Product> products;
  final ValueChanged<Product> onProductTap;
  final VoidCallback? onCartChanged;
  final String? bannerTitle;
  final Future<void> Function()? onRefresh;

  @override
  State<ProductBrowser> createState() => _ProductBrowserState();
}

class _ProductBrowserState extends State<ProductBrowser> {
  final ScrollController _scroll = ScrollController();

  ProductSort _sort = ProductSort.popular;
  ProductFilter _filter = ProductFilter.all;
  String? _subcategory;
  bool _grid = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  List<Product> get _visible {
    Iterable<Product> items = widget.products;

    if (_subcategory != null) {
      items = items.where((product) => product.subcategory == _subcategory);
    }

    switch (_filter) {
      case ProductFilter.all:
        break;
      case ProductFilter.onSale:
        items = items.where((product) => product.discountPercent > 0);
        break;
      case ProductFilter.flash:
        items = items.where((product) => product.isFlashDeal);
        break;
      case ProductFilter.inStock:
        items = items.where((product) => product.stock > 0);
        break;
    }

    final list = items.toList();

    switch (_sort) {
      case ProductSort.popular:
        break;
      case ProductSort.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSort.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSort.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case ProductSort.discount:
        list.sort(
          (a, b) => b.discountPercent.compareTo(a.discountPercent),
        );
        break;
    }

    return list;
  }

  void _scrollToProducts() {
    if (!_scroll.hasClients) return;

    _scroll.animateTo(
      math.min(220.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final all = widget.products;
    final subcategories = <String>{
      for (final product in widget.products)
        if (product.subcategory.isNotEmpty) product.subcategory,
    }.toList()
      ..sort();
    final bannerProduct = all.isEmpty ? null : all.first;
    final maxDiscount = all.fold<int>(
      0,
      (best, product) => math.max(best, product.discountPercent),
    );

    final scrollView = CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (widget.bannerTitle != null && bannerProduct != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                IanovaSpacing.xl,
                IanovaSpacing.xs,
                IanovaSpacing.xl,
                IanovaSpacing.lg,
              ),
              child: IanovaPromoBanner(
                title: widget.bannerTitle!,
                subtitle: maxDiscount > 0
                    ? 'Up to $maxDiscount% off'
                    : '${all.length} products',
                image: bannerProduct.image,
                emoji: bannerProduct.emoji,
                imageBackground: bannerProduct.bgColor,
                onPressed: _scrollToProducts,
              ),
            ),
          ),
        if (subcategories.length >= 2)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: IanovaSpacing.xl,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: 'All',
                        selected: _subcategory == null,
                        onTap: () => setState(() => _subcategory = null),
                      ),
                    ),
                    for (final name in subcategories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: name,
                          selected: _subcategory == name,
                          onTap: () => setState(() => _subcategory = name),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: IanovaSpacing.xl,
              ),
              children: [
                for (final filter in ProductFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: _filterLabel(filter),
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.xl,
              IanovaSpacing.md,
              IanovaSpacing.xl,
              IanovaSpacing.md,
            ),
            child: Row(
              children: [
                PopupMenuButton<ProductSort>(
                  initialValue: _sort,
                  onSelected: (value) => setState(() => _sort = value),
                  itemBuilder: (context) => [
                    for (final sort in ProductSort.values)
                      PopupMenuItem<ProductSort>(
                        value: sort,
                        child: Text(_sortLabel(sort)),
                      ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sort by',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: IanovaColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _sortLabel(_sort),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
                const Spacer(),
                _ViewButton(
                  icon: Icons.grid_view_rounded,
                  selected: _grid,
                  onTap: () => setState(() => _grid = true),
                ),
                const SizedBox(width: 8),
                _ViewButton(
                  icon: Icons.view_agenda_outlined,
                  selected: !_grid,
                  onTap: () => setState(() => _grid = false),
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(IanovaSpacing.huge),
              child: Center(
                child: Text(
                  'No products match this filter.',
                  style: TextStyle(color: IanovaColors.secondary),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              IanovaSpacing.xl,
              0,
              IanovaSpacing.xl,
              IanovaSpacing.xxxl,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = visible[index];

                  return IanovaProductCard(
                    product: product,
                    onTap: () => widget.onProductTap(product),
                    onCartChanged: widget.onCartChanged,
                  );
                },
                childCount: visible.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _grid ? 2 : 1,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: _grid ? 0.62 : 0.92,
              ),
            ),
          ),
      ],
    );

    if (widget.onRefresh == null) {
      return scrollView;
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh!,
      child: scrollView,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? IanovaColors.primary : IanovaColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? IanovaColors.primary : IanovaColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : IanovaColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? IanovaColors.primary : IanovaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? IanovaColors.primary : IanovaColors.border,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? Colors.white : IanovaColors.primary,
        ),
      ),
    );
  }
}
