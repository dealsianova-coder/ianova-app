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

    final tiles = <List<String>>[
      ['🛒', 'Orders', '${aInt(c['orders'])}', pendingOrders > 0 ? '$pendingOrders pending' : '', 'orders'],
      ['📦', 'Products', '${aInt(c['products'])}', reviewProducts > 0 ? '$reviewProducts to review' : '', 'products'],
      ['🏷️', 'Categories', '${aInt(c['categories'])}', '', 'categories'],
      ['🏪', 'Sellers', '${aInt(c['sellers'])}', pendingSellers > 0 ? '$pendingSellers to approve' : '', 'sellers'],
      ['👥', 'Users', '${aInt(c['users'])}', '', 'users'],
    ];

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

    tiles.add(['🔔', 'Needs attention', '$attentionTotal', attentionTotal > 0 ? 'open orders' : 'all clear', 'orders']);

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
          _Hero(
            revenue: formatKsh(aNum(c['revenue'])),
            orders: aInt(c['orders']),
            pending: pendingOrders,
            attention: attentionTotal,
            onTap: () => _go('orders'),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              for (final t in tiles)
                _Tile(
                  icon: t[0],
                  label: t[1],
                  value: t[2],
                  sub: t[3],
                  onTap: () => _go(t[4]),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminButton(
                '+ Add product',
                onPressed: () async {
                  await adminPush(context, const AdminProductEditPage());
                  _load();
                },
              ),
              AdminButton('+ Category', kind: 'gray', onPressed: () => _go('categories')),
              AdminButton('⚡ Flash deals', kind: 'gray', onPressed: () => _go('flash')),
              AdminButton('🖼️ Banners', kind: 'gray', onPressed: () => _go('banners')),
              AdminButton('⚙️ Settings', kind: 'gray', onPressed: () => _go('settings')),
            ],
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.revenue,
    required this.orders,
    required this.pending,
    required this.attention,
    required this.onTap,
  });

  final String revenue;
  final int orders;
  final int pending;
  final int attention;
  final VoidCallback onTap;

  Widget _pill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AC.gold2.withValues(alpha: 0.45)),
        ),
        child: Text(
          t,
          style: const TextStyle(color: Color(0xFFF6E3A6), fontSize: 12, fontWeight: FontWeight.w800),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AdminKeepColors(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: AC.blackGrad,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, decoration: const BoxDecoration(gradient: AC.goldGrad)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 CONFIRMED REVENUE',
                        style: TextStyle(
                          color: Color(0xFFD9B45A),
                          fontSize: 12,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ShaderMask(
                          shaderCallback: (r) => AC.goldGrad.createShader(r),
                          child: Text(
                            revenue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill('🛒 $orders orders'),
                          _pill('⏳ $pending pending'),
                          _pill(attention > 0 ? '👀 $attention to check' : '✅ all clear'),
                        ],
                      ),
                    ],
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  final String icon;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 3, decoration: const BoxDecoration(gradient: AC.goldGrad)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AC.goldTint, shape: BoxShape.circle),
                        child: Text(icon, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AC.muted, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AC.ink),
                    ),
                  ),
                  if (sub.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AC.goldGrad,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        sub,
                        style: const TextStyle(
                          color: Color(0xFF16130C),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
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
