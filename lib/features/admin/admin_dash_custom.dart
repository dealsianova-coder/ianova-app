import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

class QuickDef {
  const QuickDef(this.label, this.sub, this.icon);

  final String label;
  final String sub;
  final IconData icon;
}

/// Same ids as DPF_QUICK in includes/dash_prefs.php (the page name is the id, except add_product).
const Map<String, QuickDef> kQuickActions = {
  'add_product': QuickDef('Add Product', 'Create new product', Icons.add_box_outlined),
  'orders': QuickDef('Manage Orders', 'View and process orders', Icons.shopping_cart_outlined),
  'sellers': QuickDef('Manage Sellers', 'Control seller accounts', Icons.storefront_outlined),
  'settings': QuickDef('Store Settings', 'Configure your store', Icons.settings_outlined),
  'revenue': QuickDef('Revenue', 'Where money came from', Icons.payments_outlined),
  'analytics': QuickDef('Analytics', 'Sales and trends', Icons.show_chart),
  'products': QuickDef('Products', 'Manage the catalogue', Icons.inventory_2_outlined),
  'categories': QuickDef('Categories', 'Organise products', Icons.category_outlined),
  'users': QuickDef('Customers', 'See your customers', Icons.groups_outlined),
  'coupons': QuickDef('Coupons', 'Discount codes', Icons.confirmation_number_outlined),
  'flash': QuickDef('Flash deals', 'Limited-time offers', Icons.bolt),
  'banners': QuickDef('Banners', 'Home page banners', Icons.image_outlined),
  'payouts': QuickDef('Seller payouts', 'Pay your sellers', Icons.account_balance_wallet_outlined),
  'payments': QuickDef('Payments', 'Balances to collect', Icons.credit_card),
  'broadcast': QuickDef('Broadcast', 'Message customers', Icons.campaign_outlined),
};

/// [background, icon colour] used in turn.
const List<List<Color>> kQuickColors = [
  [Color(0xFFFFF6E3), Color(0xFFB58117)],
  [Color(0xFFEAF3FF), Color(0xFF2F80ED)],
  [Color(0xFFF3EBFF), Color(0xFF8B3DFF)],
  [Color(0xFFE8F7EE), Color(0xFF16A34A)],
];

const List<List<String>> _sections = [
  ['welcome', 'Welcome card'],
  ['kpi_revenue', 'Revenue card'],
  ['kpi_orders', 'Orders card'],
  ['kpi_products', 'Products card'],
  ['kpi_customers', 'Customers card'],
  ['sales', 'Sales chart'],
  ['quick', 'Quick actions'],
  ['recent', 'Recent orders'],
  ['attention', 'Needs your attention'],
  ['more_orders', 'Panel: Orders'],
  ['more_products', 'Panel: Products'],
  ['more_categories', 'Panel: Categories'],
  ['more_sellers', 'Panel: Sellers'],
  ['more_users', 'Panel: Users'],
];

/// Choose what you see on your own dashboard and which quick actions it shows (opened from Settings).
class AdminDashCustomizePage extends StatefulWidget {
  const AdminDashCustomizePage({super.key});

  @override
  State<AdminDashCustomizePage> createState() => _AdminDashCustomizePageState();
}

class _AdminDashCustomizePageState extends State<AdminDashCustomizePage> with AdminLoad<AdminDashCustomizePage> {
  final Set<String> _hide = <String>{};
  final List<String> _quick = <String>[];
  bool _busy = false;
  bool _filled = false;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final d = await AdminApi.instance.panel('dash_prefs_get');

    if (!_filled) {
      final p = aMap(d['prefs']);
      _hide
        ..clear()
        ..addAll([for (final x in aList(p['hide'])) aStr(x)]);
      _quick
        ..clear()
        ..addAll([for (final x in aList(p['quick'])) aStr(x)]);
      _filled = true;
    }

    return d;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> _save() async {
    setState(() => _busy = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('dash_prefs_save', body: {'hide': _hide.toList(), 'quick': _quick}),
    );

    if (!mounted) return;

    setState(() => _busy = false);

    if (ok) {
      adminSay(context, 'Saved. Your dashboard now shows this.');
      Navigator.of(context).pop(true);
    }
  }

  void _reset() {
    setState(() {
      _hide.clear();
      _quick
        ..clear()
        ..addAll(['add_product', 'orders', 'sellers', 'settings']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminSubPage(
      title: 'Dashboard layout',
      child: gate((d) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const AdminMuted('Only you see these changes. Other admins keep their own dashboard.'),
            const SizedBox(height: 10),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Show on my dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  for (final s in _sections)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(s[1]),
                      value: !_hide.contains(s[0]),
                      onChanged: (v) => setState(() {
                        if (v) {
                          _hide.remove(s[0]);
                        } else {
                          _hide.add(s[0]);
                        }
                      }),
                    ),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const AdminMuted('Pick up to 8. They show in the order you tick them.'),
                  for (final e in kQuickActions.entries)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: Icon(e.value.icon, color: AC.gold),
                      title: Text(e.value.label),
                      subtitle: Text(e.value.sub, style: const TextStyle(fontSize: 12)),
                      value: _quick.contains(e.key),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            if (_quick.length < 8) _quick.add(e.key);
                          } else if (_quick.length > 1) {
                            _quick.remove(e.key);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(child: AdminButton('Save', busy: _busy, onPressed: _busy ? null : _save)),
                const SizedBox(width: 10),
                AdminButton('Reset', kind: 'gray', onPressed: _reset),
              ],
            ),
            const SizedBox(height: 24),
          ],
        );
      }),
    );
  }
}
