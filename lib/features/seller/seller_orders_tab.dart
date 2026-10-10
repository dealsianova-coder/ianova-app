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
  List<SellerOrder>? _orders;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orders = await runSeller<List<SellerOrder>>(
      context: context,
      onExpired: widget.onExpired,
      action: () => widget.service.fetchOrders(widget.session.token),
    );

    if (!mounted) return;

    setState(() => _orders = orders ?? _orders ?? const []);
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;

    return RefreshIndicator(
      onRefresh: _load,
      child: orders == null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : orders.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(
                      child: Text(
                        'No orders for your products yet.',
                        style: TextStyle(color: IanovaColors.secondary),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(IanovaSpacing.lg),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final o = orders[index];

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
                                sellerLabel(o.status),
                                color: SellerPill.forStatus(o.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            o.createdAt,
                            style: const TextStyle(
                              fontSize: 12,
                              color: IanovaColors.muted,
                            ),
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
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text('${item.quantity} × ${item.name}'),
                                  ),
                                  Text(
                                    formatKsh(item.unitPrice * item.quantity),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
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
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
