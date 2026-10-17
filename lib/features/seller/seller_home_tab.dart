import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_panel_ui.dart';
import 'seller_ui.dart';

/// Dashboard page: needs-attention list, tiles, automatic approval, recent orders.
class SellerHomeTab extends StatelessWidget {
  const SellerHomeTab({
    super.key,
    required this.dash,
    required this.onGo,
    required this.onRefresh,
    this.onToggleAuto,
  });

  final PanelDashboard? dash;
  final void Function(int index, {String productFilter}) onGo;
  final Future<void> Function() onRefresh;
  final Future<void> Function(bool on)? onToggleAuto;

  Widget _attention(String icon, String text, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E2BC)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: IanovaColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _tile(String icon, String label, String value, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: IanovaColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F0F12),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: IanovaColors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = dash;

    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final attention = <Widget>[
      if (d.pendingOrders > 0)
        _attention(
          '🛒',
          '${d.pendingOrders} order${d.pendingOrders == 1 ? '' : 's'} waiting for you',
          () => onGo(2),
        ),
      if (d.unread > 0)
        _attention(
          '💬',
          '${d.unread} new message${d.unread == 1 ? '' : 's'} from the admin',
          () => onGo(3),
        ),
      if (d.locked > 0)
        _attention(
          '🔒',
          '${d.locked} product${d.locked == 1 ? '' : 's'} restricted by the admin',
          () => onGo(1, productFilter: 'locked'),
        ),
      if (d.pendingProducts > 0)
        _attention(
          '⏳',
          '${d.pendingProducts} product${d.pendingProducts == 1 ? '' : 's'} waiting for admin approval',
          () => onGo(1, productFilter: 'pending'),
        ),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (attention.isNotEmpty)
            PanelBlock(
              color: const Color(0xFFFFFBF1),
              borderColor: const Color(0xFFF6E3B4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Needs your attention',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...attention,
                ],
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.35,
            children: [
              _tile('📦', 'Products', '${d.products}', () => onGo(1)),
              _tile('🛒', 'Orders', '${d.orders}', () => onGo(2)),
              _tile(
                '⚠️',
                'Low stock (3 or less)',
                '${d.lowStock}',
                () => onGo(1),
              ),
              _tile('💰', 'Confirmed sales', formatKsh(d.revenue), () => onGo(2)),
            ],
          ),
          const SizedBox(height: 16),
          PanelBlock(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Automatic order approval: ',
                          children: [
                            TextSpan(
                              text: d.autoOn ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: d.autoOn
                                    ? const Color(0xFF0B6B37)
                                    : const Color(0xFFB00F2F),
                              ),
                            ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        !d.autoMaster
                            ? 'IANOVA has switched it off for everyone.'
                            : d.autoMine
                                ? 'In-stock orders are approved for you.'
                                : 'You approve each order by hand.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: IanovaColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onToggleAuto == null
                      ? () => onGo(4)
                      : () => onToggleAuto!(!d.autoMine),
                  style: FilledButton.styleFrom(
                    backgroundColor: IanovaColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(d.autoMine ? 'Turn off' : 'Turn on'),
                ),
              ],
            ),
          ),
          PanelBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent orders',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed: () => onGo(2),
                      style: FilledButton.styleFrom(
                        backgroundColor: IanovaColors.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('All orders'),
                    ),
                  ],
                ),
                if (d.recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'No orders yet.',
                      style: TextStyle(color: IanovaColors.secondary),
                    ),
                  ),
                for (final r in d.recent)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onGo(2),
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: IanovaColors.border),
                      ),
                      child: Row(
                        children: [
                          for (final p in r.photos)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SellerThumb(
                                image: p.image,
                                emoji: p.emoji,
                                bgColor: p.bgColor,
                                size: 44,
                              ),
                            ),
                          if (r.more > 0)
                            Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: IanovaColors.soft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${r.more}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: IanovaColors.secondary,
                                ),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order #${r.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${r.customer} · ${r.createdAt}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: IanovaColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatKsh(r.mine),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SPill(
                                orderPillText(r.status, r.approved),
                                orderPillKind(r.status, r.approved),
                              ),
                            ],
                          ),
                        ],
                      ),
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
