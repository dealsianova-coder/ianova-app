import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import '../../core/state/app_badges.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_inbox_view.dart';
import 'seller_models.dart';
import 'seller_ops_service.dart';
import 'seller_service.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

Future<String?> _askNote(BuildContext context, String title) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 3,
        maxLength: 800,
        decoration: const InputDecoration(
          hintText: 'What did you correct?',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(controller.text.trim()),
          child: const Text('Send to admin'),
        ),
      ],
    ),
  );
}

/// Seller area: Messages, Products (with admin restrictions) and Orders.
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({
    super.key,
    required this.session,
    required this.service,
    required this.onStatus,
    required this.onExpired,
  });

  final SellerSession session;
  final SellerService service;
  final ValueChanged<String> onStatus;
  final VoidCallback onExpired;

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard>
    with SingleTickerProviderStateMixin {
  final _ops = SellerOpsService();
  late final TabController _tabs;

  SellerSummary _summary = SellerSummary.empty;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        Future.delayed(const Duration(milliseconds: 800), _refresh);
      }
    });
    _refresh();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tabs.dispose();
    _ops.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final summary = await _ops.summary(widget.session.token);

      if (!mounted) return;

      setState(() => _summary = summary);
      AppBadges.seller.value = summary.total;

      if (summary.status.isNotEmpty) widget.onStatus(summary.status);
    } on SellerApplyException catch (error) {
      if (error.sessionExpired && mounted) widget.onExpired();
    } catch (_) {}
  }

  Future<void> _requestAccountReview() async {
    final note = await _askNote(context, 'Ask the admin to review your account');

    if (note == null || !mounted) return;

    try {
      final message = await _ops.requestReview(widget.session.token, 0, note);

      if (mounted) _snack(context, message);
    } on SellerApplyException catch (error) {
      if (mounted) _snack(context, error.message);
    }
  }

  Widget _tab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            CountBubble(count),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_summary.restricted)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDEE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your seller account is restricted by the admin.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You cannot approve orders until the admin approves your account again.',
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _requestAccountReview,
                  child: const Text('Request review'),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _tabs,
          labelColor: IanovaColors.primary,
          unselectedLabelColor: IanovaColors.muted,
          indicatorColor: IanovaColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: [
            _tab('Messages', _summary.unreadMessages),
            _tab('Products', _summary.lockedProducts),
            _tab('Orders', _summary.pendingOrders),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              SellerInboxView(
                session: widget.session,
                service: widget.service,
                onStatus: widget.onStatus,
                onExpired: widget.onExpired,
              ),
              _ProductsTab(
                ops: _ops,
                token: widget.session.token,
                onChanged: _refresh,
                onExpired: widget.onExpired,
              ),
              _OrdersTab(
                ops: _ops,
                token: widget.session.token,
                onChanged: _refresh,
                onExpired: widget.onExpired,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab({
    required this.ops,
    required this.token,
    required this.onChanged,
    required this.onExpired,
  });

  final SellerOpsService ops;
  final String token;
  final Future<void> Function() onChanged;
  final VoidCallback onExpired;

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<SellerProduct> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.ops.products(widget.token);

      if (!mounted) return;

      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } on SellerApplyException catch (error) {
      if (error.sessionExpired) widget.onExpired();

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _request(SellerProduct product) async {
    final note = await _askNote(context, 'Request review: ${product.name}');

    if (note == null || !mounted) return;

    try {
      final message = await widget.ops.requestReview(
        widget.token,
        product.id,
        note,
      );

      if (mounted) _snack(context, message);
      await widget.onChanged();
    } on SellerApplyException catch (error) {
      if (mounted) _snack(context, error.message);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF17803D);
      case 'pending':
        return const Color(0xFFA05A00);
      default:
        return const Color(0xFFB3261E);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('You have no products yet.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = _items[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: IanovaColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: IanovaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            product.status.isEmpty
                                ? ''
                                : product.status[0].toUpperCase() +
                                    product.status.substring(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _statusColor(product.status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${formatKsh(product.price)} · Stock ${product.stock}'
                        '${product.option.isEmpty ? '' : ' · ${product.option}'}',
                        style: const TextStyle(color: IanovaColors.muted),
                      ),
                      if (product.locked) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Locked by admin. You cannot change it until the admin approves it.',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _request(product),
                          child: const Text('Request review'),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab({
    required this.ops,
    required this.token,
    required this.onChanged,
    required this.onExpired,
  });

  final SellerOpsService ops;
  final String token;
  final Future<void> Function() onChanged;
  final VoidCallback onExpired;

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<SellerOrder> _items = const [];
  bool _loading = true;
  String? _error;
  int? _approving;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.ops.orders(widget.token);

      if (!mounted) return;

      setState(() {
        _items = items;
        _error = null;
        _loading = false;
      });
    } on SellerApplyException catch (error) {
      if (error.sessionExpired) widget.onExpired();

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _approve(SellerOrder order) async {
    setState(() => _approving = order.id);

    try {
      final message = await widget.ops.approve(widget.token, order.id);

      if (mounted) _snack(context, message);
    } on SellerApplyException catch (error) {
      if (mounted) _snack(context, error.message);
    }

    if (!mounted) return;

    setState(() => _approving = null);
    await _load();
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: _items.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No orders for your products yet.')),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final order = _items[index];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: IanovaColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: IanovaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            order.approved ? 'You approved' : 'Waiting for you',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: order.approved
                                  ? const Color(0xFF17803D)
                                  : const Color(0xFFA05A00),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        order.createdAt,
                        style: const TextStyle(
                          color: IanovaColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        order.customer,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (order.phone.isNotEmpty || order.address.isNotEmpty)
                        Text(
                          [order.phone, order.address]
                              .where((v) => v.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(color: IanovaColors.muted),
                        ),
                      const Divider(height: 22),
                      for (final line in order.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${line.quantity} × ${line.name}'
                                  '${line.option.isEmpty ? '' : ' (${line.option})'}',
                                ),
                              ),
                              Text(formatKsh(line.lineTotal)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Your total: ${formatKsh(order.total)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (order.canApprove)
                            FilledButton(
                              onPressed:
                                  _approving == order.id ? null : () => _approve(order),
                              child: _approving == order.id
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Approve order'),
                            )
                          else if (order.note.isNotEmpty)
                            Flexible(
                              child: Text(
                                order.note,
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  color: IanovaColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
