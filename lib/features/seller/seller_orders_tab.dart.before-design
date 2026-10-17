import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_panel_ui.dart';
import 'seller_open_product.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

/// Orders page, laid out like the website's seller orders page.
class SellerOrdersTab extends StatefulWidget {
  const SellerOrdersTab({
    super.key,
    required this.session,
    required this.service,
    required this.onExpired,
    this.onChanged,
  });

  final SellerSession session;
  final SellerService service;
  final VoidCallback onExpired;
  final VoidCallback? onChanged;

  @override
  State<SellerOrdersTab> createState() => _SellerOrdersTabState();
}

class _SellerOrdersTabState extends State<SellerOrdersTab> {
  PanelOrdersData? _data;
  String _show = '';
  int? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await runSeller<PanelOrdersData>(
      context: context,
      onExpired: widget.onExpired,
      action: () => widget.service.fetchPanelOrders(widget.session.token),
    );

    if (!mounted) return;

    setState(() {
      _data = data ??
          _data ??
          const PanelOrdersData(orders: [], autoMaster: true, autoMine: true);
    });
  }

  Future<void> _approve(PanelOrder order) async {
    setState(() => _busy = order.id);

    final data = await runSeller<PanelOrdersData>(
      context: context,
      onExpired: widget.onExpired,
      action: () =>
          widget.service.approvePanelOrder(widget.session.token, order.id),
    );

    if (!mounted) return;

    setState(() {
      _busy = null;

      if (data != null) _data = data;
    });

    if (data != null) {
      widget.onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order #${order.id} approved.')),
      );
    }
  }

  Widget _chip(String value, String label, int count) {
    final on = _show == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: on ? IanovaColors.primary : IanovaColors.soft,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => setState(() => _show = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              '$label  $count',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : IanovaColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(PanelOrder o) {
    return PanelBlock(
      borderColor: o.waiting ? const Color(0xFFF6E3B4) : null,
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
              SPill(
                orderPillText(o.status, o.approved),
                orderPillKind(o.status, o.approved),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(o.customer, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(
            '${o.phone}${o.address.isNotEmpty ? ' · ${o.address}' : ''}',
            style: const TextStyle(color: IanovaColors.secondary, fontSize: 13),
          ),
          Text(
            o.createdAt,
            style: const TextStyle(color: IanovaColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          for (final it in o.items)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openSellerProduct(
                context: context,
                session: widget.session,
                service: widget.service,
                onExpired: widget.onExpired,
                name: it.name,
                option: it.option,
                onChanged: widget.onChanged,
              ),
              child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: IanovaColors.border),
              ),
              child: Row(
                children: [
                  SellerThumb(
                    image: it.photo.image,
                    emoji: it.photo.emoji,
                    bgColor: it.photo.bgColor,
                    size: 44,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${it.quantity} × ${formatKsh(it.quantity == 0 ? 0 : it.lineTotal / it.quantity)}'
                          '${it.option.isNotEmpty ? ' · ${it.option}' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: IanovaColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatKsh(it.lineTotal),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Your total ${formatKsh(o.total)}',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 10),
          if (o.approved)
            const Text(
              'You approved this order.',
              style: TextStyle(color: IanovaColors.secondary),
            )
          else if (o.note.isNotEmpty)
            Text(o.note, style: const TextStyle(color: IanovaColors.secondary))
          else
            FilledButton(
              onPressed: _busy == o.id ? null : () => _approve(o),
              style: FilledButton.styleFrom(
                backgroundColor: IanovaColors.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _busy == o.id
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Approve order'),
            ),
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

    final all = data.orders;
    final waiting = all.where((o) => o.waiting).toList();
    final done = all.where((o) => o.approved).toList();
    final rows = _show == 'waiting'
        ? waiting
        : _show == 'approved'
            ? done
            : all;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('', 'All', all.length),
                _chip('waiting', 'Waiting for you', waiting.length),
                _chip('approved', 'Approved', done.length),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (rows.isEmpty)
            const PanelBlock(
              child: Text(
                'No orders here.',
                style: TextStyle(color: IanovaColors.secondary),
              ),
            ),
          for (final o in rows) _card(o),
        ],
      ),
    );
  }
}
