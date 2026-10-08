import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/network/api_service.dart' show ApiException;
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'admin_api.dart';

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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Products'),
              Tab(text: 'Store'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersTab(onExpired: _signOut),
            _ProductsTab(onExpired: _signOut),
            _StoreTab(onExpired: _signOut),
          ],
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
      appBar: AppBar(title: const Text('Admin sign in')),
      body: ListView(
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        children: [
          const Text(
            'Use the same email and password as the website admin.',
            style: TextStyle(color: IanovaColors.secondary),
          ),
          const SizedBox(height: IanovaSpacing.xl),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Admin email'),
          ),
          const SizedBox(height: IanovaSpacing.md),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: 'Password'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: IanovaSpacing.md),
            Text(
              _error!,
              style: const TextStyle(color: IanovaColors.danger),
            ),
          ],
          const SizedBox(height: IanovaSpacing.xl),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Signing in...' : 'Sign in'),
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

          return InkWell(
            onTap: () => _pickStatus(order),
            borderRadius: BorderRadius.circular(IanovaSpacing.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(IanovaSpacing.lg),
              decoration: BoxDecoration(
                color: IanovaColors.surface,
                borderRadius:
                    BorderRadius.circular(IanovaSpacing.radiusMedium),
                border: Border.all(color: IanovaColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order['id']}  ${order['guest_name'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order['guest_phone'] ?? ''}',
                          style: const TextStyle(
                            color: IanovaColors.secondary,
                          ),
                        ),
                        Text(
                          '${order['address'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: IanovaColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order['created_at'] ?? ''}',
                          style: const TextStyle(
                            color: IanovaColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatKsh(total),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: IanovaColors.soft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _cap('${order['status']}'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(IanovaSpacing.lg),
                    itemCount: _products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      final price =
                          double.tryParse('${product['price']}') ?? 0;
                      final flash = '${product['is_flash_deal']}' == '1' ||
                          product['is_flash_deal'] == true;
                      final option =
                          '${product['color'] ?? ''} ${product['size'] ?? ''}'
                              .trim();

                      return InkWell(
                        onTap: () => _edit(product),
                        borderRadius: BorderRadius.circular(
                          IanovaSpacing.radiusMedium,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(IanovaSpacing.lg),
                          decoration: BoxDecoration(
                            color: IanovaColors.surface,
                            borderRadius: BorderRadius.circular(
                              IanovaSpacing.radiusMedium,
                            ),
                            border: Border.all(color: IanovaColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${product['name']}'
                                      '${option.isEmpty ? '' : '  ·  $option'}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${formatKsh(price)}  ·  '
                                      'Stock ${product['stock']}  ·  '
                                      '${_cap('${product['status']}')}',
                                      style: const TextStyle(
                                        color: IanovaColors.secondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (flash)
                                const Icon(
                                  Icons.bolt_rounded,
                                  color: IanovaColors.danger,
                                ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.product['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: IanovaSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Sale price'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _original,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'Old price'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Stock'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Flash deal'),
              value: _flash,
              onChanged: (value) => setState(() => _flash = value),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final status in const ['approved', 'pending', 'rejected'])
                  ChoiceChip(
                    label: Text(_cap(status)),
                    selected: _status == status,
                    onSelected: (_) => setState(() => _status = status),
                  ),
              ],
            ),
            const SizedBox(height: IanovaSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save changes'),
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

    return ListView(
      padding: const EdgeInsets.all(IanovaSpacing.xl),
      children: [
        const Text(
          'Announcement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _announcement,
          decoration: const InputDecoration(hintText: 'Message for the top bar'),
        ),
        const SizedBox(height: IanovaSpacing.xl),
        const Text(
          'Flash deals end',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          _endsAt.isEmpty ? 'No countdown' : _endsAt,
          style: const TextStyle(color: IanovaColors.secondary),
        ),
        Row(
          children: [
            TextButton(onPressed: _pickEnd, child: const Text('Pick date and time')),
            TextButton(
              onPressed: () => setState(() => _endsAt = ''),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: IanovaSpacing.md),
        const Text(
          'Delivery',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _freeOver,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Free over (KSh)'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _fee,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Fee (KSh)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: IanovaSpacing.xl),
        const Text(
          'Home screen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        for (final entry in _toggleLabels.entries)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.value),
            value: _flags[entry.key] ?? false,
            onChanged: (value) => setState(() => _flags[entry.key] = value),
          ),
        const SizedBox(height: IanovaSpacing.md),
        const Text(
          'Support contact',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Phone'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'Email'),
        ),
        const SizedBox(height: IanovaSpacing.xl),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save changes'),
        ),
      ],
    );
  }
}
