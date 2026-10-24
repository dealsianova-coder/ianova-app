import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_service.dart' show ApiException;
import '../auth/forgot_password_page.dart';
import 'admin_analytics.dart';
import 'admin_api.dart';
import 'admin_broadcast.dart';
import 'admin_catalog.dart';
import 'admin_team.dart';
import 'admin_activity.dart';
import 'admin_dashboard.dart';
import 'admin_money.dart';
import 'admin_more.dart';
import 'admin_orders.dart';
import 'admin_payments.dart';
import 'admin_products.dart';
import 'admin_sellers.dart';
import 'admin_store.dart';
import 'admin_ui.dart';

/// The IANOVA Admin app: the same sections, in the same order, as the website admin.
class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _NavItem {
  const _NavItem(this.key, this.icon, this.label, [this.badge]);

  final String key;
  final String icon;
  final String label;
  final String? badge;
}

class _AdminPageState extends State<AdminPage> {
  static const _items = <_NavItem>[
    _NavItem('dashboard', '📊', 'Dashboard'),
    _NavItem('analytics', '📈', 'Analytics'),
    _NavItem('products', '📦', 'Products', 'review_products'),
    _NavItem('categories', '🏷️', 'Categories'),
    _NavItem('orders', '🛒', 'Orders', 'pending_orders'),
    _NavItem('users', '👥', 'Users'),
    _NavItem('admins', '🛡️', 'Admin team'),
    _NavItem('activity', '🧾', 'Activity'),
    _NavItem('sellers', '🏪', 'Sellers', 'sellers'),
    _NavItem('broadcast', '📢', 'Broadcast'),
    _NavItem('subscribers', '✉️', 'Subscribers'),
    _NavItem('suggestions', '💡', 'Suggestions', 'suggestions'),
    _NavItem('email', '📧', 'Email alerts'),
    _NavItem('banners', '🖼️', 'Banners'),
    _NavItem('video', '🎬', 'Video ad'),
    _NavItem('store', '🎛️', 'Store control'),
    _NavItem('display', '🖥️', 'Display control'),
    _NavItem('flash', '⚡', 'Flash deals'),
    _NavItem('coupons', '🎟️', 'Coupons'),
    _NavItem('payouts', '💸', 'Seller payouts'),
    _NavItem('payments', '💳', 'Payments'),
    _NavItem('settings', '⚙️', 'Settings'),
    _NavItem('alerts', '🔔', 'Alerts', 'alerts'),
  ];

  bool? _signedIn;
  String _page = 'dashboard';
  Map<String, String> _args = <String, String>{};
  int _stamp = 0;
  Map<String, int> _counts = <String, int>{};
  Timer? _poll;
  List<String>? _allowed;
  bool _master = false;

  bool _can(String key) => key == 'admins' || (key == 'activity' ? _master : (_allowed == null || _allowed!.contains(key)));

  @override
  void initState() {
    super.initState();
    AdminApi.expiredHook = () {
      if (!mounted) return;
      setState(() {
        _signedIn = false;
      });
    };
    _check();
  }

  @override
  void dispose() {
    _poll?.cancel();
    AdminApi.expiredHook = null;
    super.dispose();
  }

  Future<void> _check() async {
    final token = await AdminApi.instance.token();

    if (!mounted) return;

    setState(() {
      _signedIn = token != null;
    });

    if (token != null) _startPolling();
  }

  void _startPolling() {
    _poll?.cancel();
    _loadCounts();
    _poll = Timer.periodic(const Duration(seconds: 25), (_) => _loadCounts());
  }

  Future<void> _loadCounts() async {
    try {
      final data = await AdminApi.instance.panel('nav_counts');

      if (!mounted) return;

      setState(() {
        final al = data['allowed'];

        if (al is List) _allowed = [for (final e in al) '$e'];
        _master = aBool(data['master']);

        if (!_can(_page)) {
          for (final it in _items) {
            if (_can(it.key)) {
              _page = it.key;
              break;
            }
          }
        }

        _counts = {
          'alerts': aInt(data['alerts']),
          'messages': aInt(data['messages']),
          'suggestions': aInt(data['suggestions']),
          'pending_orders': aInt(data['pending_orders']),
          'review_products': aInt(data['review_products']),
          'pending_sellers': aInt(data['pending_sellers']),
        };
      });
    } catch (_) {}
  }

  Future<void> _signOut() async {
    _poll?.cancel();
    await AdminApi.instance.signOut();

    if (!mounted) return;

    setState(() {
      _signedIn = false;
      _allowed = null;
      _page = 'dashboard';
      _args = <String, String>{};
    });
  }

  void _go(String page, [Map<String, String> args = const <String, String>{}]) {
    setState(() {
      _page = page;
      _args = Map<String, String>.from(args);
      _stamp++;
    });
  }

  int _badge(String? key) {
    if (key == null) return 0;
    if (key == 'sellers') {
      return (_counts['pending_sellers'] ?? 0) + (_counts['messages'] ?? 0);
    }

    return _counts[key] ?? 0;
  }

  String get _title {
    for (final item in _items) {
      if (item.key == _page) return item.label;
    }

    return 'Admin';
  }

  Widget _body() {
    if (!_can(_page)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 42)),
              const SizedBox(height: 10),
              const Text('No access to this section', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const AdminMuted('Ask the master admin if you need it.'),
              const SizedBox(height: 14),
              AdminButton('Open Admin team', small: true, onPressed: () => _go('admins')),
            ],
          ),
        ),
      );
    }

    switch (_page) {
      case 'products':
        return AdminProductsScreen(
          initialStatus: _args['status'] ?? '',
          initialCategory: aInt(_args['category']),
        );
      case 'categories':
        return const AdminCategoriesScreen();
      case 'orders':
        return AdminOrdersScreen(
          initialTab: _args['tab'] ?? 'main',
          initialStatus: _args['status'] ?? '',
          initialSeller: aInt(_args['seller']),
        );
      case 'users':
        return AdminUsersScreen(onGo: _go, initialRole: _args['role'] ?? 'all');
      case 'admins':
        return const AdminTeamScreen();
      case 'activity':
        return const AdminActivityScreen();
      case 'sellers':
        return const AdminSellersScreen();
      case 'subscribers':
        return const AdminSubscribersScreen();
      case 'suggestions':
        return const AdminSuggestionsScreen();
      case 'banners':
        return const AdminBannersScreen();
      case 'analytics':
        return AdminAnalyticsScreen(onGo: _go);
      case 'email':
        return const AdminEmailScreen();
      case 'video':
        return const AdminVideoAdScreen();
      case 'display':
        return const AdminDisplayScreen();
      case 'store':
        return const AdminStoreScreen();
      case 'flash':
        return const AdminFlashScreen();
      case 'coupons':
        return const AdminCouponsScreen();
      case 'payouts':
        return const AdminPayoutsScreen();
      case 'payments':
        return const AdminPaymentsScreen();
      case 'settings':
        return const AdminSettingsScreen();
      case 'alerts':
        return AdminAlertsScreen(onChanged: _loadCounts);
      default:
        return AdminDashboardScreen(onGo: _go);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _signedIn != true || _page == 'dashboard',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _go('dashboard');
      },
      child: _buildPage(context),
    );
  }

  Widget _buildPage(BuildContext context) {
    final signedIn = _signedIn;

    if (signedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!signedIn) {
      return _AdminLogin(
        onSignedIn: () {
          setState(() {
            _signedIn = true;
            _page = 'dashboard';
          });
          _startPolling();
        },
      );
    }

    final alerts = _counts['alerts'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            tooltip: 'Alerts',
            onPressed: () => _go('alerts'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (alerts > 0)
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AC.goldLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        alerts > 99 ? '99+' : '$alerts',
                        style: const TextStyle(
                          color: AC.side,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AC.side,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Wordmark(height: 34),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final item in _items)
                      if (_can(item.key))
                      _DrawerRow(
                        item: item,
                        selected: item.key == _page,
                        badge: _badge(item.badge),
                        onTap: () {
                          Navigator.of(context).pop();
                          if (item.key == 'broadcast') {
                            adminPush(
                              context,
                              AdminBroadcastPage(onExpired: () {
                                final hook = AdminApi.expiredHook;
                                if (hook != null) hook();
                              }),
                            );
                          } else {
                            _go(item.key);
                          }
                        },
                      ),
                    const SizedBox(height: 6),
                    _DrawerRow(
                      item: const _NavItem('viewstore', '🌐', 'View store'),
                      selected: false,
                      badge: 0,
                      onTap: () {
                        Navigator.of(context).pop();
                        launchUrl(Uri.parse(IanovaApiConfig.baseUrl), mode: LaunchMode.externalApplication);
                      },
                    ),
                    _DrawerRow(
                      item: const _NavItem('logout', '🚪', 'Logout'),
                      selected: false,
                      badge: 0,
                      onTap: () {
                        Navigator.of(context).pop();
                        _signOut();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: KeyedSubtree(
          key: ValueKey('$_page|$_stamp'),
          child: _body(),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      IanovaApiConfig.imageUrl('assets/img/ianova-wordmark.png'),
      height: height,
      errorBuilder: (_, _, _) => const Text(
        'IANOVA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? AC.side2 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Text(item.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFDCE8E2),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AC.goldLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(
                        color: AC.side,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminLogin extends StatefulWidget {
  const _AdminLogin({required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<_AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<_AdminLogin> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await AdminApi.instance.login(_email.text.trim(), _password.text);

      if (!mounted) return;

      widget.onSignedIn();
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to reach the server.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: AC.side,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 40,
              24,
              36,
            ),
            child: Column(
              children: [
                _Wordmark(height: 46),
                const SizedBox(height: 10),
                const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: AC.goldLight,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: AdminCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin sign in',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const AdminMuted(
                    'Use the same email and password as the website admin.',
                  ),
                  const SizedBox(height: 20),
                  AdminField(
                    label: 'Email',
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: AdminField.decoration(null),
                    onSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).push(MaterialPageRoute<void>(
                                builder: (_) => ForgotPasswordPage(
                                  kind: 'admin',
                                  initialEmail: _email.text.trim(),
                                ),
                              )),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDEAEA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFF8A2424)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: AdminButton(
                        'Sign in',
                        busy: _busy,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
