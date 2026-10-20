import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

const Map<String, Color> _statusColors = <String, Color>{
  'pending': Color(0xFF7C6FD0),
  'approved': Color(0xFF2F6FDE),
  'paid': Color(0xFF17A2A2),
  'shipped': Color(0xFFE9B949),
  'delivered': Color(0xFF1D6B52),
  'cancelled': Color(0xFFB83B3B),
};

Color _statusColor(String s) => _statusColors[s] ?? AC.gray;

String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _k(double v) {
  if (v < 1000) return v.round().toString();

  final t = v / 1000;

  return '${t == t.roundToDouble() ? t.toInt().toString() : t.toStringAsFixed(1)}K';
}

/// The Analytics panel: summary cards, sales line, order status donut, recent orders, top products.
class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key, this.onGo});

  final void Function(String page)? onGo;

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> with AdminLoad<AdminAnalyticsScreen> {
  int _months = 6;

  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('analytics', query: {'months': '$_months'});

  @override
  void initState() {
    super.initState();
    load();
  }

  void _setMonths(int m) {
    setState(() {
      _months = m;
      loading = true;
      data = null;
    });
    load();
  }

  Widget _trend(dynamic t) {
    if (t == null) return const Text('▲ new', style: TextStyle(color: AC.okFg, fontWeight: FontWeight.w800, fontSize: 12));

    final v = aNum(t);

    if (v >= 0) return Text('▲ $v%', style: const TextStyle(color: AC.okFg, fontWeight: FontWeight.w800, fontSize: 12));

    return Text('▼ ${v.abs()}%', style: const TextStyle(color: AC.red, fontWeight: FontWeight.w800, fontSize: 12));
  }

  Widget _stat(String icon, Color bg, String label, String value, Widget sub) {
    return Expanded(
      child: AdminCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                  child: Text(icon, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: const TextStyle(color: AC.muted, fontSize: 12))),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 4),
            sub,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final cards = aMap(d['cards']);
      final rev = aMap(cards['revenue']);
      final ord = aMap(cards['orders']);
      final cus = aMap(cards['customers']);
      final prod = aMap(cards['products']);
      final sales = aList(d['sales']);
      final status = aList(d['status']);
      final recent = aList(d['recent']);
      final top = aList(d['top']);
      final totalOrders = aInt(d['orders_total']);
      final topMax = top.isEmpty ? 1 : math.max(1, aInt(top.first['sold']));

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stat('💰', AC.okBg, 'Total revenue', aMoney(rev['value']), Row(children: [_trend(rev['trend']), const SizedBox(width: 6), const Text('30 days', style: TextStyle(color: AC.muted, fontSize: 11))])),
                const SizedBox(width: 12),
                _stat('🛒', const Color(0xFFE3ECFB), 'Total orders', '${aInt(ord['value'])}', Row(children: [_trend(ord['trend']), const SizedBox(width: 6), const Text('30 days', style: TextStyle(color: AC.muted, fontSize: 11))])),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stat('👥', const Color(0xFFEFE9FB), 'Total customers', '${aInt(cus['value'])}', Row(children: [_trend(cus['trend']), const SizedBox(width: 6), const Text('30 days', style: TextStyle(color: AC.muted, fontSize: 11))])),
                const SizedBox(width: 12),
                _stat('📦', const Color(0xFFFDEAEA), 'Total products', '${aInt(prod['value'])}', Text('${aInt(prod['review'])} waiting for review', style: const TextStyle(color: AC.muted, fontSize: 11))),
              ],
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Sales overview', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      AdminChip(label: '6 months', selected: _months == 6, onTap: () => _setMonths(6)),
                      const SizedBox(width: 6),
                      AdminChip(label: '12 months', selected: _months == 12, onTap: () => _setMonths(12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 210,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _SalesPainter(
                        [for (final s in sales) aNum(s['value']).toDouble()],
                        [for (final s in sales) aStr(s['label'])],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Order status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CustomPaint(
                          painter: _DonutPainter(
                            [for (final s in status) aInt(s['count'])],
                            [for (final s in status) _statusColor(aStr(s['status']))],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$totalOrders', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                                const Text('Orders', style: TextStyle(color: AC.muted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            for (final s in status)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _statusColor(aStr(s['status'])), shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(_cap(aStr(s['status'])))),
                                    Text('${aStr(s['percent'])}%', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
                      const Expanded(child: Text('Recent orders', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      if (widget.onGo != null) AdminButton('View all', small: true, kind: 'gray', onPressed: () => widget.onGo!('orders')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recent.isEmpty) const AdminMuted('No orders yet.'),
                  for (final o in recent)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('#${aInt(o['id'])} · ${aStr(o['customer'])}', style: const TextStyle(fontWeight: FontWeight.w800)),
                                AdminMuted('${aStr(o['product'])}${aInt(o['items']) > 1 ? ' +${aInt(o['items']) - 1}' : ''}'),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(aMoney(o['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(color: _statusColor(aStr(o['status'])), borderRadius: BorderRadius.circular(99)),
                                child: Text(_cap(aStr(o['status'])), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                      const Expanded(child: Text('Top products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      if (widget.onGo != null) AdminButton('View all', small: true, kind: 'gray', onPressed: () => widget.onGo!('products')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (top.isEmpty) const AdminMuted('No sales yet.'),
                  for (final t in top)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(aStr(t['name']), style: const TextStyle(fontWeight: FontWeight.w800))),
                              Text('${aInt(t['sold'])} sold', style: const TextStyle(color: AC.muted, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: aInt(t['sold']) / topMax,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE8EEEA),
                              valueColor: const AlwaysStoppedAnimation<Color>(AC.green),
                            ),
                          ),
                        ],
                      ),
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

class _SalesPainter extends CustomPainter {
  _SalesPainter(this.values, this.labels);

  final List<double> values;
  final List<String> labels;

  void _text(Canvas canvas, String s, Offset at, {bool right = false, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: const TextStyle(fontSize: 10, color: AC.muted)),
      textDirection: TextDirection.ltr,
    )..layout();

    double x = at.dx;

    if (right) x -= tp.width;
    if (center) x -= tp.width / 2;

    tp.paint(canvas, Offset(x, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 38.0;
    const right = 10.0;
    const top = 8.0;
    const bottom = 24.0;

    double maxV = 0;

    for (final v in values) {
      if (v > maxV) maxV = v;
    }

    if (maxV <= 0) maxV = 1000;

    final raw = maxV / 4;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    double step = mag * 10;

    for (final m in <double>[1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]) {
      if (m * mag >= raw) {
        step = m * mag;
        break;
      }
    }

    final nice = step * 4;
    final plotH = size.height - top - bottom;
    final plotW = size.width - left - right;
    final n = values.length;

    double px(int i) => left + (n > 1 ? i * plotW / (n - 1) : plotW / 2);
    double py(double v) => top + plotH * (1 - v / nice);

    final grid = Paint()
      ..color = const Color(0xFFE1E8E4)
      ..strokeWidth = 1;

    for (int g = 0; g <= 4; g++) {
      final y = py(nice * g / 4);

      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      _text(canvas, _k(nice * g / 4), Offset(left - 6, y), right: true);
    }

    if (n == 0) return;

    final line = Path();
    final area = Path();

    for (int i = 0; i < n; i++) {
      final p = Offset(px(i), py(values[i]));

      if (i == 0) {
        line.moveTo(p.dx, p.dy);
        area.moveTo(p.dx, top + plotH);
        area.lineTo(p.dx, p.dy);
      } else {
        line.lineTo(p.dx, p.dy);
        area.lineTo(p.dx, p.dy);
      }
    }

    area.lineTo(px(n - 1), top + plotH);
    area.close();

    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, top),
          Offset(0, top + plotH),
          const [Color(0x471D6B52), Color(0x001D6B52)],
        ),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AC.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < n; i++) {
      final c = Offset(px(i), py(values[i]));

      canvas.drawCircle(c, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        c,
        4.5,
        Paint()
          ..color = AC.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      if (i < labels.length && (n <= 6 || i.isEven)) {
        _text(canvas, labels[i], Offset(px(i), size.height - 8), center: true);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesPainter old) => true;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.counts, this.colors);

  final List<int> counts;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 24.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    int total = 0;

    for (final c in counts) {
      total += c;
    }

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xFFEEF1F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (total <= 0) return;

    double start = -math.pi / 2;

    for (int i = 0; i < counts.length; i++) {
      if (counts[i] < 1) continue;

      final sweep = math.pi * 2 * counts[i] / total;

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
