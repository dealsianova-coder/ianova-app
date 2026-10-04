import 'package:flutter/material.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_card.dart';

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
          const SliverToBoxAdapter(child: _Header()),
          const SliverToBoxAdapter(child: _SearchBar()),
          SliverToBoxAdapter(
            child: _CategoryStrip(
              categories: _categories,
              selectedCategoryId: _selectedCategoryId,
              onSelected: _selectCategory,
            ),
          ),
          const SliverToBoxAdapter(child: _HeroBanner()),
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
            if (flashDeals.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Flash deals',
                  action: 'See all',
                ),
              ),SliverToBoxAdapter(
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
                          onTap: () =>
                              widget.onProductTap?.call(
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
            const SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Popular picks',
                action: 'View all',
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
                      onTap: () =>
                          widget.onProductTap?.call(
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
  const _Header();

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
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
            ),
          ),
          IconButton(
            onPressed: () {},
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
  const _SearchBar();

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
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: IanovaSpacing.xl,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final isAll = index == 0;

          final selected = isAll
              ? selectedCategoryId == null
              : selectedCategoryId == categories[index - 1].id;

          final label = isAll
              ? 'All'
              : '${categories[index - 1].emoji} '
                  '${categories[index - 1].name}';

          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) {
              onSelected(
                isAll ? null : categories[index - 1].id,
              );
            },
            selectedColor: IanovaColors.primary,
            backgroundColor: IanovaColors.surface,
            labelStyle: TextStyle(
              color: selected
                  ? Colors.white
                  : IanovaColors.primary,
              fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(
              color: IanovaColors.border,
            ),
          );
        },
      ),
    );
  }
}
class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        IanovaSpacing.xl,
        IanovaSpacing.xl,
        IanovaSpacing.xl,
        IanovaSpacing.lg,
      ),
      child: Container(
        height: 178,
        padding: const EdgeInsets.all(IanovaSpacing.xxl),
        decoration: BoxDecoration(
          color: IanovaColors.primary,
          borderRadius: BorderRadius.circular(
            IanovaSpacing.radiusXLarge,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'IANOVA EXCLUSIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'New season.\nNew essentials.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 76,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
  });

  final String title;
  final String action;

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
            onPressed: () {},
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
