import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import 'admin_api.dart';
import 'admin_dashboard.dart' show AdminGo;
import 'admin_ui.dart';

/// Revenue breakdown (where it came from), start revenue over (30 days to restore) and delete test orders (recycle bin).
class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key, required this.onGo});

  final AdminGo onGo;

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> with AdminLoad<AdminRevenueScreen> {
  String _range = '30';

  @override
  Future<Map<String, dynamic>> fetch() {
    final to = DateTime.now();
    final days = _range == '7' ? 6 : 29;
    String d(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

    return AdminApi.instance.panel('revenue_report', query: {'from': d(to.subtract(Duration(days: days))), 'to': d(to)});
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<List<String>?> _ask(String title, String note, List<String> labels, {List<bool> secret = const []}) async {
    final ctrls = [for (final _ in labels) TextEditingController()];

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
              for (int i = 0; i < labels.length; i++)
                AdminField(label: labels[i], controller: ctrls[i], obscure: i < secret.length ? secret[i] : true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
        ],
      ),
    );

    final vals = [for (final c in ctrls) c.text.trim()];

    for (final c in ctrls) {
      c.dispose();
    }

    return ok == true ? vals : null;
  }

  Future<void> _reset() async {
    final v = await _ask(
      'Start revenue over',
      'Revenue goes back to zero from now. Your orders are not touched. The old figures are archived and can be restored for 30 days, then permanently deleted.',
      ['Note (optional)', 'Type RESET', '🔒 Security password'],
      secret: [false, false, true],
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('revenue_reset_do', body: {'label': v[0], 'confirm': v[1], 'security_password': v[2]}),
    );

    if (ok && mounted) {
      adminSay(context, 'Revenue started over. Old figures are kept for 30 days.');
      load();
    }
  }

  Future<void> _restore(int id) async {
    final v = await _ask('Restore old revenue', 'Brings the archived revenue back.', ['🔒 Security password']);

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('revenue_restore_do', body: {'id': id, 'security_password': v[0]}));

    if (ok && mounted) {
      adminSay(context, 'Revenue restored.');
      load();
    }
  }

  Future<void> _trash(int count) async {
    final v = await _ask(
      'Delete test orders',
      'Moves all $count orders (with their items, payments and refunds) to a recycle bin for 30 days, then they are permanently deleted. Customers, products and sellers are not touched.',
      ['Type DELETE', '🔒 Security password'],
      secret: [false, true],
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('revenue_trash_do', body: {'confirm': v[0], 'security_password': v[1]}));

    if (ok && mounted) {
      adminSay(context, 'Orders moved to the recycle bin for 30 days.');
      load();
    }
  }

  Future<void> _trashRestore(int id) async {
    final v = await _ask('Restore orders', 'Brings these orders back exactly as they were.', ['🔒 Security password']);

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('revenue_trash_restore_do', body: {'id': id, 'security_password': v[0]}));

    if (ok && mounted) {
      adminSay(context, 'Orders restored.');
      load();
    }
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: AC.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w500))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _bar(double part, double whole) {
    final f = whole <= 0 ? 0.0 : (part / whole).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 8, color: AC.naBg),
          FractionallySizedBox(
            widthFactor: f,
            child: Container(height: 8, decoration: const BoxDecoration(gradient: AC.goldGrad)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String sub, Color bg, Color fg, IconData icon, {Color? subColor}) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AC.ink)),
            ),
            Text(sub, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: subColor ?? AC.muted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final r = aMap(d['report']);
      final src = aMap(r['sources']);
      final master = aBool(d['master']);
      final resets = aList(d['resets']);
      final trash = aList(d['trash']);
      final ordersNow = aMap(d['orders_now']);
      final direct = aNum(src['direct']).toDouble();
      final sg = aNum(src['sellers_gross']).toDouble();
      final total = direct + sg;
      final since = aStr(r['since']);
      final daily = aList(r['daily']);
      final vals = [for (final p in daily) aNum(aMap(p)['total']).toDouble()];
      final labels = [
        for (final p in daily)
          () {
            final x = aStr(aMap(p)['d']);
            return x.length >= 10 ? '${x.substring(8, 10)}/${x.substring(5, 7)}' : x;
          }()
      ];

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminCard(
              color: const Color(0xFFFFF6E3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💰 Revenue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(
                    since.isEmpty
                        ? 'Where your money came from.'
                        : 'Counting from ${since.length >= 16 ? since.substring(0, 16) : since} (revenue was started over).',
                    style: const TextStyle(color: AC.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final e in const [['7', 'Last 7 days'], ['30', 'Last 30 days']])
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 12),
                    child: ChoiceChip(
                      label: Text(e[1]),
                      selected: _range == e[0],
                      onSelected: (_) {
                        setState(() => _range = e[0]);
                        load();
                      },
                    ),
                  ),
              ],
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                _stat('Confirmed revenue', formatKsh(aNum(r['confirmed'])), '${aInt(r['orders'])} orders', const Color(0xFFFFF6E3), AC.gold, Icons.account_balance_wallet_outlined),
                _stat('Net after refunds', formatKsh(aNum(r['net'])), '− ${formatKsh(aNum(r['refunded']))} refunded', const Color(0xFFE8F7EE), const Color(0xFF16A34A), Icons.verified_outlined, subColor: AC.red),
                _stat('Pending (not counted yet)', formatKsh(aNum(r['pending'])), '${aInt(r['pending_n'])} orders', const Color(0xFFEAF3FF), const Color(0xFF2F80ED), Icons.hourglass_bottom),
                _stat('Cancelled', formatKsh(aNum(r['cancelled'])), '${aInt(r['cancelled_n'])} orders', const Color(0xFFF3EBFF), const Color(0xFF8B3DFF), Icons.block),
              ],
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Revenue by day', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 170,
                    child: vals.isEmpty ? const Center(child: AdminMuted('No sales yet.')) : CustomPaint(size: Size.infinite, painter: _RevPainter(vals, labels)),
                  ),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Where it came from', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const AdminMuted('Product sales in confirmed orders'),
                  const SizedBox(height: 8),
                  _row('🏠 IANOVA direct', formatKsh(direct), bold: true),
                  _bar(direct, total),
                  _row('🏪 Sellers (total sales)', formatKsh(sg), bold: true),
                  _bar(sg, total),
                  _row('💼 Your commission from sellers', formatKsh(aNum(src['commission'])), color: AC.gold),
                  for (final s in aList(src['sellers']))
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: _row(
                        '${aStr(aMap(s)['name'])} (${aNum(aMap(s)['rate'])}%)',
                        '${formatKsh(aNum(aMap(s)['gross']))} · you keep ${formatKsh(aNum(aMap(s)['commission']))}',
                      ),
                    ),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How customers paid', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const AdminMuted('Payments recorded on these orders'),
                  const SizedBox(height: 6),
                  for (final m in aList(r['methods']))
                    _row(aStr(aMap(m)['method']).isEmpty ? 'Other' : aStr(aMap(m)['method']), formatKsh(aNum(aMap(m)['amount']))),
                  _row('No payment recorded (e.g. pay on delivery)', formatKsh(aNum(r['unrecorded']))),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Top products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  if (aList(r['products']).isEmpty) const AdminMuted('No sales in this period.'),
                  for (final p in aList(r['products']))
                    _row('${aStr(aMap(p)['name'])} × ${aInt(aMap(p)['qty'])}', formatKsh(aNum(aMap(p)['amount']))),
                  const SizedBox(height: 10),
                  const Text('Top categories', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  if (aList(r['categories']).isEmpty) const AdminMuted('No sales in this period.'),
                  for (final c in aList(r['categories'])) _row(aStr(aMap(c)['name']), formatKsh(aNum(aMap(c)['amount']))),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: () => widget.onGo('orders', <String, String>{}), child: const Text('See all orders ›')),
            ),
            if (master) ...[
              AdminCard(
                color: const Color(0xFFFFF7F7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🔄 Start revenue over', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    const AdminMuted('Revenue goes back to zero from now. Orders are not touched. Old figures are archived for 30 days and can be restored, then permanently deleted.'),
                    const SizedBox(height: 10),
                    AdminButton('Start over', kind: 'red', onPressed: _reset),
                    for (final x in resets)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🗂️ ${aStr(aMap(x)['reset_at']).length >= 16 ? aStr(aMap(x)['reset_at']).substring(0, 16) : aStr(aMap(x)['reset_at'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  AdminMuted(
                                    aMap(x)['confirmed'] == null
                                        ? (aMap(x)['restored_at'] != null ? 'Restored' : 'Permanently deleted')
                                        : 'Archived ${formatKsh(aNum(aMap(x)['confirmed']))} from ${aInt(aMap(x)['orders'])} orders · ${aInt(aMap(x)['days_left'])} days left',
                                  ),
                                ],
                              ),
                            ),
                            if (aBool(aMap(x)['can_restore'])) AdminButton('Restore', kind: 'gray', small: true, onPressed: () => _restore(aInt(aMap(x)['id']))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              AdminCard(
                color: const Color(0xFFFFF7F7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🗑️ Delete test orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    AdminMuted('Moves all ${aInt(ordersNow['n'])} orders (${formatKsh(aNum(ordersNow['total']))}) to a recycle bin for 30 days, then they are permanently deleted. Customers, products and sellers are not touched.'),
                    const SizedBox(height: 10),
                    AdminButton('Delete all orders', kind: 'red', onPressed: aInt(ordersNow['n']) == 0 ? null : () => _trash(aInt(ordersNow['n']))),
                    for (final x in trash)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('🗑️ ${aInt(aMap(x)['n'])} orders · ${formatKsh(aNum(aMap(x)['total']))}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  AdminMuted(
                                    aBool(aMap(x)['can_restore'])
                                        ? '${aInt(aMap(x)['days_left'])} days left to restore'
                                        : (aMap(x)['restored_at'] != null ? 'Restored' : 'Permanently deleted'),
                                  ),
                                ],
                              ),
                            ),
                            if (aBool(aMap(x)['can_restore'])) AdminButton('Restore', kind: 'gray', small: true, onPressed: () => _trashRestore(aInt(aMap(x)['id']))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              const AdminMuted('Only the master admin can start revenue over or delete test orders.'),
          ],
        ),
      );
    });
  }
}

class _RevPainter extends CustomPainter {
  _RevPainter(this.vals, this.labels);

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

    final grid = Paint()
      ..color = const Color(0xFFE6E9E7)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i++) {
      final y = 6 + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - 6, y), grid);
      final v = maxV * i / 4;
      final t = v >= 1000 ? '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}K' : v.toStringAsFixed(0);
      final tp = TextPainter(text: TextSpan(text: t, style: const TextStyle(fontSize: 10, color: AC.muted)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(left - tp.width - 4, y - tp.height / 2));
    }

    final n = vals.length;
    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(left + (n == 1 ? w / 2 : w * i / (n - 1)), 6 + h - h * (vals[i] / maxV)),
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

    canvas.drawPath(fill, Paint()..color = const Color(0x2EE4B43C));
    canvas.drawPath(
      line,
      Paint()
        ..color = AC.gold2
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    final step = (n / 7).ceil().clamp(1, 99);
    final dot = Paint()..color = AC.gold2;

    for (var i = 0; i < n; i++) {
      if (n <= 14 || i == n - 1) canvas.drawCircle(pts[i], 3.4, dot);

      if (i % step == 0 || i == n - 1) {
        final tp = TextPainter(text: TextSpan(text: labels[i], style: const TextStyle(fontSize: 10, color: AC.muted)), textDirection: TextDirection.ltr)..layout();
        final x = (pts[i].dx - tp.width / 2).clamp(0.0, size.width - tp.width);
        tp.paint(canvas, Offset(x, size.height - tp.height));
      }
    }
  }

  @override
  bool shouldRepaint(_RevPainter old) => old.vals != vals || old.labels != labels;
}
