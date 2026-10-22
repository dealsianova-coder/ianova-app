import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import 'admin_api.dart';
import 'admin_ui.dart';

/// One item of an order: what was bought, how many, for whom, and who sells it.
/// Opened by tapping an item inside an order (not the product editor).
class AdminOrderItemPage extends StatelessWidget {
  const AdminOrderItemPage({super.key, required this.order, required this.group, required this.line});

  final Map<String, dynamic> order;
  final Map<String, dynamic> group;
  final Map<String, dynamic> line;

  Widget _row(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AC.muted))),
          Expanded(child: value),
        ],
      ),
    );
  }

  Future<void> _cancelItem(BuildContext context) async {
    if (!await adminConfirm(context, 'Cancel ${aStr(line['name'])} from order #${aInt(order['id'])}?')) return;
    if (!context.mounted) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('order_item_cancel', body: {'id': aInt(order['id']), 'product_id': aInt(line['product_id'])}),
    );

    if (!context.mounted) return;

    if (ok) {
      adminSay(context, 'Item cancelled.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = '${aStr(line['color'])} ${aStr(line['size'])}'.trim();
    final qty = aInt(line['quantity']);
    final price = aNum(line['unit_price']);
    final isMain = aBool(group['is_main']);
    final approved = aBool(group['approved']);

    return AdminSubPage(
      title: 'Order item',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: AdminThumb(
                    image: aStr(line['image']),
                    emoji: aStr(line['emoji']),
                    bg: aStr(line['bg_color']),
                    size: 220,
                  ),
                ),
                const SizedBox(height: 14),
                Text(aStr(line['name']), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                if (option.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: ATag(option, kind: 'na')),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFFE1F3E8), borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Expanded(child: Text('$qty × ${formatKsh(price)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                      Text(formatKsh(price * qty), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AC.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AdminCard(
            accent: const Color(0xFF2F6FDE),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('In order #${aInt(order['id'])}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
                    statusTag(aStr(order['status'])),
                  ],
                ),
                AdminMuted(aStr(order['created_at'])),
                const SizedBox(height: 8),
                _row('Customer', Text(aStr(order['customer']), style: const TextStyle(fontWeight: FontWeight.w700))),
                _row('Phone', Text(aStr(order['phone']))),
                _row('Address', Text(aStr(order['address']))),
              ],
            ),
          ),
          AdminCard(
            accent: isMain ? AC.green : AC.goldLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sold by', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text('${isMain ? '🏠' : '🏪'} ${aStr(group['name'])}', style: const TextStyle(fontWeight: FontWeight.w800))),
                    if (isMain) const ATag('Managed by you') else ATag(approved ? 'approved' : 'waiting', kind: approved ? 'ok' : 'wait'),
                  ],
                ),
              ],
            ),
          ),
          if (const ['pending', 'approved', 'paid'].contains(aStr(order['status'])))
            AdminCard(
              accent: AC.red,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Cancel this item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const AdminMuted('Removes only this item, puts its stock back, works out the new total and emails the customer.'),
                  const SizedBox(height: 10),
                  AdminButton('Cancel item', small: true, kind: 'red', onPressed: () => _cancelItem(context)),
                ],
              ),
            ),
          AdminButton('Back to order', kind: 'gray', onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
