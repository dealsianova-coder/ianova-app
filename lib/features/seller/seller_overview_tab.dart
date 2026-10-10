import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

class SellerOverviewTab extends StatefulWidget {
  const SellerOverviewTab({
    super.key,
    required this.session,
    required this.service,
    required this.onExpired,
  });

  final SellerSession session;
  final SellerService service;
  final VoidCallback onExpired;

  @override
  State<SellerOverviewTab> createState() => _SellerOverviewTabState();
}

class _SellerOverviewTabState extends State<SellerOverviewTab> {
  SellerSummary? _summary;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await runSeller<SellerSummary>(
      context: context,
      onExpired: widget.onExpired,
      action: () => widget.service.fetchSummary(widget.session.token),
    );

    if (!mounted) return;

    setState(() {
      _summary = summary ?? _summary;
      _failed = summary == null && _summary == null;
    });
  }

  Widget _tile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: sellerCardDecoration(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: IanovaColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _summary;

    return RefreshIndicator(
      onRefresh: _load,
      child: s == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                Center(
                  child: _failed
                      ? const Text('Pull down to try again.')
                      : const CircularProgressIndicator(),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(IanovaSpacing.lg),
              children: [
                Container(
                  padding: const EdgeInsets.all(IanovaSpacing.xl),
                  decoration: sellerCardDecoration(IanovaColors.primary),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sales, last 30 days',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatKsh(s.last30.revenue),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${s.last30.orders} orders · ${s.last30.units} items',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: IanovaSpacing.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: IanovaSpacing.md,
                  crossAxisSpacing: IanovaSpacing.md,
                  childAspectRatio: 1.9,
                  children: [
                    _tile('Last 7 days', formatKsh(s.last7.revenue),
                        IanovaColors.sky),
                    _tile('All time', formatKsh(s.allTime.revenue),
                        IanovaColors.sand),
                    _tile('Live products', '${s.approved}', IanovaColors.soft),
                    _tile('In review', '${s.pending}', IanovaColors.soft),
                  ],
                ),
                if (s.lowStock > 0) ...[
                  const SizedBox(height: IanovaSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(IanovaSpacing.md),
                    decoration: sellerCardDecoration(IanovaColors.blush),
                    child: Text(
                      '${s.lowStock} live product${s.lowStock == 1 ? '' : 's'} '
                      'low on stock (3 or fewer left).',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const SizedBox(height: IanovaSpacing.xl),
                const Text(
                  'Best sellers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: IanovaSpacing.sm),
                if (s.top.isEmpty)
                  const Text(
                    'No sales yet. Orders will show up here.',
                    style: TextStyle(color: IanovaColors.secondary),
                  ),
                for (final t in s.top)
                  Container(
                    margin: const EdgeInsets.only(bottom: IanovaSpacing.sm),
                    padding: const EdgeInsets.all(IanovaSpacing.md),
                    decoration: sellerCardDecoration(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${t.units} sold · ${formatKsh(t.revenue)}',
                          style: const TextStyle(
                            color: IanovaColors.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
