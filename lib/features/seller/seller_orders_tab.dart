import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({
    super.key,
    required this.session,
    required this.service,
    required this.onExpired,
  });

  final SellerSession session;
  final SellerService service;
  final VoidCallback onExpired;

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  SellerOrdersData? _data;
  String _filter = 'pending';
  bool _filterChosen = false;
  int? _busyOrder;

  @override
  void initState() {
    super.initState();
    _run(() => widget.service.fetchOrders(widget.session.token));
  }

  Future<void> _run(
    Future<SellerOrdersData> Function() action, {
    String? success,
  }) async {
    final data = await runSeller<SellerOrdersData>(
      context: context,
      onExpired: widget.onExpired,
      action: action,
    );

    if (!mounted) return;

    setState(() {
      _data = data ??
          _data ??
          const SellerOrdersData(orders: [], autoApprove: false, pending: 0);

      // First load: open on "To approve" only when something is waiting.
      if (!_filterChosen && data != null) {
        _filter = data.pending > 0 ? 'pending' : 'all';
        _filterChosen = true;
      }
    });

    if (data != null && success != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    }
  }

  Future<void> _approve(SellerOrder order) async {
    setState(() => _busyOrder = order.id);

    await _run(
      () => widget.service.decideOrder(
        widget.session.token,
        order.id,
        approve: true,
      ),
      success: 'Order #${order.id} approved.',
    );

    if (mounted) setState(() => _busyOrder = null);
  }

  Future<void> _decline(SellerOrder order) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Decline order #${order.id}?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            helperText: 'The IANOVA team will see this.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (reason == null || !mounted) return;

    setState(() => _busyOrder = order.id);

    await _run(
      () => widget.service.decideOrder(
        widget.session.token,
        order.id,
        approve: false,
        reason: reason,
      ),
      success: 'Order #${order.id} declined.',
    );

    if (mounted) setState(() => _busyOrder = null);
  }

  Widget _orderCard(SellerOrder o) {
    final busy = _busyOrder == o.id;
    final label = o.sellerStatus == 'pending'
        ? 'Needs approval'
        : o.sellerStatus == 'rejected'
            ? 'Declined'
            : 'Approved';

    return Container(
      margin: const EdgeInsets.only(bottom: IanovaSpacing.md),
      padding: const EdgeInsets.all(IanovaSpacing.lg),
      decoration: sellerCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${o.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SellerPill(
                label,
                color: SellerPill.forStatus(o.sellerStatus),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${o.createdAt} · Store status: ${sellerLabel(o.status)}',
            style: const TextStyle(fontSize: 12, color: IanovaColors.muted),
          ),
          const SizedBox(height: IanovaSpacing.sm),
          Text(
            '${o.customer} · ${o.phone}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            o.address,
            style: const TextStyle(
              color: IanovaColors.secondary,
              fontSize: 13,
            ),
          ),
          const Divider(height: 22),
          for (final item in o.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SellerThumb(
                    image: item.image,
                    emoji: item.emoji,
                    bgColor: item.bgColor,
                    size: 48,
                  ),
                  const SizedBox(width: IanovaSpacing.md),
                  Expanded(
                    child: Text(
                      '${item.quantity} × ${item.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    formatKsh(item.unitPrice * item.quantity),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Your items: ${formatKsh(o.subtotal)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (o.sellerStatus == 'pending') ...[
            const SizedBox(height: IanovaSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : () => _decline(o),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: IanovaColors.danger,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: IanovaSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => _approve(o),
                    style: FilledButton.styleFrom(
                      backgroundColor: IanovaColors.primary,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final orders = data.orders.where((o) {
      return _filter == 'all' || o.sellerStatus == _filter;
    }).toList();

    Widget chip(String value, String label) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == value,
          onSelected: (_) => setState(() {
            _filter = value;
            _filterChosen = true;
          }),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          _run(() => widget.service.fetchOrders(widget.session.token)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(IanovaSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: IanovaSpacing.lg,
              vertical: IanovaSpacing.sm,
            ),
            decoration: sellerCardDecoration(IanovaColors.sky),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: data.autoApprove,
              onChanged: (v) => _run(
                () => widget.service.setAutoOrders(widget.session.token, v),
                success: v
                    ? 'New orders will be approved automatically when in stock.'
                    : 'You will approve each order yourself.',
              ),
              title: const Text(
                'Auto-accept new orders',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Approve orders automatically when your products are in '
                'stock. You still get an email.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: IanovaSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                chip(
                  'pending',
                  data.pending > 0 ? 'To approve (${data.pending})' : 'To approve',
                ),
                chip('approved', 'Approved'),
                chip('rejected', 'Declined'),
                chip('all', 'All'),
              ],
            ),
          ),
          const SizedBox(height: IanovaSpacing.md),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'No orders here.',
                  style: TextStyle(color: IanovaColors.secondary),
                ),
              ),
            ),
          for (final o in orders) _orderCard(o),
        ],
      ),
    );
  }
}
