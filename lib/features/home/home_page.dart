import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/state/wishlist_controller.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_card.dart';
import '../notifications/notifications_page.dart';
import '../search/search_page.dart';
import '../wishlist/wishlist_page.dart';
import 'hero_carousel.dart';
import 'product_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.onProductTap,
    this.onCartChanged,
  });

  final ValueChanged<Product>? onProductTap;
  final VoidCallback? onCartChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();

  List<Product> _products = const [];
  List<Category> _categories = const [];
  int? _selectedCategoryId;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStorefront();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadStorefront() async {
    WishlistController.instance.load();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getProducts(categoryId: _selectedCategoryId),
        _api.getCategories(),
      ]);

      if (!mounted) return;

      setState(() {
        _products = results[0] as List<Product>;
        _categories = results[1] as List<Category>;
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
        _error = 'Unable to connect to IANOVA.';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCategory(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    await _loadProductsForCategory(categoryId);
  }

  Future<void> _loadProductsForCategory(int? categoryId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await _api.getProducts(categoryId: categoryId);

      if (!mounted) return;

      setState(() {
        _products = products;
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
        _error = 'Unable to load products.';
        _isLoading = false;
      });
    }
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  }

  Future<void> _openWishlist() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WishlistPage(),
      ),
    );

    // The user may have removed items on that page.
    WishlistController.instance.load();
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchPage(
          onProductTap: widget.onProductTap,
          onCartChanged: widget.onCartChanged,
        ),
      ),
    );
  }

  void _openProductList(String title, List<Product> products) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListPage(
          title: title,
          products: products,
          onProductTap: widget.onProductTap,
          onCartChanged: widget.onCartChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flashDeals = _products
        .where((product) => product.isFlashDeal)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadStorefront,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              onNotifications: _openNotifications,
              onWishlist: _openWishlist,
            ),
          ),
          SliverToBoxAdapter(
            child: _SearchBar(onTap: _openSearch),
          ),
          SliverToBoxAdapter(
            child: _CategoryPicker(
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onSelected: _selectCategory,
            ),
          ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: _ErrorState(
                message: _error!,
                onRetry: _loadStorefront,
              ),
            )
          else if (_products.isEmpty)
            const SliverToBoxAdapter(
              child: _EmptyState(),
            )
          else ...[
            SliverToBoxAdapter(
              child: HeroCarousel(
                products: flashDeals.isNotEmpty ? flashDeals : _products,
                onProductTap: (product) =>
                    widget.onProductTap?.call(product),
              ),
            ),
            if (flashDeals.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Flash deals',
                  action: 'See all',
                  onAction: () =>
                      _openProductList('Flash deals', flashDeals),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 310,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      IanovaSpacing.xl,
                      4,
                      IanovaSpacing.xl,
                      IanovaSpacing.lg,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemCount: flashDeals.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 205,
                        child: IanovaProductCard(
                          product: flashDeals[index],
                          onTap: () => widget.onProductTap?.call(
                            flashDeals[index],
                          ),
                          onCartChanged: widget.onCartChanged,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Popular picks',
                action: 'View all',
                onAction: () =>
                    _openProductList('Popular picks', _products),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                IanovaSpacing.xl,
                4,
                IanovaSpacing.xl,
                IanovaSpacing.xxxl,
              ),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return IanovaProductCard(
                      product: _products[index],
                      onTap: () => widget.onProductTap?.call(
                        _products[index],
                      ),
                      onCartChanged: widget.onCartChanged,
                    );
                  },
                  childCount: _products.length,
                ),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.66,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onNotifications,
    required this.onWishlist,
  });

  final VoidCallback onNotifications;
  final VoidCallback onWishlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        IanovaSpacing.lg,
        IanovaSpacing.xl,
        IanovaSpacing.sm,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/ianova_logo.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return const Icon(
                Icons.shopping_bag_rounded,
                size: 42,
              );
            },
          ),
          const Spacer(),
          IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifications',
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
          IconButton(
            onPressed: onWishlist,
            tooltip: 'Wishlist',
            icon: const Icon(
              Icons.favorite_border_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        IanovaSpacing.sm,
        IanovaSpacing.xl,
        IanovaSpacing.lg,
      ),
      child: TextField(
        readOnly: true,
        canRequestFocus: false,
        onTap: onTap,
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

/// A single "All" pill. Tapping it opens a list with every category inside.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  String get _label {
    if (selectedCategoryId == null) {
      return 'All';
    }

    for (final category in categories) {
      if (category.id == selectedCategoryId) {
        return '${category.emoji} ${category.name}'.trim();
      }
    }

    return 'All';
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: IanovaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(IanovaSpacing.radiusXLarge),
        ),
      ),
      builder: (sheetContext) {
        void pick(int? categoryId) {
          Navigator.of(sheetContext).pop();
          onSelected(categoryId);
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                IanovaSpacing.xl,
                IanovaSpacing.xl,
                IanovaSpacing.xl,
                IanovaSpacing.xl,
              ),
              children: [
                Text(
                  'Categories',
                  style: Theme.of(sheetContext).textTheme.headlineSmall,
                ),
                const SizedBox(height: IanovaSpacing.sm),
                _CategoryOption(
                  emoji: '🛍️',
                  label: 'All',
                  selected: selectedCategoryId == null,
                  onTap: () => pick(null),
                ),
                for (final category in categories)
                  _CategoryOption(
                    emoji: category.emoji,
                    label: category.name,
                    selected: selectedCategoryId == category.id,
                    onTap: () => pick(category.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: IanovaSpacing.xl,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          onPressed: () => _openSheet(context),
          backgroundColor: IanovaColors.primary,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 8,
          ),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  const _CategoryOption({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Text(
        emoji,
        style: const TextStyle(fontSize: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        IanovaSpacing.sm,
        IanovaSpacing.xl,
        IanovaSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Spacer(),
          TextButton(
            onPressed: onAction,
            child: Text(action),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(IanovaSpacing.xxxl),
      child: Column(
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(IanovaSpacing.xxxl),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
          ),
          SizedBox(height: IanovaSpacing.md),
          Text(
            'No products found.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
