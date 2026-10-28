import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import 'admin_api.dart';
import 'admin_dark.dart';
import 'admin_orders.dart';
import 'admin_products.dart';
import 'admin_ui.dart';

typedef AdminGo = void Function(String page, Map<String, String> args);

/// Same blocks as the website admin dashboard: tiles, attention, orders, products...
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, required this.onGo});

  final AdminGo onGo;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.panel('dashboard');

      if (!mounted) return;

      setState(() {
        _data = data;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = adminErr(error);
        _loading = false;
      });
    }
  }

  void _go(String page, [Map<String, String> args = const <String, String>{}]) {
    widget.onGo(page, args);
  }

  Future<void> _openOrder(int id, String tab) async {
    await adminPush(context, AdminOrderViewPage(id: id, tab: tab));
    _load();
  }

  Future<void> _openProduct(int id) async {
    await adminPush(context, AdminProductViewPage(id: id));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    if (_loading) return const AdminLoading();

    if (data == null) return AdminLoading(error: _error, onRetry: _load);

    final c = aMap(data['counts']);
    final pendingOrders = aInt(c['pending_orders']);
    final reviewProducts = aInt(c['review_products']);
    final pendingSellers = aInt(c['pending_sellers']);

    final attention = <List<dynamic>>[
      ['🛒', 'Pending orders', pendingOrders, 'orders', <String, String>{'status': 'pending'}],
      ['⏳', 'Products to review', reviewProducts, 'products', <String, String>{'status': 'pending'}],
      ['🏪', 'Sellers to approve', pendingSellers, 'sellers', <String, String>{}],
      ['💬', 'Unread seller messages', aInt(c['unread_messages']), 'sellers', <String, String>{}],
      ['🔔', 'Unread alerts', aInt(c['alerts']), 'alerts', <String, String>{}],
      ['⚠️', 'Low stock (3 or less)', aInt(c['low_stock']), 'products', <String, String>{}],
      ['⏰', 'Orders waiting over 24 hours', aInt(c['old_pending']), 'orders', <String, String>{'status': 'pending'}],
      ['🚚', 'Shipped over 7 days, not delivered', aInt(c['stuck_shipped']), 'orders', <String, String>{'status': 'shipped'}],
      ['💳', 'Orders with a balance to collect', aInt(c['to_collect']), 'payments', <String, String>{}],
      ['💸', 'Sellers waiting for a payout', aInt(c['payouts_due']), 'payouts', <String, String>{}],
      ['💾', 'No backup in the last 3 days', aInt(c['backup_old']), 'dashboard', <String, String>{}],
    ];

    var attentionTotal = 0;
    for (final a in attention) {
      attentionTotal += a[2] as int;
    }

    final main = aMap(data['main']);
    final sellersOrders = aMap(data['sellers_orders']);
    final groups = aList(sellersOrders['groups']);
    final recent = aList(data['recent_products']);
    final low = aList(data['low_items']);
    final cats = aList(data['categories']);
    final sellers = aList(data['sellers']);
    final users = aList(data['users']);

    var maxCat = 1;
    for (final cat in cats) {
      if (aInt(cat['n']) > maxCat) maxCat = aInt(cat['n']);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Welcome(onTap: () => _go('analytics')),
          _KpiGrid(
            revenue: formatKsh(aNum(c['revenue'])),
            orders: aInt(c['orders']),
            products: aInt(c['products']),
            customers: aInt(c['users']),
            trends: aMap(data['trends']),
            onGo: _go,
          ),
          _SalesCard(sales: aMap(data['sales']), onTap: () => _go('analytics')),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Text('Manage your store with ease.', style: TextStyle(color: AC.muted, fontSize: 13)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.9,
                  children: [
                    _QuickAction(
                      icon: Icons.add_box_outlined,
                      title: 'Add Product',
                      sub: 'Create new product',
                      bg: const Color(0xFFFFF6E3),
                      fg: AC.gold,
                      onTap: () async {
                        await adminPush(context, const AdminProductEditPage());
                        _load();
                      },
                    ),
                    _QuickAction(
                      icon: Icons.shopping_cart_outlined,
                      title: 'Manage Orders',
                      sub: 'View and process orders',
                      bg: const Color(0xFFEAF3FF),
                      fg: const Color(0xFF2F80ED),
                      onTap: () => _go('orders'),
                    ),
                    _QuickAction(
                      icon: Icons.storefront_outlined,
                      title: 'Manage Sellers',
                      sub: 'Control seller accounts',
                      bg: const Color(0xFFF3EBFF),
                      fg: const Color(0xFF8B3DFF),
                      onTap: () => _go('sellers'),
                    ),
                    _QuickAction(
                      icon: Icons.settings_outlined,
                      title: 'Store Settings',
                      sub: 'Configure your store',
                      bg: const Color(0xFFE8F7EE),
                      fg: const Color(0xFF16A34A),
                      onTap: () => _go('settings'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    TextButton(onPressed: () => _go('orders'), child: const Text('View all ›')),
                  ],
                ),
                const Text('Latest orders from your customers', style: TextStyle(color: AC.muted, fontSize: 13)),
                const SizedBox(height: 8),
                if (aList(data['latest_orders']).isEmpty) const AdminMuted('No orders yet.'),
                for (final o in aList(data['latest_orders']))
                  _RecentOrderRow(
                    order: aMap(o),
                    onTap: () => _go('orders'),
                  ),
              ],
            ),
          ),
          AdminCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminKeepColors(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    decoration: const BoxDecoration(gradient: AC.blackGrad),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            attentionTotal > 0 ? '👀 Needs your attention' : '✅ All caught up',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (attentionTotal > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AC.goldGrad,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$attentionTotal',
                              style: const TextStyle(
                                color: Color(0xFF16130C),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final a in attention)
                        _AttentionRow(
                          icon: a[0] as String,
                          label: a[1] as String,
                          count: a[2] as int,
                          onTap: () => _go(a[3] as String, a[4] as Map<String, String>),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ------------------------------------------------ orders
          AdminHeading(
            '🛒 Orders',
            trailing: TextButton(
              onPressed: () => _go('orders'),
              child: const Text('All orders'),
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🏠 IANOVA orders (${aInt(main['count'])})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ),
                    AdminButton(
                      'Manage',
                      small: true,
                      onPressed: () => _go('orders', {'tab': 'main'}),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const AdminMuted('Sold directly by IANOVA'),
                const SizedBox(height: 10),
                if (aList(main['orders']).isEmpty) const AdminMuted('No orders yet.'),
                for (final o in aList(main['orders']))
                  _OrderTile(
                    order: o,
                    onTap: () => _openOrder(aInt(o['id']), 'main'),
                  ),
              ],
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🏪 Seller orders (${aInt(sellersOrders['count'])})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ),
                    AdminButton(
                      'Manage',
                      small: true,
                      onPressed: () => _go('orders', {'tab': 'sellers'}),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const AdminMuted('One section per seller'),
                const SizedBox(height: 10),
                if (groups.isEmpty) const AdminMuted('No seller orders yet.'),
                for (final g in groups) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '🏪 ${aStr(g['name'])} (${aInt(g['orders'])})',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (aInt(g['waiting']) > 0)
                        ATag('${aInt(g['waiting'])} waiting', kind: 'wait')
                      else
                        const ATag('all approved', kind: 'ok'),
                      TextButton(
                        onPressed: () => _go('orders', {
                          'tab': 'sellers',
                          'seller': '${aInt(g['seller_id'])}',
                        }),
                        child: const Text('open'),
                      ),
                    ],
                  ),
                  for (final o in aList(g['recent']))
                    _OrderTile(
                      order: o,
                      onTap: () => _openOrder(aInt(o['id']), 'sellers'),
                    ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          // ------------------------------------------------ products
          AdminHeading(
            '📦 Products',
            trailing: TextButton(
              onPressed: () => _go('products'),
              child: const Text('Manage products'),
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Latest products', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (recent.isEmpty) const AdminMuted('No products yet.'),
                for (final p in recent)
                  _MiniRow(
                    image: aStr(p['image']),
                    emoji: aStr(p['emoji']),
                    bg: aStr(p['bg_color']),
                    title: aStr(p['name']),
                    sub: '${aStr(p['seller'])} · ${_statusLabel(aStr(p['status']))}',
                    right: aMoney(p['price']),
                    right2: 'stock ${aInt(p['stock'])}',
                    onTap: () => _openProduct(aInt(p['id'])),
                  ),
              ],
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ Running low', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (low.isEmpty) const AdminMuted('Nothing is running low. 🎉'),
                for (final p in low)
                  _MiniRow(
                    image: aStr(p['image']),
                    emoji: aStr(p['emoji']),
                    bg: aStr(p['bg_color']),
                    title: aStr(p['name']),
                    tag: aInt(p['stock']) <= 0 ? 'Out of stock' : '${aInt(p['stock'])} left',
                    tagKind: aInt(p['stock']) <= 0 ? 'wait' : 'na',
                    onTap: () => _openProduct(aInt(p['id'])),
                  ),
                if (reviewProducts > 0) ...[
                  const SizedBox(height: 12),
                  AdminButton(
                    '$reviewProducts product${reviewProducts == 1 ? '' : 's'} waiting for review',
                    onPressed: () => _go('products', {'status': 'pending'}),
                  ),
                ],
              ],
            ),
          ),
          // ------------------------------------------------ categories
          AdminHeading(
            '🏷️ Categories',
            trailing: TextButton(
              onPressed: () => _go('categories'),
              child: const Text('Manage categories'),
            ),
          ),
          AdminCard(
            child: cats.isEmpty
                ? const AdminMuted('No categories yet.')
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: [
                      for (final cat in cats)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _go('products', {'category': '${aInt(cat['id'])}'}),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE8EEEA)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  aStr(cat['name']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  '${aInt(cat['n'])} product${aInt(cat['n']) == 1 ? '' : 's'}',
                                  style: const TextStyle(color: AC.muted, fontSize: 12.5),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    minHeight: 7,
                                    value: (aInt(cat['n']) / maxCat).clamp(0.04, 1.0).toDouble(),
                                    backgroundColor: const Color(0xFFE8EEEA),
                                    color: AC.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          // ------------------------------------------------ sellers
          AdminHeading(
            '🏪 Sellers',
            trailing: TextButton(
              onPressed: () => _go('sellers'),
              child: const Text('Manage sellers'),
            ),
          ),
          AdminCard(
            child: Column(
              children: [
                if (sellers.isEmpty) const Align(alignment: Alignment.centerLeft, child: AdminMuted('No sellers yet.')),
                for (final s in sellers)
                  _MiniRow(
                    title: '🏪 ${aStr(s['business_name'])}',
                    sub: '${aInt(s['products'])} product${aInt(s['products']) == 1 ? '' : 's'} · '
                        '${aInt(s['orders'])} order${aInt(s['orders']) == 1 ? '' : 's'}'
                        '${aInt(s['waiting']) > 0 ? ' · ${aInt(s['waiting'])} waiting' : ''}',
                    tag: _cap(aStr(s['status'])),
                    tagKind: aStr(s['status']) == 'approved'
                        ? 'ok'
                        : (aStr(s['status']) == 'pending' ? 'wait' : 'na'),
                    onTap: () => _go('sellers'),
                  ),
              ],
            ),
          ),
          // ------------------------------------------------ users
          AdminHeading(
            '👥 Users',
            trailing: TextButton(
              onPressed: () => _go('users'),
              child: const Text('All users'),
            ),
          ),
          AdminCard(
            child: Column(
              children: [
                if (users.isEmpty) const Align(alignment: Alignment.centerLeft, child: AdminMuted('No users yet.')),
                for (final u in users)
                  _MiniRow(
                    title: aStr(u['name']).isEmpty ? 'User' : aStr(u['name']),
                    sub: aStr(u['email']),
                    onTap: () => _go('users'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  const labels = {
    'approved': 'Approved',
    'pending': 'Review',
    'rejected': 'Rejected',
    'hidden': 'Hidden',
  };

  return labels[status] ?? status;
}

String _cap(String value) {
  return value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onTap});

  final VoidCallback onTap;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final n = DateTime.now();
    final hh = n.hour % 12 == 0 ? 12 : n.hour % 12;
    final mm = n.minute.toString().padLeft(2, '0');
    final ap = n.hour >= 12 ? 'PM' : 'AM';

    return AdminCard(
      color: const Color(0xFFFFF6E3),
      onTap: onTap,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back, Admin!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                SizedBox(height: 2),
                Text("Here's what's happening with your store today.",
                    style: TextStyle(color: AC.muted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.calendar_month_outlined, color: AC.gold, size: 22),
              Text(
                '${_days[n.weekday - 1]}, ${_months[n.month - 1]} ${n.day}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              Text('$hh:$mm $ap', style: const TextStyle(fontSize: 12, color: AC.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.revenue,
    required this.orders,
    required this.products,
    required this.customers,
    required this.trends,
    required this.onGo,
  });

  final String revenue;
  final int orders;
  final int products;
  final int customers;
  final Map<String, dynamic> trends;
  final void Function(String) onGo;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        _Kpi(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Total Revenue',
          value: revenue,
          trend: trends['revenue'],
          bg: const Color(0xFFFFF6E3),
          fg: AC.gold,
          onTap: () => onGo('orders'),
        ),
        _Kpi(
          icon: Icons.shopping_cart_outlined,
          label: 'Total Orders',
          value: '$orders',
          trend: trends['orders'],
          bg: const Color(0xFFEAF3FF),
          fg: const Color(0xFF2F80ED),
          onTap: () => onGo('orders'),
        ),
        _Kpi(
          icon: Icons.inventory_2_outlined,
          label: 'Total Products',
          value: '$products',
          trend: trends['products'],
          bg: const Color(0xFFF3EBFF),
          fg: const Color(0xFF8B3DFF),
          onTap: () => onGo('products'),
        ),
        _Kpi(
          icon: Icons.groups_outlined,
          label: 'Total Customers',
          value: '$customers',
          trend: trends['users'],
          bg: const Color(0xFFE8F7EE),
          fg: const Color(0xFF16A34A),
          onTap: () => onGo('users'),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final dynamic trend;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = trend == null ? null : aNum(trend).toDouble();
    final up = t != null && t >= 0;
    final tText = t == null ? 'no change data' : '${up ? '↑' : '↓'} ${t.abs().toStringAsFixed(t.abs() >= 10 ? 0 : 1)}%';

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AC.ink)),
              ),
              Row(
                children: [
                  Text(
                    tText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: t == null ? AC.muted : (up ? AC.okFg : AC.red),
                    ),
                  ),
                  if (t != null)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Text('vs last 7 days', style: TextStyle(fontSize: 11, color: AC.muted)),
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

class _SalesCard extends StatefulWidget {
  const _SalesCard({required this.sales, required this.onTap});

  final Map<String, dynamic> sales;
  final VoidCallback onTap;

  @override
  State<_SalesCard> createState() => _SalesCardState();
}

class _SalesCardState extends State<_SalesCard> {
  String _range = '7';

  Widget _chip(String key, String text) {
    final on = _range == key;

    return GestureDetector(
      onTap: () => setState(() => _range = key),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: on ? AC.goldGrad : null,
          color: on ? null : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on ? AC.gold : AC.line),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: on ? Colors.white : AC.muted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pts = aList(widget.sales[_range]);
    final vals = [for (final p in pts) aNum(aMap(p)['total']).toDouble()];
    final labels = [
      for (final p in pts)
        () {
          final d = aStr(aMap(p)['d']);
          return d.length >= 10 ? '${d.substring(8, 10)}/${d.substring(5, 7)}' : d;
        }()
    ];

    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Sales Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              _chip('7', '7 Days'),
              _chip('30', '30 Days'),
            ],
          ),
          Text(
            'Revenue trend (last $_range days)',
            style: const TextStyle(color: AC.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: vals.isEmpty
                ? const Center(child: AdminMuted('No sales yet.'))
                : GestureDetector(
                    onTap: widget.onTap,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _TrendPainter(vals, labels),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.vals, this.labels);

  final List<double> vals;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const bottom = 20.0;
    final w = size.width - left - 6;
    final h = size.height - bottom - 6;
    var maxV = 0.0;
    for (final v in vals) {
      if (v > maxV) maxV = v;
    }
    if (maxV <= 0) maxV = 1;
    // nice ceiling
    final step = maxV / 4;
    final grid = Paint()
      ..color = const Color(0xFFE6E9E7)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = 6 + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - 6, y), grid);
      final v = step * i;
      final t = v >= 1000 ? '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K' : v.toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(text: t, style: const TextStyle(fontSize: 10, color: AC.muted)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
    }

    final n = vals.length;
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(left + (n == 1 ? w / 2 : w * i / (n - 1)), 6 + h - h * (vals[i] / maxV)),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, 6 + h)
      ..lineTo(pts.first.dx, 6 + h)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x55E4B43C), Color(0x08E4B43C)],
        ).createShader(Rect.fromLTWH(left, 0, w, h + 6)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AC.gold2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    final dot = Paint()..color = AC.gold2;
    final every = n > 10 ? 5 : 1;
    for (var i = 0; i < n; i++) {
      if (n <= 10 || i == n - 1) canvas.drawCircle(pts[i], 3.6, dot);
      if (i % every == 0 || i == n - 1) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: const TextStyle(fontSize: 10, color: AC.muted)),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (pts[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(x, size.height - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.vals != vals || old.labels != labels;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.sub,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 21),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                    Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AC.muted, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  static (Color, Color) _col(String s) {
    switch (s) {
      case 'paid':
      case 'delivered':
        return (const Color(0xFFE1F3E8), const Color(0xFF166534));
      case 'pending':
        return (const Color(0xFFFFF0CC), const Color(0xFF92600A));
      case 'processing':
      case 'confirmed':
        return (const Color(0xFFE3EEFF), const Color(0xFF1F5FBF));
      case 'shipped':
        return (const Color(0xFFF0E6FF), const Color(0xFF6B2FCC));
      case 'cancelled':
        return (const Color(0xFFFBE4E4), const Color(0xFFB83B3B));
      default:
        return (AC.naBg, AC.naFg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = aStr(order['status']);
    final (bg, fg) = _col(st);
    final d = aStr(order['created_at']);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AC.line))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#IAN-${aInt(order['id']).toString().padLeft(4, '0')}  ${aStr(order['customer'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  Text(
                    d.length >= 10 ? d.substring(0, 10) : d,
                    style: const TextStyle(color: AC.muted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatKsh(aNum(order['total'])), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    st.isEmpty ? '' : st[0].toUpperCase() + st.substring(1),
                    style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: AC.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hot = count > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: hot ? AC.goldTint : AC.soft,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: hot ? AC.gold2 : Colors.transparent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    child: Row(
                      children: [
                        Text(icon),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: hot ? FontWeight.w800 : FontWeight.w500,
                              color: hot ? AC.ink : AC.muted,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 30),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: hot ? AC.goldGrad : null,
                            color: hot ? null : AC.naBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: hot ? const Color(0xFF16130C) : AC.muted,
                            ),
                          ),
                        ),
                      ],
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

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbs = aList(order['thumbs']);
    final approved = order['approved'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.line),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${aInt(order['id'])} · ${aStr(order['customer'])}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    statusTag(aStr(order['status'])),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in thumbs)
                      AdminThumb(
                        image: aStr(t['image']),
                        emoji: aStr(t['emoji']),
                        bg: aStr(t['bg_color']),
                        size: 44,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (approved != null)
                      ATag(approved == true ? 'approved' : 'waiting', kind: approved == true ? 'ok' : 'wait'),
                    const Spacer(),
                    Text(
                      aMoney(order['total']),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Text(
                  aStr(order['created_at']),
                  style: const TextStyle(color: AC.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  const _MiniRow({
    required this.title,
    this.sub,
    this.image,
    this.emoji,
    this.bg,
    this.right,
    this.right2,
    this.tag,
    this.tagKind = 'na',
    required this.onTap,
  });

  final String title;
  final String? sub;
  final String? image;
  final String? emoji;
  final String? bg;
  final String? right;
  final String? right2;
  final String? tag;
  final String tagKind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasThumb = image != null || emoji != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EEEA)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (hasThumb) ...[
                AdminThumb(image: image ?? '', emoji: emoji ?? '', bg: bg ?? '', size: 44),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (sub != null)
                      Text(
                        sub!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AC.muted, fontSize: 12.5),
                      ),
                  ],
                ),
              ),
              if (right != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(right!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                    if (right2 != null)
                      Text(right2!, style: const TextStyle(color: AC.muted, fontSize: 11.5)),
                  ],
                ),
              if (tag != null) ATag(tag!, kind: tagKind),
            ],
          ),
        ),
      ),
    );
  }
}
