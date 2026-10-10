import 'package:flutter/material.dart';

import 'core/network/api_service.dart';
import 'core/state/wishlist_controller.dart';
import 'core/theme/ianova_theme.dart';
import 'features/home/home_page.dart';
import 'features/splash/splash_page.dart';
import 'features/products/product_detail_page.dart';
import 'features/categories/categories_page.dart';
import 'features/cart/cart_page.dart';
import 'features/profile/profile_page.dart';
import 'models/product.dart';

void main() {
  runApp(const IanovaApp());
}

class IanovaApp extends StatelessWidget {
  const IanovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IANOVA',
      theme: IanovaTheme.light(),
      home: const SplashGate(next: IanovaShell()),
    );
  }
}

class IanovaShell extends StatefulWidget {
  const IanovaShell({super.key});

  @override
  State<IanovaShell> createState() => _IanovaShellState();
}

class _IanovaShellState extends State<IanovaShell> {
  final ApiService _api = ApiService();

  int _currentIndex = 0;
  int _cartRefreshToken = 0;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
    WishlistController.instance.load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    try {
      final cart = await _api.getCart();
      if (!mounted) return;

      setState(() {
        _cartItemCount = cart.itemCount;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401 && mounted) {
        setState(() {
          _cartItemCount = 0;
        });
      }
    } catch (_) {
      // Keep the last known badge value when the cart cannot be reached.
    }
  }

  Future<void> _openProduct(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          onCartChanged: _loadCartCount,
        ),
      ),
    );

    if (mounted) {
      await _loadCartCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onProductTap: _openProduct,
        onCartChanged: _loadCartCount,
      ),
      const CategoriesPage(),
      CartPage(
        refreshToken: _cartRefreshToken,
        onCartChanged: _loadCartCount,
        onContinueShopping: () {
          setState(() {
            _currentIndex = 0;
          });
        },
      ),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            if (index == 2) {
              _cartRefreshToken++;
              _loadCartCount();
            }
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: _CartBadge(
              count: _cartItemCount,
              child: Icon(Icons.shopping_bag_outlined),
            ),
            selectedIcon: _CartBadge(
              count: _cartItemCount,
              child: Icon(Icons.shopping_bag_rounded),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }


}


class _CartBadge extends StatelessWidget {
  const _CartBadge({
    required this.count,
    required this.child,
  });

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return child;
    }

    final label = count > 99 ? '99+' : count.toString();

    return Badge(
      label: Text(label),
      isLabelVisible: true,
      child: child,
    );
  }
}
