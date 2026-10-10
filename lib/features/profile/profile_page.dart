import 'package:flutter/material.dart';
import '../../core/format/money.dart';

import '../../core/network/api_service.dart';
import '../../core/storage/auth_storage.dart';
import '../../core/state/wishlist_controller.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/order.dart';
import '../auth/auth_user.dart';
import '../admin/admin_page.dart';
import '../auth/login_page.dart';
import '../orders/orders_page.dart';
import '../wishlist/wishlist_page.dart';
import 'addresses_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();

  AuthUser? _user;
  Order? _latestOrder;
  bool _isLoading = true;
  bool _isLoadingOrder = true;
  String? _orderError;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _loadLatestOrder();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final user = await AuthStorage.getUser();

    if (!mounted) {
      return;
    }

    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _loadLatestOrder() async {
    setState(() {
      _isLoadingOrder = true;
      _orderError = null;
    });

    try {
      final orders = await _api.getOrders(
        page: 1,
        limit: 1,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latestOrder = orders.isEmpty ? null : orders.first;
        _isLoadingOrder = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _latestOrder = null;
        _orderError = error.toString();
        _isLoadingOrder = false;
      });
    }
  }

  Future<void> _openLogin() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );

    if (loggedIn == true) {
      WishlistController.instance.load();
      await _loadSession();
    }
  }

  Future<void> _logout() async {
    await AuthStorage.clearSession();
    WishlistController.instance.clear();

    if (!mounted) {
      return;
    }

    setState(() {
      _user = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have been signed out.'),
      ),
    );
  }

  void _openOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OrdersPage(),
      ),
    );
  }

  void _openWishlist() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WishlistPage(),
      ),
    );
  }

  void _openAddresses() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddressesPage(),
      ),
    );
  }

  void _openAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdminPage(),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        backgroundColor: IanovaColors.background,
        elevation: 0,
        titleSpacing: IanovaSpacing.xl,
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Admin',
            onPressed: _openAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: IanovaSpacing.md),
            child: IconButton(
              tooltip: 'Settings',
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadSession,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  IanovaSpacing.md,
                  IanovaSpacing.sm,
                  IanovaSpacing.md,
                  IanovaSpacing.xl,
                ),
                children: [
                  _ProfileHero(
                    user: user,
                    onSignIn: _openLogin,
                    onSignOut: _logout,
                  ),
                  const SizedBox(height: IanovaSpacing.lg),
                  const _SectionHeading(
                    title: 'Quick access',
                  ),
                  const SizedBox(height: IanovaSpacing.sm),
                  _QuickActionGrid(
                    onOrders: _openOrders,
                    onWishlist: _openWishlist,
                    onAddresses: _openAddresses,
                    onSettings: _openSettings,
                  ),
                  const SizedBox(height: IanovaSpacing.xl),
                  _AccountActivityCard(
                    order: _latestOrder,
                    loading: _isLoadingOrder,
                    error: _orderError,
                    onOrders: _openOrders,
                    onRetry: _loadLatestOrder,
                  ),
                  const SizedBox(height: IanovaSpacing.xl),
                  _SupportCard(
                    onSettings: _openSettings,
                  ),
                  const SizedBox(height: IanovaSpacing.lg),
                  if (user != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.user,
    required this.onSignIn,
    required this.onSignOut,
  });

  final AuthUser? user;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = user != null;

    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: BoxDecoration(
        color: IanovaColors.soft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -32,
            child: Icon(
              Icons.eco_rounded,
              size: 150,
              color: IanovaColors.primary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: IanovaColors.border,
                      ),
                    ),
                    child: Icon(
                      isSignedIn
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      color: IanovaColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: IanovaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignedIn
                              ? 'Welcome, ${user!.name}'
                              : 'Welcome to IANOVA',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignedIn
                              ? user!.email
                              : 'Sign in to manage your account',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: IanovaColors.secondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: IanovaSpacing.lg),
              if (isSignedIn)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                        ),
                        label: const Text('Sign out'),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onSignIn,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Sign in'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({
    required this.onOrders,
    required this.onWishlist,
    required this.onAddresses,
    required this.onSettings,
  });

  final VoidCallback onOrders;
  final VoidCallback onWishlist;
  final VoidCallback onAddresses;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: IanovaSpacing.sm,
      mainAxisSpacing: IanovaSpacing.sm,
      childAspectRatio: 1.38,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _QuickActionCard(
          icon: Icons.inventory_2_outlined,
          title: 'My orders',
          subtitle: 'Track purchases',
          onTap: onOrders,
        ),
        _QuickActionCard(
          icon: Icons.favorite_border_rounded,
          title: 'Wishlist',
          subtitle: 'Saved products',
          onTap: onWishlist,
        ),
        _QuickActionCard(
          icon: Icons.location_on_outlined,
          title: 'Addresses',
          subtitle: 'Delivery locations',
          onTap: onAddresses,
        ),
        _QuickActionCard(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'App preferences',
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(IanovaSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: IanovaColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: IanovaColors.soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: IanovaColors.primary,
                  size: 23,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: IanovaColors.secondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountActivityCard extends StatelessWidget {
  const _AccountActivityCard({
    required this.order,
    required this.loading,
    required this.error,
    required this.onOrders,
    required this.onRetry,
  });

  final Order? order;
  final bool loading;
  final String? error;
  final VoidCallback onOrders;
  final VoidCallback onRetry;

  String _statusLabel(String status) {
    if (status.isEmpty) {
      return 'Pending';
    }

    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your shopping',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: onOrders,
                child: const Text('View orders'),
              ),
            ],
          ),
          const SizedBox(height: IanovaSpacing.sm),
          if (loading)
            const _OrderPreviewLoading()
          else if (error != null)
            _OrderPreviewError(
              onRetry: onRetry,
            )
          else if (order == null)
            const _NoOrdersPreview()
          else
            _LatestOrderPreview(
              order: order!,
              statusLabel: _statusLabel(order!.status),
              onTap: onOrders,
            ),
        ],
      ),
    );
  }
}

class _OrderPreviewLoading extends StatelessWidget {
  const _OrderPreviewLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: IanovaColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _OrderPreviewError extends StatelessWidget {
  const _OrderPreviewError({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.md),
      decoration: BoxDecoration(
        color: IanovaColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined),
          const SizedBox(width: IanovaSpacing.sm),
          const Expanded(
            child: Text(
              'Unable to load recent orders.',
              style: TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NoOrdersPreview extends StatelessWidget {
  const _NoOrdersPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.md),
      decoration: BoxDecoration(
        color: IanovaColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: IanovaColors.soft,
                borderRadius: BorderRadius.all(
                  Radius.circular(14),
                ),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: IanovaColors.primary,
              ),
            ),
          ),
          SizedBox(width: IanovaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No orders yet',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your purchases will appear here after you place an order.',
                  style: TextStyle(
                    color: IanovaColors.secondary,
                    fontSize: 12,
                    height: 1.35,
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

class _LatestOrderPreview extends StatelessWidget {
  const _LatestOrderPreview({
    required this.order,
    required this.statusLabel,
    required this.onTap,
  });

  final Order order;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.isNotEmpty
        ? order.items.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          )
        : null;

    return Material(
      color: IanovaColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(IanovaSpacing.md),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: IanovaColors.primary,
                  ),
                  const SizedBox(width: IanovaSpacing.sm),
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _OrderStatusChip(
                    label: statusLabel,
                  ),
                ],
              ),
              const SizedBox(height: IanovaSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _OrderStat(
                      label: 'Total',
                      value: formatKsh(order.total),
                    ),
                  ),
                  Expanded(
                    child: _OrderStat(
                      label: 'Items',
                      value: itemCount == null
                          ? 'Order details'
                          : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  const _OrderStatusChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: IanovaColors.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: IanovaColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OrderStat extends StatelessWidget {
  const _OrderStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: IanovaColors.secondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.onSettings,
  });

  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: IanovaColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: IanovaColors.soft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: IanovaColors.primary,
            ),
          ),
          const SizedBox(width: IanovaSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personalize your experience',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Control notifications and other app preferences.',
                  style: TextStyle(
                    color: IanovaColors.secondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
