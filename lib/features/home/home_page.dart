import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/network/api_service.dart';
import '../../core/state/wishlist_controller.dart';
import '../../models/store_config.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/product.dart';
import '../../widgets/ianova_product_card.dart';
import '../notifications/notifications_page.dart';
import '../search/search_page.dart';
import '../wishlist/wishlist_page.dart';
import '../../core/storage/recent_products.dart';
import '../categories/categories_page.dart';
import '../products/product_detail_page.dart';
import 'category_rail.dart';
import 'flash_deals_section.dart';
import 'hero_carousel.dart';
import 'product_list_page.dart';
import 'recently_viewed_section.dart';
import 'video_ad_section.dart';

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
  List<int> _recentIds = const [];
  StoreConfig _store = StoreConfig.defaults;

  bool _isLoading = true;
  String? _error;

  bool _showingVideoAd = false;
  Timer? _videoAdCycleTimer;
  Timer? _videoAdHideTimer;
  bool _videoAdTimersArmedFor = false; // guards against re-arming on every rebuild

  @override
  void initState() {
    super.initState();
    _loadStorefront();
    _loadRecent();
    RecentProducts.changes.addListener(_loadRecent);
  }

  @override
  void dispose() {
    RecentProducts.changes.removeListener(_loadRecent);
    _videoAdCycleTimer?.cancel();
    _videoAdHideTimer?.cancel();
    _api.dispose();
    super.dispose();
  }

  void _armVideoAd() {
    final ad = _store.videoAd;
    if (!ad.isActive) {
      _videoAdCycleTimer?.cancel();
      _videoAdHideTimer?.cancel();
      _videoAdTimersArmedFor = false;
      if (_showingVideoAd) setState(() => _showingVideoAd = false);
      return;
    }

    if (_store.banners.isEmpty) {
      // No banners to fall back to — the ad just takes over that slot
      // permanently and loops itself (see VideoAdSection).
      _videoAdCycleTimer?.cancel();
      _videoAdHideTimer?.cancel();
      if (!_showingVideoAd) setState(() => _showingVideoAd = true);
      return;
    }

    if (_videoAdTimersArmedFor) return; // already running the interval cycle
    _videoAdTimersArmedFor = true;

    _videoAdCycleTimer?.cancel();
    _videoAdCycleTimer = Timer.periodic(
      Duration(minutes: ad.intervalMinutes),
      (_) {
        if (!mounted) return;
        setState(() => _showingVideoAd = true);
        _videoAdHideTimer?.cancel();
        _videoAdHideTimer = Timer(Duration(seconds: ad.minSeconds), () {
          if (mounted) setState(() => _showingVideoAd = false);
        });
      },
    );
  }

  void _openLink(String linkType, String linkValue) {
    switch (linkType) {
      case 'product':
        final productId = int.tryParse(linkValue);
        if (productId == null || productId < 1) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              productId: productId,
              onCartChanged: widget.onCartChanged,
            ),
          ),
        );
        break;
      case 'category':
        final categoryId = int.tryParse(linkValue);

        for (final category in _categories) {
          if (category.id == categoryId) {
            _openCategory(category);
            return;
          }
        }
        break;
      case 'search':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SearchPage(
              initialQuery: linkValue,
              onProductTap: widget.onProductTap,
              onCartChanged: widget.onCartChanged,
            ),
          ),
        );
        break;
      case 'url':
        final trimmed = linkValue.trim();
        if (trimmed.isEmpty) return;
        final uri = trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? Uri.tryParse(trimmed)
            : Uri.tryParse('${_api.baseUrl}/${trimmed.startsWith('/') ? trimmed.substring(1) : trimmed}');
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        break;
    }
  }

  Future<void> _loadStorefront() async {
    WishlistController.instance.load();
    _loadStore();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _api.getProducts(),
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

  Future<void> _loadStore() async {
    try {
      final config = await _api.getStoreConfig();

      if (!mounted) return;

      setState(() {
        _store = config;
      });
      _armVideoAd();
    } catch (_) {
      // Keep the defaults when the server has no store config yet.
    }
  }

  Future<void> _loadRecent() async {
    final ids = await RecentProducts.load();

    if (!mounted) return;

    setState(() {
      _recentIds = ids;
    });
  }

  void _openBanner(HomeBanner banner) {
    _openLink(banner.linkType, banner.linkValue);
  }

  void _openSale() {
    final sale = _products
        .where((product) => product.discountPercent > 0)
        .toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    _openProductList('Sale', sale);
  }

  void _openCategory(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryProductsPage(category: category),
      ),
    );
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

    final byId = {for (final product in _products) product.id: product};
    final recent = [
      for (final id in _recentIds)
        if (byId[id] != null) byId[id]!,
    ];

    return RefreshIndicator(
      onRefresh: _loadStorefront,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_store.announcement.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: IanovaColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: IanovaSpacing.xl,
                  vertical: 10,
                ),
                child: Text(
                  _store.announcement,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
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
            child: CategoryRail(
              categories: _store.showCategories ? _categories : const [],
              onSelect: _openCategory,
              onSale: _store.showSale ? _openSale : null,
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
              child: (_showingVideoAd && _store.videoAd.isActive)
                  ? VideoAdSection(
                      key: ValueKey('video-ad-${_store.videoAd.src}'),
                      config: _store.videoAd,
                      loopContinuously: _store.banners.isEmpty,
                      onCtaTap: _store.videoAd.hasLink
                          ? () => _openLink(
                                _store.videoAd.linkType,
                                _store.videoAd.linkValue,
                              )
                          : null,
                    )
                  : HeroCarousel(
                      products: flashDeals.isNotEmpty ? flashDeals : _products,
                      onProductTap: (product) =>
                          widget.onProductTap?.call(product),
                      banners: _store.banners,
                      onBannerTap: _openBanner,
                    ),
            ),
            if (flashDeals.isNotEmpty && _store.flashActive)
              SliverToBoxAdapter(
                child: FlashDealsSection(
                  title: _store.flashTitle,
                  endsAt: _store.flashEndsAt,
                  products: flashDeals,
                  onSeeAll: () =>
                      _openProductList('Flash deals', flashDeals),
                  onProductTap: (product) =>
                      widget.onProductTap?.call(product),
                  onCartChanged: widget.onCartChanged,
                ),
              ),
            if (recent.isNotEmpty && _store.showRecent)
              SliverToBoxAdapter(
                child: RecentlyViewedSection(
                  products: recent,
                  onProductTap: (product) =>
                      widget.onProductTap?.call(product),
                ),
              ),
            if (_store.showPopular) ...[
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
        IanovaSpacing.xl,
        IanovaSpacing.xl,
        IanovaSpacing.md,
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/ianova_wordmark.png',
            height: 40,
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
