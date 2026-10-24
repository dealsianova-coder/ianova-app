import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_orders.dart';
import 'admin_ui.dart';

/// Deposit % + "how customers pay" text, and the orders that still have a balance to collect.
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> with AdminLoad<AdminPaymentsScreen> {
  final TextEditingController _pct = TextEditingController();
  final TextEditingController _how = TextEditingController();
  String _filter = 'part';
  bool _filled = false;
  bool _saving = false;

  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('payments_list', query: {'filter': _filter});

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _pct.dispose();
    _how.dispose();
    super.dispose();
  }

  String _num(dynamic v) {
    final n = aNum(v);

    return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  Future<void> _reload() async {
    await load();

    if (!mounted) return;

    if (!_filled && data != null) {
      _pct.text = _num(data!['deposit_pct']);
      _how.text = aStr(data!['instructions']);
      _filled = true;
      setState(() {});
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('payment_settings_set', body: {'deposit_pct': _pct.text.trim(), 'instructions': _how.text.trim()}),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) adminSay(context, 'Saved. The shop app and the website use this right away.');
  }

  void _pick(String f) {
    if (_filter == f) return;

    setState(() => _filter = f);
    _reload();
  }

  Widget _tag(String state) {
    switch (state) {
      case 'paid':
        return const ATag('Paid in full', kind: 'ok');
      case 'deposit':
        return const ATag('Deposit paid', kind: 'wait');
      case 'part':
        return const ATag('Part paid', kind: 'wait');
      default:
        return const ATag('Not paid', kind: 'na');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_filled && data != null) {
      _pct.text = _num(data!['deposit_pct']);
      _how.text = aStr(data!['instructions']);
      _filled = true;
    }

    return gate((d) {
      final orders = aList(d['orders']);

      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('💳 Payments & deposits', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const AdminMuted('Customers choose at checkout: pay in full, or pay the deposit now and the rest later. You record each payment you receive on the order.'),
            const SizedBox(height: 12),
            AdminCard(
              accent: AC.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminField(
                    label: 'Deposit % (0 = customers pay in full)',
                    controller: _pct,
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  AdminField(
                    label: 'How customers pay',
                    controller: _how,
                    maxLines: 3,
                    maxLength: 400,
                    hint: 'e.g. Send M-Pesa to Till 123456, then we confirm your order.',
                  ),
                  AdminButton('Save', busy: _saving, onPressed: _save),
                ],
              ),
            ),
            AdminChipRow(
              children: [
                AdminChip(label: 'Part paid', selected: _filter == 'part', onTap: () => _pick('part')),
                AdminChip(label: 'Deposit orders', selected: _filter == 'deposit', onTap: () => _pick('deposit')),
                AdminChip(label: 'Not paid yet', selected: _filter == 'unpaid', onTap: () => _pick('unpaid')),
                AdminChip(label: 'All with a balance', selected: _filter == 'all', onTap: () => _pick('all')),
              ],
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Still to collect on these orders', style: TextStyle(color: AC.muted, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(aMoney(d['due']), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AC.warnFg)),
                ],
              ),
            ),
            if (orders.isEmpty) const AdminCard(child: AdminMuted('No orders to show here.')),
            for (final o in orders)
              AdminCard(
                accent: aStr(o['state']) == 'unpaid' ? AC.line2 : AC.goldLight,
                onTap: () async {
                  await adminPush(context, AdminOrderViewPage(id: aInt(o['id'])));

                  if (mounted) _reload();
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #${aInt(o['id'])} · ${aStr(o['customer'])}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          AdminMuted('${aStr(o['created_at'])} · ${aStr(o['status'])}${aStr(o['plan']) == 'deposit' ? ' · deposit ${_num(o['deposit_pct'])}%' : ''}'),
                          AdminMuted('Paid ${aMoney(aNum(o['paid']) - aNum(o['refunded']))} of ${aMoney(o['total'])}'),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _tag(aStr(o['state'])),
                        const SizedBox(height: 4),
                        Text(aMoney(o['balance']), style: const TextStyle(fontWeight: FontWeight.w900, color: AC.warnFg)),
                        const Text('balance', style: TextStyle(color: AC.muted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
