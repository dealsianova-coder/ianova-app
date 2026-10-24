import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/format/money.dart';
import '../../core/theme/ianova_theme.dart';

/// What the seller has earned, been paid and is still owed (shown on the seller's dashboard).
class SellerBalanceCard extends StatefulWidget {
  const SellerBalanceCard({super.key, required this.token, required this.onExpired});

  final String token;
  final VoidCallback onExpired;

  @override
  State<SellerBalanceCard> createState() => _SellerBalanceCardState();
}

class _SellerBalanceCardState extends State<SellerBalanceCard> {
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _payouts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _n(dynamic v) => double.tryParse('$v') ?? 0;

  Future<void> _load() async {
    try {
      final response = await http.get(
        Uri.parse('${IanovaApiConfig.baseUrl}/api/seller_balance.php'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 401) {
        widget.onExpired();

        return;
      }

      final data = jsonDecode(response.body);

      if (data is! Map || data['success'] != true || data['balance'] is! Map) return;

      if (!mounted) return;

      setState(() {
        _balance = Map<String, dynamic>.from(data['balance'] as Map);
        _payouts = [
          for (final p in (data['payouts'] as List? ?? const []))
            if (p is Map) Map<String, dynamic>.from(p),
        ];
      });
    } catch (_) {
      // The card simply stays hidden when it cannot load.
    }
  }

  String _payLine(Map<String, dynamic> p) {
    final method = p['method'] == null ? '' : '${p['method']}';
    final date = p['created_at'] == null ? '' : '${p['created_at']}'.split(' ').first;

    return 'Paid ${formatKsh(_n(p['amount']))} $method · $date';
  }

  @override
  Widget build(BuildContext context) {
    final b = _balance;

    if (b == null) return const SizedBox.shrink();

    final rate = _n(b['rate']);
    final rateText = rate == rate.roundToDouble() ? rate.toStringAsFixed(0) : rate.toStringAsFixed(2);
    final owed = _n(b['balance']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: IanovaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💸 Balance owed to you', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: IanovaColors.secondary)),
          const SizedBox(height: 4),
          Text(
            formatKsh(owed),
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: owed > 0.009 ? const Color(0xFFB36B00) : IanovaColors.success),
          ),
          const SizedBox(height: 6),
          Text(
            'Paid so far ${formatKsh(_n(b['paid']))} · Coming after delivery ${formatKsh(_n(b['coming']))}',
            style: const TextStyle(color: IanovaColors.secondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'You earn the item price minus the $rateText% store commission once an order is delivered.',
            style: const TextStyle(color: IanovaColors.muted, fontSize: 12),
          ),
          for (final p in _payouts.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _payLine(p),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
