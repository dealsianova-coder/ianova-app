import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import 'admin_api.dart';
import 'admin_order_item.dart';
import 'admin_products.dart';
import 'admin_ui.dart';

const List<String> _statuses = [
  'pending',
  'approved',
  'paid',
  'shipped',
  'delivered',
  'cancelled',
];

Map<String, String> get _statusOptions => {
      for (final s in _statuses) s: '${s[0].toUpperCase()}${s.substring(1)}',
    };

/// Orders: IANOVA orders and seller orders in separate sections, like the website.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({
    super.key,
    this.initialTab = 'main',
    this.initialStatus = '',
    this.initialSeller = 0,
  });

  final String initialTab;
  final String initialStatus;
  final int initialSeller;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _search = TextEditingController();

  late String _tab;
  late String _status;
  late int _seller;
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab == 'sellers' ? 'sellers' : 'main';
    _status = widget.initialStatus;
    _seller = _tab == 'sellers' ? widget.initialSeller : 0;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.panel(
        'orders_list',
        query: {
          'tab': _tab,
          'status': _status,
          'seller': '$_seller',
          'q': _search.text.trim(),
        },
      );

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

  void _reload({String? tab, String? status, int? seller}) {
    setState(() {
      if (tab != null) {
        _tab = tab;
        _seller = 0;
      }
      if (status != null) _status = status;
      if (seller != null) _seller = seller;
      _loading = true;
    });
    _load();
  }

  Future<void> _setStatus(int id, String status) async {
    final ok = await adminTry(
      context,
      () => AdminApi.instance.setOrderStatus(id, status),
    );

    if (!mounted) return;

    if (ok) adminSay(context, 'Order #$id is now $status.');
    _load();
  }

  Future<void> _open(int id) async {
    await adminPush(context, AdminOrderViewPage(id: id, tab: _tab));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    if (_loading && data == null) return const AdminLoading();
    if (data == null) return AdminLoading(error: _error, onRetry: _load);

    final statusCounts = aMap(data['status_counts']);
    var total = 0;
    for (final s in _statuses) {
      total += aInt(statusCounts[s]);
    }

    final chips = aList(data['seller_chips']);
    final orders = aList(data['orders']);
    final List<Widget> rows = _tab == 'main'
        ? <Widget>[
            for (final o in orders)
              AdminCard(
                child: _OrderBlock(
                  order: o,
                  lines: aList(o['lines']),
                  approvals: const <Map<String, dynamic>>[],
                  itemsLabel: 'IANOVA items',
                  onOpen: () => _open(aInt(o['id'])),
                  onStatus: (s) => _setStatus(aInt(o['id']), s),
                ),
              ),
          ]
        : _sellerGroups(orders);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminChipRow(
            children: [
              AdminChip(
                label: '🏠 IANOVA orders',
                count: aInt(data['n_main']),
                selected: _tab == 'main',
                onTap: () => _reload(tab: 'main'),
              ),
              AdminChip(
                label: '🏪 Seller orders',
                count: aInt(data['n_sellers']),
                selected: _tab == 'sellers',
                onTap: () => _reload(tab: 'sellers'),
              ),
            ],
          ),
          AdminMuted(
            _tab == 'main'
                ? 'Orders with products sold directly by IANOVA. You manage these yourself.'
                : 'Orders with products sold by sellers. Each seller approves their own items; you see their status here.',
          ),
          const SizedBox(height: 10),
          if (_tab == 'sellers')
            AdminChipRow(
              children: [
                AdminChip(
                  label: 'All sellers',
                  count: chips.length,
                  selected: _seller == 0,
                  onTap: () => _reload(seller: 0),
                ),
                for (final s in chips)
                  AdminChip(
                    label: aInt(s['waiting']) > 0
                        ? '🏪 ${aStr(s['name'])} · ${aInt(s['waiting'])} waiting'
                        : '🏪 ${aStr(s['name'])}',
                    count: aInt(s['orders']),
                    selected: _seller == aInt(s['id']),
                    onTap: () => _reload(seller: aInt(s['id'])),
                  ),
              ],
            ),
          AdminChipRow(
            children: [
              AdminChip(
                label: 'All',
                count: total,
                selected: _status.isEmpty,
                onTap: () => _reload(status: ''),
              ),
              for (final s in _statuses)
                AdminChip(
                  label: '${s[0].toUpperCase()}${s.substring(1)}',
                  count: aInt(statusCounts[s]),
                  selected: _status == s,
                  onTap: () => _reload(status: s),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _reload(),
                  decoration: AdminField.decoration('Search order #, customer, phone, email...'),
                ),
              ),
              const SizedBox(width: 8),
              AdminButton('Search', onPressed: () => _reload()),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            const AdminCard(child: AdminMuted('No orders in this section.')),
          ...rows,
          if (_loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  List<Widget> _sellerGroups(List<Map<String, dynamic>> orders) {
    final groups = <int, Map<String, dynamic>>{};

    for (final o in orders) {
      final bySeller = <int, List<Map<String, dynamic>>>{};

      for (final l in aList(o['lines'])) {
        final sid = aInt(l['seller_id']);
        if (sid > 0) bySeller.putIfAbsent(sid, () => <Map<String, dynamic>>[]).add(l);
      }

      for (final entry in bySeller.entries) {
        final g = groups.putIfAbsent(
          entry.key,
          () => <String, dynamic>{
            'name': aStr(entry.value.first['seller_name']),
            'rows': <Map<String, dynamic>>[],
          },
        );

        (g['rows'] as List<Map<String, dynamic>>).add({
          'order': o,
          'lines': entry.value,
          'seller_id': entry.key,
        });
      }
    }

    final keys = groups.keys.toList()
      ..sort((a, b) => aStr(groups[a]!['name'])
          .toLowerCase()
          .compareTo(aStr(groups[b]!['name']).toLowerCase()));

    final widgets = <Widget>[];

    for (final sid in keys) {
      final g = groups[sid]!;
      final rows = g['rows'] as List<Map<String, dynamic>>;
      var waiting = 0;

      for (final r in rows) {
        for (final a in aList(aMap(r['order'])['approvals'])) {
          if (aInt(a['seller_id']) == sid && !aBool(a['approved'])) waiting++;
        }
      }

      widgets.add(
        AdminCard(
          accent: AC.gold,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🏪 ${aStr(g['name'])} (${rows.length} order${rows.length == 1 ? '' : 's'})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (waiting > 0)
                    ATag('$waiting waiting for this seller', kind: 'wait')
                  else
                    const ATag('All approved', kind: 'ok'),
                  const Spacer(),
                  if (_seller != sid)
                    AdminButton(
                      'Only this seller',
                      kind: 'gray',
                      small: true,
                      onPressed: () => _reload(seller: sid),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (final r in rows) ...[
                const Divider(height: 22),
                _OrderBlock(
                  order: aMap(r['order']),
                  lines: aList(r['lines']),
                  approvals: aList(aMap(r['order'])['approvals'])
                      .where((a) => aInt(a['seller_id']) == sid)
                      .toList(),
                  itemsLabel: 'Their items',
                  onOpen: () => _open(aInt(aMap(r['order'])['id'])),
                  onStatus: (s) => _setStatus(aInt(aMap(r['order'])['id']), s),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return widgets;
  }
}

class _OrderBlock extends StatelessWidget {
  const _OrderBlock({
    required this.order,
    required this.lines,
    required this.approvals,
    required this.itemsLabel,
    required this.onOpen,
    required this.onStatus,
  });

  final Map<String, dynamic> order;
  final List<Map<String, dynamic>> lines;
  final List<Map<String, dynamic>> approvals;
  final String itemsLabel;
  final VoidCallback onOpen;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) {
    var itemsTotal = 0.0;
    for (final l in lines) {
      itemsTotal += aNum(l['unit_price']) * aInt(l['quantity']);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onOpen,
                child: Text(
                  '#${aInt(order['id'])}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AC.green,
                  ),
                ),
              ),
            ),
            statusTag(aStr(order['status'])),
          ],
        ),
        Text(
          aStr(order['created_at']),
          style: const TextStyle(color: AC.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        for (final l in lines.take(3))
          AdminLineRow(
            line: l,
            showSeller: false,
            onTap: onOpen,
          ),
        if (lines.length > 3)
          TextButton(
            onPressed: onOpen,
            child: Text('+${lines.length - 3} more items'),
          ),
        const SizedBox(height: 6),
        Text(aStr(order['customer']), style: const TextStyle(fontWeight: FontWeight.w900)),
        if (aStr(order['phone']).isNotEmpty || aStr(order['address']).isNotEmpty)
          Text(
            '${aStr(order['phone'])}\n${aStr(order['address'])}'.trim(),
            style: const TextStyle(color: AC.muted, fontSize: 13),
          ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('$itemsLabel: ', style: const TextStyle(color: AC.muted, fontSize: 13)),
            Text(formatKsh(itemsTotal), style: const TextStyle(fontWeight: FontWeight.w900)),
            const Spacer(),
            Text(
              'Order total ${aMoney(order['total'])}',
              style: const TextStyle(color: AC.muted, fontSize: 12.5),
            ),
          ],
        ),
        if (approvals.isNotEmpty)
          Wrap(
            children: [
              for (final a in approvals)
                ATag(
                  '${aStr(a['name'])} · ${aBool(a['approved']) ? 'approved' : 'waiting'}',
                  kind: aBool(a['approved']) ? 'ok' : 'wait',
                ),
            ],
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatusSelect(
                value: aStr(order['status']),
                onChanged: onStatus,
              ),
            ),
            const SizedBox(width: 8),
            AdminButton('Open', kind: 'gray', onPressed: onOpen),
          ],
        ),
      ],
    );
  }
}

class _StatusSelect extends StatelessWidget {
  const _StatusSelect({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = _statusOptions;

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: value == 'cancelled'
          ? null
          : () async {
        final picked = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Change order status', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
                for (final e in options.entries)
                  ListTile(
                    title: Text(e.value),
                    trailing: e.key == value ? const Icon(Icons.check_rounded, color: AC.green) : null,
                    onTap: () => Navigator.of(ctx).pop(e.key),
                  ),
              ],
            ),
          ),
        );

        if (picked != null && picked != value) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AC.line2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(value == 'cancelled' ? '🔒 Cancelled · locked' : 'Status: ${options[value] ?? value}')),
            const Icon(Icons.expand_more_rounded, color: AC.muted),
          ],
        ),
      ),
    );
  }
}

/// One order: customer, delivery, one panel for IANOVA and one per seller.
class AdminOrderViewPage extends StatefulWidget {
  const AdminOrderViewPage({super.key, required this.id, this.tab = 'main'});

  final int id;
  final String tab;

  @override
  State<AdminOrderViewPage> createState() => _AdminOrderViewPageState();
}

class _AdminOrderViewPageState extends State<AdminOrderViewPage> {
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
      final data = await AdminApi.instance.panel(
        'order_view',
        query: {'id': '${widget.id}'},
      );

      if (!mounted) return;

      if (!_trackFilled) {
        final t = aMap(data['tracking']);

        _courier.text = aStr(t['courier']);
        _trackNo.text = aStr(t['number']);
        _trackNote.text = aStr(t['note']);
        _trackFilled = true;
      }

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

  Future<void> _setStatus(String status) async {
    final ok = await adminTry(
      context,
      () => AdminApi.instance.setOrderStatus(widget.id, status),
    );

    if (!mounted) return;

    if (ok) adminSay(context, 'Status updated.');
    _load();
  }

  final TextEditingController _note = TextEditingController();
  final TextEditingController _courier = TextEditingController();
  final TextEditingController _trackNo = TextEditingController();
  final TextEditingController _trackNote = TextEditingController();
  bool _trackFilled = false;

  @override
  void dispose() {
    _note.dispose();
    _courier.dispose();
    _trackNo.dispose();
    _trackNote.dispose();
    super.dispose();
  }

  Future<void> _saveTracking() async {
    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('order_tracking_save', body: {'id': widget.id, 'courier': _courier.text.trim(), 'number': _trackNo.text.trim(), 'note': _trackNote.text.trim()}),
    );

    if (!mounted) return;

    if (ok) {
      adminSay(context, 'Saved. The customer was emailed.');
      _load();
    }
  }

  Future<void> _recordPayment(double balance, double suggested) async {
    final amount = TextEditingController(text: suggested.toStringAsFixed(2));
    final method = TextEditingController();
    final reference = TextEditingController();

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Record payment', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminMuted('Record money you received (M-Pesa, cash, bank). The customer gets an email. Balance now: ${aMoney(balance)}.'),
              const SizedBox(height: 12),
              AdminField(label: 'Amount received', controller: amount, keyboard: const TextInputType.numberWithOptions(decimal: true)),
              AdminField(label: 'Method (M-Pesa, cash, bank)', controller: method),
              AdminField(label: 'Transaction code', controller: reference),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Record payment')),
        ],
      ),
    );

    final body = {'id': widget.id, 'amount': amount.text.trim(), 'method': method.text.trim(), 'reference': reference.text.trim()};

    amount.dispose();
    method.dispose();
    reference.dispose();

    if (go != true || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('order_payment_add', body: body));

    if (!mounted) return;

    if (ok) {
      adminSay(context, 'Payment recorded and the customer was emailed.');
      _load();
    }
  }

  Widget _paymentsCard(Map<String, dynamic> data, Map<String, dynamic> o) {
    final pay = aMap(data['pay']);

    if (pay.isEmpty) return const SizedBox.shrink();

    final state = aStr(pay['pay_state']);
    final balance = aNum(pay['balance']);
    final depositLeft = aNum(pay['deposit_left']);
    final isDeposit = aStr(pay['pay_plan']) == 'deposit';
    final pct = aNum(pay['deposit_pct']);
    final pctText = pct == pct.roundToDouble() ? pct.toStringAsFixed(0) : pct.toStringAsFixed(2);

    final String tagText;
    final String tagKind;

    switch (state) {
      case 'paid':
        tagText = 'Paid in full';
        tagKind = 'ok';
        break;
      case 'deposit':
        tagText = 'Deposit paid';
        tagKind = 'wait';
        break;
      case 'part':
        tagText = 'Part paid';
        tagKind = 'wait';
        break;
      case 'cancelled':
        tagText = 'Cancelled';
        tagKind = 'na';
        break;
      default:
        tagText = 'Not paid';
        tagKind = 'na';
    }

    return AdminCard(
      accent: state == 'paid' ? AC.green : AC.goldLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('💳 Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              ATag(tagText, kind: tagKind),
            ],
          ),
          const SizedBox(height: 8),
          AdminMuted(isDeposit ? 'The customer chose to pay a $pctText% deposit now and the rest later.' : 'The customer chose to pay in full.'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _payFigure('Order total', aNum(o['total'])),
              if (isDeposit) _payFigure('Deposit', aNum(pay['deposit_due'])),
              _payFigure('Paid', aNum(pay['paid'])),
              _payFigure('Balance', balance),
            ],
          ),
          const SizedBox(height: 10),
          for (final p in aList(pay['list']))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${aMoney(p['amount'])}  ${aStr(p['method'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        AdminMuted('${aStr(p['reference']).isEmpty ? '' : '${aStr(p['reference'])} · '}${aStr(p['admin_name'])} · ${aStr(p['created_at'])}'),
                      ],
                    ),
                  ),
                  TextButton(onPressed: () => _removePayment(aInt(p['id'])), child: const Text('Remove')),
                ],
              ),
            ),
          if (state != 'cancelled' && balance > 0.009)
            AdminButton('Record payment', small: true, onPressed: () => _recordPayment(balance, depositLeft > 0.009 ? depositLeft : balance)),
        ],
      ),
    );
  }

  Widget _payFigure(String label, double value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AC.soft, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: AC.muted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(aMoney(value), style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Future<void> _removePayment(int paymentId) async {
    final go = await adminConfirm(context, 'Remove this payment? Only do this if it was entered by mistake.');

    if (!go || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('order_payment_delete', body: {'payment_id': paymentId}));

    if (!mounted) return;

    if (ok) _load();
  }

  Future<void> _refund(double left) async {
    final amount = TextEditingController();
    final method = TextEditingController();
    final reason = TextEditingController();

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Record refund', style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminMuted('Records a refund you paid out yourself and emails the customer. Up to ${aMoney(left)} left.'),
              const SizedBox(height: 12),
              AdminField(label: 'Amount', controller: amount, keyboard: const TextInputType.numberWithOptions(decimal: true)),
              AdminField(label: 'Method (M-Pesa, bank, cash)', controller: method),
              AdminField(label: 'Reason', controller: reason),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Record refund')),
        ],
      ),
    );

    final body = {'id': widget.id, 'amount': amount.text.trim(), 'method': method.text.trim(), 'reason': reason.text.trim()};

    amount.dispose();
    method.dispose();
    reason.dispose();

    if (go != true || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('order_refund_add', body: body));

    if (!mounted) return;

    if (ok) {
      adminSay(context, 'Refund recorded.');
      _load();
    }
  }

  Future<void> _addNote() async {
    final text = _note.text.trim();

    if (text.isEmpty) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('order_note_add', body: {'id': widget.id, 'note': text}),
    );

    if (!mounted) return;

    if (ok) {
      _note.clear();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    Widget body;

    if (_loading) {
      body = const AdminLoading();
    } else if (data == null) {
      body = AdminLoading(error: _error, onRetry: _load);
    } else {
      final o = aMap(data['order']);
      final groups = aList(data['groups']);
      final delivery = aNum(data['delivery']);

      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Order #${aInt(o['id'])} ',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      statusTag(aStr(o['status'])),
                    ],
                  ),
                  AdminMuted(aStr(o['created_at'])),
                  const SizedBox(height: 12),
                  _StatusSelect(value: aStr(o['status']), onChanged: _setStatus),
                  const SizedBox(height: 14),
                  const Text('Customer', style: TextStyle(fontWeight: FontWeight.w900)),
                  Text(aStr(o['customer'])),
                  AdminMuted(aStr(o['email'])),
                  const SizedBox(height: 10),
                  const Text('Delivery', style: TextStyle(fontWeight: FontWeight.w900)),
                  Text(aStr(o['phone'])),
                  AdminMuted(aStr(o['address'])),
                ],
              ),
            ),
            for (final g in groups)
              AdminCard(
                accent: aBool(g['is_main']) ? AC.green : AC.gold,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${aBool(g['is_main']) ? '🏠' : '🏪'} ${aStr(g['name'])}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (aBool(g['is_main']))
                          const ATag('Managed by you')
                        else
                          ATag(
                            aBool(g['approved']) ? 'approved' : 'waiting',
                            kind: aBool(g['approved']) ? 'ok' : 'wait',
                          ),
                        const Spacer(),
                        Text(aMoney(g['total']), style: const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const Divider(height: 18),
                    for (final l in aList(g['lines']))
                      AdminLineRow(
                        line: l,
                        size: 56,
                        onTap: () => adminPush(context, AdminOrderItemPage(order: o, group: g, line: l)),
                      ),
                  ],
                ),
              ),
            if (groups.isEmpty) const AdminCard(child: AdminMuted('This order has no items.')),
            _paymentsCard(data, o),
            AdminCard(
              accent: const Color(0xFF17A2A2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚚 Delivery tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  AdminField(label: 'Courier', controller: _courier),
                  AdminField(label: 'Tracking number', controller: _trackNo),
                  AdminField(label: 'Note (optional)', controller: _trackNote),
                  AdminButton('Save and email customer', small: true, onPressed: _saveTracking),
                ],
              ),
            ),
            AdminCard(
              accent: AC.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('↩️ Refunds${aNum(data['refunded']) > 0 ? ' (${aMoney(data['refunded'])})' : ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  for (final r in aList(data['refunds']))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${aMoney(r['amount'])} ${aStr(r['method'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          AdminMuted('${aStr(r['reason'])} · ${aStr(r['admin_name'])} · ${aStr(r['created_at'])}'),
                        ],
                      ),
                    ),
                  if (aStr(o['status']) != 'pending' || aNum(aMap(data['pay'])['paid']) > 0) AdminButton('Record refund', small: true, kind: 'red', onPressed: () => _refund(aNum(o['total']) - aNum(data['refunded']))),
                  if (aStr(o['status']) == 'pending' && aNum(aMap(data['pay'])['paid']) <= 0) const AdminMuted('Nothing was paid yet: this order is still pending.'),
                ],
              ),
            ),
            AdminCard(
              accent: const Color(0xFF7C6FD0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📝 Internal notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const AdminMuted('Only admins see these. Customers and sellers do not.'),
                  const SizedBox(height: 10),
                  for (final n in aList(data['notes']))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(aStr(n['note'])),
                          AdminMuted('${aStr(n['admin_name'])} · ${aStr(n['created_at'])}'),
                        ],
                      ),
                    ),
                  TextField(
                    controller: _note,
                    minLines: 1,
                    maxLines: 4,
                    decoration: AdminField.decoration('Add a note (e.g. called the customer)'),
                  ),
                  const SizedBox(height: 8),
                  AdminButton('Add note', small: true, onPressed: _addNote),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const AdminMuted('Items'),
                      const Spacer(),
                      Text(aMoney(data['subtotal'])),
                    ],
                  ),
                  if (delivery.abs() > 0.004) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const AdminMuted('Delivery / other'),
                        const Spacer(),
                        Text(formatKsh(delivery)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                      const Spacer(),
                      Text(aMoney(o['total']), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AdminSubPage(
      title: widget.tab == 'sellers' ? 'Seller order' : 'IANOVA order',
      child: body,
    );
  }
}
