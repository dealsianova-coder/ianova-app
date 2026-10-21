import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_panel_ui.dart';
import 'seller_ui.dart';

/// One item of an order, for the seller: what to prepare, how many, who it is for and where it goes.
/// Opened by tapping an item inside an order (the product page is one tap further).
class SellerOrderItemPage extends StatelessWidget {
  const SellerOrderItemPage({
    super.key,
    required this.order,
    required this.item,
    this.onViewProduct,
    this.onApprove,
  });

  final PanelOrder order;
  final PanelLine item;
  final VoidCallback? onViewProduct; // kept for compatibility; not shown, orders are not a place to edit products
  final Future<void> Function()? onApprove;

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 92, child: Text(label, style: const TextStyle(color: IanovaColors.secondary))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unit = item.quantity == 0 ? 0.0 : item.lineTotal / item.quantity;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(title: const Text('Order item')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PanelBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: SellerThumb(image: item.photo.image, emoji: item.photo.emoji, bgColor: item.photo.bgColor, size: 220)),
                const SizedBox(height: 14),
                Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                if (item.option.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(item.option, style: const TextStyle(color: IanovaColors.secondary, fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFE8F3EC), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item.quantity} × ${formatKsh(unit)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                      Text(formatKsh(item.lineTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
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
                    Expanded(child: Text('In order #${order.id}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                    SPill(orderPillText(order.status, order.approved), orderPillKind(order.status, order.approved)),
                  ],
                ),
                Text(order.createdAt, style: const TextStyle(color: IanovaColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                _row('Customer', order.customer),
                _row('Phone', order.phone),
                _row('Deliver to', order.address),
              ],
            ),
          ),
          if (!order.approved && order.canApprove && order.status != 'cancelled' && onApprove != null)
            FilledButton(
              onPressed: () async {
                await onApprove!();
                if (context.mounted) Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(backgroundColor: IanovaColors.primary, minimumSize: const Size.fromHeight(50)),
              child: const Text('Approve order'),
            )
          else if (order.status == 'cancelled')
            const Text('Cancelled by the customer. Nothing to approve.', style: TextStyle(color: IanovaColors.secondary))
          else if (order.approved)
            const Text('You approved this order.', style: TextStyle(color: IanovaColors.secondary)),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Back to order'),
          ),
        ],
      ),
    );
  }
}
