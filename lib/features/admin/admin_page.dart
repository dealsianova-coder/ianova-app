import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/format/money.dart';
import '../../core/network/api_service.dart' show ApiException;
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../core/state/app_badges.dart';
import '../../widgets/panel_ui.dart';
import 'admin_api.dart';
import 'admin_extras.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String _two(int value) => value.toString().padLeft(2, '0');

String _cap(String value) {
  return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool? _signedIn;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await AdminApi.instance.token();

    if (!mounted) return;

    setState(() {
      _signedIn = token != null;
    });
  }

  Future<void> _signOut() async {
    await AdminApi.instance.signOut();

    if (!mounted) return;

    setState(() {
      _signedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _signedIn;

    if (signedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!signedIn) {
      return _AdminLogin(
        onSignedIn: () => setState(() => _signedIn = true),
      );
    }

    return AdminBadgePoller(
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Admin',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: IanovaColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: IanovaColors.secondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 18),
                  tabs: [
                    const Tab(height: 38, text: 'Orders'),
                    const Tab(height: 38, text: 'Products'),
                    const Tab(height: 38, text: 'Store'),
                    Tab(
                      height: 38,
                      child: BadgeLabel(
                        label: 'Alerts',
                        count: AppBadges.adminAlerts,
                      ),
                    ),
                    Tab(
                      height: 38,
                      child: BadgeLabel(
                        label: 'Sellers',
                        count: AppBadges.adminMessages,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            children: [
              _OrdersTab(onExpired: _signOut),
              _ProductsTab(onExpired: _signOut),
              _StoreTab(onExpired: _signOut),
              AdminAlertsTab(onExpired: _signOut),
              AdminSellersTab(onExpired: _signOut),
            ],
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
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Image.asset(
              'assets/images/ianova_logo.png',
              height: 64,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: panelDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin sign in',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Use the same email and password as the website admin.',
                  style: TextStyle(color: IanovaColors.secondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Admin email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: IanovaSpacing.md),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: IanovaSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: IanovaColors.danger),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Signing in...' : 'Sign in'),
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

class _Loading extends StatelessWidget {
  const _Loading({required this.error, required this.onRetry});

  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IanovaSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: IanovaSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ orders

class _OrdersTab extends StatefulWidget {
  const _OrdersTab({required this.onExpired});

  final VoidCallback onExpired;

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  static const _statuses = [
    'pending',
    'approved',
    'paid',
    'shipped',
    'delivered',
    'cancelled',
  ];

  List<Map<String, dynamic>> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await AdminApi.instance.orders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        widget.onExpired();
        return;
      }

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to reach the server.';
        _loading = false;
      });
    }
  }

  Future<void> _pickStatus(Map<String, dynamic> order) async {
    final current = order['status']?.toString() ?? '';

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(IanovaSpacing.lg),
                child: Text(
                  'Order #${order['id']} status',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              for (final status in _statuses)
                ListTile(
                  title: Text(_cap(status)),
                  trailing:
                      status == current ? const Icon(Icons.check_rounded) : null,
                  onTap: () => Navigator.of(sheet).pop(status),
                ),
            ],
          ),
        );
      },
    );

    if (chosen == null || chosen == current) return;

    try {
      await AdminApi.instance.setOrderStatus(
        int.tryParse('${order['id']}') ?? 0,
        chosen,
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) _snack(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return _Loading(error: _error, onRetry: _load);
    }

    if (_orders.isEmpty) {
      return const Center(child: Text('No orders yet.'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(IanovaSpacing.lg),
        itemCount: _orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = _orders[index];
          final total = double.tryParse('${order['total']}') ?? 0;

          final status = '${order['status']}';
          final statusColor = status == 'delivered' || status == 'completed'
              ? const Color(0xFF17803D)
              : status == 'cancelled'
                  ? const Color(0xFFB3261E)
                  : const Color(0xFFA05A00);

          return InkWell(
            onTap: () => _pickStatus(order),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: panelDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${order['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      StatusPill(_cap(status), statusColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order['created_at'] ?? ''}',
                    style: const TextStyle(
                      color: IanovaColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OrderThumbs(items: order['items']),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: IanovaColors.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${order['guest_name'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        if ('${order['guest_phone'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined,
                                  size: 16, color: IanovaColors.secondary),
                              const SizedBox(width: 8),
                              Text(
                                '${order['guest_phone']}',
                                style: const TextStyle(
                                    color: IanovaColors.secondary),
                              ),
                            ],
                          ),
                        ],
                        if ('${order['address'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: IanovaColors.secondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${order['address']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: IanovaColors.secondary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Tap to change status',
                          style: TextStyle(
                            color: IanovaColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        formatKsh(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- products

class _ProductsTab extends StatefulWidget {
  const _ProductsTab({required this.onExpired});

  final VoidCallback onExpired;

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _products = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await PhotoLookup.ensureLoaded();
      final products = await AdminApi.instance.products(_search.text.trim());

      if (!mounted) return;

      setState(() {
        _products = products;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        widget.onExpired();
        return;
      }

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to reach the server.';
        _loading = false;
      });
    }
  }

  Future<void> _edit(Map<String, dynamic> product) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProductEditor(product: product),
    );

    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            IanovaSpacing.lg,
            IanovaSpacing.md,
            IanovaSpacing.lg,
            IanovaSpacing.sm,
          ),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: const InputDecoration(
              hintText: 'Search products',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: (_loading || _error != null)
              ? _Loading(error: _error, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(IanovaSpacing.lg),
                    children: [
                      TwoColumnGrid(
                        children: [
                          for (final product in _products)
                            _AdminProductCard(
                              product: product,
                              onTap: () => _edit(product),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _AdminProductCard extends StatelessWidget {
  const _AdminProductCard({required this.product, required this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse('${product['price']}') ?? 0;
    final flash = '${product['is_flash_deal']}' == '1' ||
        product['is_flash_deal'] == true;
    final option =
        '${product['color'] ?? ''} ${product['size'] ?? ''}'.trim();
    final status = '${product['status']}';
    final statusColor = status == 'approved' || status == 'active'
        ? const Color(0xFF17803D)
        : status == 'pending'
            ? const Color(0xFFA05A00)
            : const Color(0xFFB3261E);
    final photo = PhotoLookup.forProduct(
      id: int.tryParse('${product['id']}'),
      name: '${product['name']}',
      own: '${product['image'] ?? product['image_url'] ?? ''}',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: panelDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ImageBlock(url: photo, radius: 14),
                Positioned(
                  left: 8,
                  top: 8,
                  child: StatusPill(_cap(status), statusColor),
                ),
                if (flash)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.bolt_rounded,
                          size: 18, color: IanovaColors.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${product['name']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              formatKsh(price),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                InfoChip('Stock ${product['stock']}',
                    icon: Icons.inventory_2_outlined),
                if (option.isNotEmpty) InfoChip(option),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({required this.product});

  final Map<String, dynamic> product;

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  late final TextEditingController _price;
  late final TextEditingController _original;
  late final TextEditingController _stock;
  late bool _flash;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _price = TextEditingController(text: '${p['price']}');
    _original = TextEditingController(text: '${p['original_price']}');
    _stock = TextEditingController(text: '${p['stock']}');
    _flash = '${p['is_flash_deal']}' == '1' || p['is_flash_deal'] == true;
    _status = '${p['status']}';
  }

  @override
  void dispose() {
    _price.dispose();
    _original.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    try {
      await AdminApi.instance.updateProduct(
        int.tryParse('${widget.product['id']}') ?? 0,
        {
          'price': double.tryParse(_price.text) ?? 0,
          'original_price': double.tryParse(_original.text) ?? 0,
          'stock': int.tryParse(_stock.text) ?? 0,
          'is_flash_deal': _flash,
          'status': _status,
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });
      _snack(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final photo = PhotoLookup.forProduct(
      id: int.tryParse('${p['id']}'),
      name: '${p['name']}',
      own: '${p['image'] ?? p['image_url'] ?? ''}',
    );
    final option = '${p['color'] ?? ''} ${p['size'] ?? ''}'.trim();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ImageBlock(url: photo, size: 72, radius: 16),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p['name']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (option.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        InfoChip(option),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SectionCard(
              icon: Icons.sell_outlined,
              title: 'Pricing',
              subtitle: 'What customers pay',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Sale price'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _original,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Old price'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Stock',
              children: [
                TextField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Units in stock'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(
              icon: Icons.bolt_rounded,
              title: 'Visibility',
              tint: IanovaColors.blush,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Flash deal'),
                  subtitle: const Text('Show on the home screen flash section'),
                  value: _flash,
                  onChanged: (value) => setState(() => _flash = value),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in const [
                      'approved',
                      'pending',
                      'rejected',
                      'hidden',
                    ])
                      ChoiceChip(
                        label: Text(_cap(status)),
                        selected: _status == status,
                        onSelected: (_) => setState(() => _status = status),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- store

class _StoreTab extends StatefulWidget {
  const _StoreTab({required this.onExpired});

  final VoidCallback onExpired;

  @override
  State<_StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<_StoreTab> {
  static const _toggleLabels = {
    'announcement_enabled': 'Show announcement',
    'show_flash': 'Flash deals',
    'show_sale': 'Sale shortcut',
    'show_categories': 'Category shortcuts',
    'show_recent': 'Recently viewed',
    'show_popular': 'Popular picks',
  };

  final Map<String, bool> _flags = {};
  final TextEditingController _announcement = TextEditingController();
  final TextEditingController _fee = TextEditingController();
  final TextEditingController _freeOver = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  String _endsAt = '';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _announcement.dispose();
    _fee.dispose();
    _freeOver.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final store = await AdminApi.instance.storeGet();

      if (!mounted) return;

      setState(() {
        for (final key in _toggleLabels.keys) {
          _flags[key] = '${store[key]}' == '1';
        }
        _announcement.text = '${store['announcement_text']}';
        _fee.text = '${store['delivery_fee']}';
        _freeOver.text = '${store['free_delivery_threshold']}';
        _phone.text = '${store['support_phone']}';
        _email.text = '${store['support_email']}';
        _endsAt = '${store['flash_ends_at']}';
        _loading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        widget.onExpired();
        return;
      }

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to reach the server.';
        _loading = false;
      });
    }
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 23, minute: 59),
    );

    if (time == null || !mounted) return;

    setState(() {
      _endsAt = '${date.year}-${_two(date.month)}-${_two(date.day)} '
          '${_two(time.hour)}:${_two(time.minute)}:00';
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    try {
      await AdminApi.instance.storeSet({
        for (final entry in _flags.entries) entry.key: entry.value,
        'announcement_text': _announcement.text,
        'delivery_fee': double.tryParse(_fee.text) ?? 0,
        'free_delivery_threshold': double.tryParse(_freeOver.text) ?? 0,
        'support_phone': _phone.text,
        'support_email': _email.text,
        'flash_ends_at': _endsAt,
      });

      if (!mounted) return;

      _snack(context, 'Saved. The store is updated.');
    } on ApiException catch (error) {
      if (mounted) _snack(context, error.message);
    }

    if (mounted) {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _error != null) {
      return _Loading(error: _error, onRetry: _load);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                icon: Icons.campaign_outlined,
                title: 'Announcement',
                subtitle: 'Message in the top bar',
                tint: IanovaColors.sand,
                children: [
                  TextField(
                    controller: _announcement,
                    decoration: const InputDecoration(
                      hintText: 'Message for the top bar',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                icon: Icons.bolt_rounded,
                title: 'Flash deals',
                subtitle: 'When the countdown ends',
                tint: IanovaColors.blush,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: IanovaColors.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endsAt.isEmpty ? 'No countdown' : _endsAt,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickEnd,
                          child: const Text('Pick date and time'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () => setState(() => _endsAt = ''),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                icon: Icons.local_shipping_outlined,
                title: 'Delivery',
                subtitle: 'Fee and free-delivery limit',
                tint: IanovaColors.sky,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _freeOver,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Free over (KSh)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _fee,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Fee (KSh)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                icon: Icons.home_outlined,
                title: 'Home screen',
                subtitle: 'Choose what customers see',
                children: [
                  for (final entry in _toggleLabels.entries)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(entry.value),
                      value: _flags[entry.key] ?? false,
                      onChanged: (value) =>
                          setState(() => _flags[entry.key] = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                icon: Icons.support_agent_rounded,
                title: 'Support contact',
                children: [
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: IanovaColors.border)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save changes'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Product photos of an order, each with its quantity.
class _OrderThumbs extends StatelessWidget {
  const _OrderThumbs({required this.items});

  final Object? items;

  Color _hex(String hex) {
    final clean = hex.replaceFirst('#', '');
    final value = clean.length == 6 ? int.tryParse(clean, radix: 16) : null;

    return value == null ? const Color(0xFFEFF3EC) : Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    final list = items is List ? (items as List).whereType<Map>().toList() : [];

    if (list.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in list)
          Tooltip(
            message: '${item['quantity']} × ${item['name']}',
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: _hex('${item['bg_color'] ?? ''}'),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: '${item['image'] ?? ''}'.isEmpty
                          ? Center(
                              child: Text(
                                '${item['emoji'] ?? ''}'.isEmpty
                                    ? '📦'
                                    : '${item['emoji']}',
                                style: const TextStyle(fontSize: 24),
                              ),
                            )
                          : Image.network(
                              IanovaApiConfig.imageUrl('${item['image']}'),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image_not_supported_outlined),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: IanovaColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${item['quantity']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
