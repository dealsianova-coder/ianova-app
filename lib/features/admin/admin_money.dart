import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

/// One field of a small ask-dialog.
class _F {
  const _F(this.label, {this.text = '', this.keyboard, this.hint});

  final String label;
  final String text;
  final TextInputType? keyboard;
  final String? hint;
}

/// Small dialog with text fields. Returns the values, or null when cancelled.
Future<List<String>?> _ask(BuildContext context, String title, String note, List<_F> fields, {String okLabel = 'Save', Widget? extra}) async {
  final ctrls = [for (final f in fields) TextEditingController(text: f.text)];

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: AdminMuted(note)),
            if (extra != null) extra,
            for (int i = 0; i < fields.length; i++) AdminField(label: fields[i].label, controller: ctrls[i], keyboard: fields[i].keyboard, hint: fields[i].hint),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(okLabel)),
      ],
    ),
  );

  final vals = [for (final c in ctrls) c.text.trim()];

  for (final c in ctrls) {
    c.dispose();
  }

  if (ok != true) return null;

  return vals;
}

const _num = TextInputType.numberWithOptions(decimal: true);

// ===================================================================== COUPONS

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> with AdminLoad<AdminCouponsScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('coupons_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> _edit(Map<String, dynamic>? c) async {
    String kind = c == null ? 'percent' : aStr(c['kind']);
    final extra = StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(
          spacing: 8,
          children: [
            for (final k in const {'percent': 'Percent off', 'fixed': 'Amount off', 'freeship': 'Free delivery'}.entries)
              ChoiceChip(label: Text(k.value), selected: kind == k.key, onSelected: (_) => setS(() => kind = k.key)),
          ],
        ),
      ),
    );

    final v = await _ask(
      context,
      c == null ? 'New coupon' : 'Edit coupon',
      'Percent: value is a percentage. Amount off: value is money. Free delivery ignores the value. Leave a date empty for no limit.',
      [
        _F('Code', text: c == null ? '' : aStr(c['code']), hint: 'WELCOME10'),
        _F('Value (% or amount)', text: c == null ? '10' : aStr(c['value']), keyboard: _num),
        _F('Minimum order', text: c == null ? '0' : aStr(c['min_subtotal']), keyboard: _num),
        _F('Total uses (0 = unlimited)', text: c == null ? '0' : aStr(c['max_uses']), keyboard: TextInputType.number),
        _F('Uses per customer (0 = unlimited)', text: c == null ? '1' : aStr(c['per_user']), keyboard: TextInputType.number),
        _F('Starts (YYYY-MM-DD)', text: c == null ? '' : aStr(c['starts_at']).split(' ').first),
        _F('Ends (YYYY-MM-DD)', text: c == null ? '' : aStr(c['expires_at']).split(' ').first),
        _F('Note for yourself', text: c == null ? '' : aStr(c['note'])),
      ],
      okLabel: c == null ? 'Create' : 'Save',
      extra: extra,
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('coupon_save', body: {
        'id': c == null ? 0 : aInt(c['id']),
        'code': v[0],
        'kind': kind,
        'value': v[1],
        'min_subtotal': v[2],
        'max_uses': v[3],
        'per_user': v[4],
        'starts_at': v[5],
        'expires_at': v[6],
        'note': v[7],
      }),
    );

    if (ok) {
      adminSay(context, c == null ? 'Coupon created.' : 'Coupon saved.');
      load();
    }
  }

  Future<void> _toggle(Map<String, dynamic> c) async {
    final ok = await adminTry(context, () => AdminApi.instance.panel('coupon_toggle', body: {'id': aInt(c['id'])}));

    if (ok) load();
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    if (!await adminConfirm(context, 'Delete coupon ${aStr(c['code'])}? Past orders keep their discount.')) return;

    if (!mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('coupon_delete', body: {'id': aInt(c['id'])}));

    if (ok) load();
  }

  Color _accent(String state) {
    switch (state) {
      case 'live':
        return AC.green;
      case 'scheduled':
        return const Color(0xFF2B6FD6);
      case 'off':
        return AC.gray;
      default:
        return AC.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final rows = aList(d['coupons']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('🎟️ Coupons', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const AdminMuted('Discount codes customers enter at checkout. The store pays for the discount; sellers still earn the full price.'),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerLeft, child: AdminButton('➕ New coupon', small: true, onPressed: () => _edit(null))),
            const SizedBox(height: 12),
            if (rows.isEmpty) const AdminCard(child: AdminMuted('No coupons yet.')),
            for (final c in rows)
              AdminCard(
                accent: _accent(aStr(c['state'])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(aStr(c['code']), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.6))),
                        ATag(aStr(c['state']).toUpperCase(), kind: aStr(c['state']) == 'live' ? 'ok' : (aStr(c['state']) == 'scheduled' ? 'wait' : 'na')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${aStr(c['label'])}${aNum(c['min_subtotal']) > 0 ? ' · min ${aMoney(c['min_subtotal'])}' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    AdminMuted(
                      'Used ${aInt(c['used_count'])}${aInt(c['max_uses']) > 0 ? ' of ${aInt(c['max_uses'])}' : ''} · discount given ${aMoney(c['given'])}'
                      '${aStr(c['expires_at']).isNotEmpty ? ' · ends ${aStr(c['expires_at']).split(' ').first}' : ''}'
                      '${aStr(c['note']).isNotEmpty ? ' · ${aStr(c['note'])}' : ''}',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminButton('Edit', small: true, kind: 'gray', onPressed: () => _edit(c)),
                        AdminButton(aInt(c['active']) == 1 ? 'Turn off' : 'Turn on', small: true, kind: 'gray', onPressed: () => _toggle(c)),
                        AdminButton('Delete', small: true, kind: 'red', onPressed: () => _delete(c)),
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

// ===================================================================== PAYOUTS

class AdminPayoutsScreen extends StatefulWidget {
  const AdminPayoutsScreen({super.key});

  @override
  State<AdminPayoutsScreen> createState() => _AdminPayoutsScreenState();
}

class _AdminPayoutsScreenState extends State<AdminPayoutsScreen> with AdminLoad<AdminPayoutsScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('payouts_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  String _pct(dynamic v) {
    final n = aNum(v);

    return n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toStringAsFixed(2);
  }

  Future<void> _pay(Map<String, dynamic> s) async {
    final v = await _ask(
      context,
      'Pay ${aStr(s['name'])}',
      'Record a payment you already sent (M-Pesa, bank, cash). The seller gets an email. Owed now: ${aMoney(s['balance'])}.',
      [
        _F('Amount paid', text: aNum(s['balance']).toStringAsFixed(2), keyboard: _num),
        const _F('Method', hint: 'M-Pesa, bank'),
        const _F('Reference', hint: 'Transaction code'),
      ],
      okLabel: 'Record payout',
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('payout_add', body: {'seller_id': aInt(s['id']), 'amount': v[0], 'method': v[1], 'reference': v[2]}));

    if (ok) {
      adminSay(context, 'Payout recorded and the seller was emailed.');
      load();
    }
  }

  Future<void> _rate(int sellerId, String name, String current, {bool allowEmpty = true}) async {
    final v = await _ask(
      context,
      sellerId == 0 ? 'Default commission' : 'Commission for $name',
      sellerId == 0 ? 'The store keeps this % of every delivered sale, for all sellers without a custom rate.' : 'Leave empty to use the default commission.',
      [_F('Commission %', text: current, keyboard: _num)],
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('payout_rate', body: {'seller_id': sellerId, 'rate': v[0]}));

    if (ok) load();
  }

  Future<void> _history(Map<String, dynamic> s) async {
    final r = await adminRun(context, () => AdminApi.instance.panel('payout_history', body: {'seller_id': aInt(s['id'])}));

    if (r == null || !mounted) return;

    final rows = aList(r['payouts']);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Payouts to ${aStr(s['name'])}', style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: rows.isEmpty
              ? const AdminMuted('No payouts recorded yet.')
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${aMoney(p['amount'])}  ${aStr(p['method'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            AdminMuted('${aStr(p['reference']).isEmpty ? '' : '${aStr(p['reference'])} · '}${aStr(p['admin_name'])} · ${aStr(p['created_at'])}'),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _figure(String label, dynamic value) {
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

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final sellers = aList(d['sellers']);
      final def = _pct(d['default_rate']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('💸 Seller payouts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const AdminMuted('A seller earns the item price minus commission once an order is delivered. Refunds reduce it. Coupons are paid by the store.'),
            const SizedBox(height: 12),
            AdminCard(
              accent: AC.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _figure('Owed to sellers now', d['owed']),
                      _figure('Paid out so far', d['paid']),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AC.soft, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Default commission', style: TextStyle(color: AC.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('$def%', style: const TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AdminButton('Change default', small: true, kind: 'gray', onPressed: () => _rate(0, '', def)),
                ],
              ),
            ),
            if (sellers.isEmpty) const AdminCard(child: AdminMuted('No sellers yet.')),
            for (final s in sellers)
              AdminCard(
                accent: aNum(s['balance']) > 0.009 ? AC.goldLight : AC.line2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(aStr(s['name']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                              AdminMuted('${aStr(s['email'])} · commission ${_pct(s['rate'])}%${aBool(s['custom_rate']) ? ' (custom)' : ''}'),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Balance owed', style: TextStyle(color: AC.muted, fontSize: 11, fontWeight: FontWeight.w700)),
                            Text(aMoney(s['balance']), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: aNum(s['balance']) > 0.009 ? AC.warnFg : AC.okFg)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _figure('Sold (delivered)', s['gross']),
                        _figure('Refunds', s['refunded']),
                        _figure('Commission', s['commission']),
                        _figure('Earned', s['earned']),
                        _figure('Paid', s['paid']),
                        _figure('Coming (not delivered)', s['coming']),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (aNum(s['balance']) > 0.009) AdminButton('💸 Record payout', small: true, onPressed: () => _pay(s)),
                        AdminButton('Commission', small: true, kind: 'gray', onPressed: () => _rate(aInt(s['id']), aStr(s['name']), aBool(s['custom_rate']) ? _pct(s['rate']) : '')),
                        AdminButton('History', small: true, kind: 'gray', onPressed: () => _history(s)),
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
