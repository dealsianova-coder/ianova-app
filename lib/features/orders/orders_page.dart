import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../../core/format/money.dart';

import '../../core/network/api_service.dart';
import 'order_edit_page.dart';
import 'order_manage_service.dart';
import '../../models/order.dart';


const double _spaceSm = 10;
const double _spaceMd = 16;
const double _spaceLg = 24;


class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final ApiService _api = ApiService();

  List<Order> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await _api.getOrders();

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My orders'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(_spaceLg),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: _spaceMd),
            const Text(
              'Unable to load orders',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: _spaceSm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: _spaceLg),
            Center(
              child: FilledButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(_spaceLg),
          children: [
            const SizedBox(height: 120),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: _spaceMd),
            const Text(
              'No orders yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: _spaceSm),
            Text(
              'Your completed purchases will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.all(_spaceMd),
        itemCount: _orders.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: _spaceSm),
        itemBuilder: (context, index) {
          final order = _orders[index];

          return _OrderCard(
            order: order,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailPage(
                    orderId: order.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(_spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: _spaceSm),
              Text(
                order.createdAt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: _spaceMd),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    formatKsh(order.total),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _spaceSm),
              Row(
                children: [
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  Text(
                    'View order details',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = status.isEmpty
        ? 'Pending'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  final int orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ApiService _api = ApiService();

  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _cancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel order #${order.id}?'),
        content: const Text('Your items will be released back to the store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await OrderManageService().cancel(order.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled.')),
      );
      _loadOrder();
    } on OrderManageException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _editOrder(Order order) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => OrderEditPage(order: order)),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == 'cancelled' ? 'Order cancelled.' : 'Order updated.',
          ),
        ),
      );
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final order = await _api.getOrder(widget.orderId);

      if (!mounted) {
        return;
      }

      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(_spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
              ),
              const SizedBox(height: _spaceMd),
              const Text(
                'Unable to load order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: _spaceSm),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: _spaceLg),
              FilledButton.icon(
                onPressed: _loadOrder,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order;

    if (order == null) {
      return const Center(
        child: Text('Order not found.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: ListView(
        padding: const EdgeInsets.all(_spaceMd),
        children: [
          _DetailHeader(order: order),
          const SizedBox(height: _spaceMd),
          _AddressCard(order: order),
          const SizedBox(height: _spaceMd),
          Text(
            'Items',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: _spaceSm),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: _spaceSm),
              child: _OrderItemCard(item: item),
            ),
          ),
          const SizedBox(height: _spaceMd),
          _TotalsCard(order: order),
          if (order.status == 'pending') ...[
            const SizedBox(height: _spaceMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelOrder(order),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cancel order'),
                  ),
                ),
                const SizedBox(width: _spaceSm),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _editOrder(order),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit order'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_spaceMd),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.createdAt,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusBadge(status: order.status),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: _spaceSm),
            Text(order.guestName),
            if (order.guestPhone.isNotEmpty) Text(order.guestPhone),
            const SizedBox(height: 4),
            Text(order.address),
          ],
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    required this.item,
  });

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final variantParts = [
      item.variantColor,
      item.variantSize,
    ].where((value) => value != null && value.isNotEmpty).join(' • ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_spaceSm),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.image.isEmpty
                  ? const Icon(Icons.shopping_bag_outlined)
                  : Image.network(
                      IanovaApiConfig.imageUrl(item.image),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.shopping_bag_outlined),
                    ),
            ),
            const SizedBox(width: _spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (variantParts.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      variantParts,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} × ${formatKsh(item.unitPrice)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: _spaceSm),
            Text(
              formatKsh(item.itemTotal),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.order,
  });

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(_spaceMd),
        child: Column(
          children: [
            if (order.subtotal != null)
              _TotalRow(
                label: 'Subtotal',
                value: order.subtotal!,
              ),
            if (order.delivery != null) ...[
              const SizedBox(height: _spaceSm),
              _TotalRow(
                label: 'Delivery',
                value: order.delivery!,
              ),
            ],
            if (order.discount > 0) ...[
              const SizedBox(height: _spaceSm),
              _TotalRow(
                label: order.couponCode.isEmpty ? 'Coupon discount' : 'Coupon ${order.couponCode}',
                value: -order.discount,
              ),
            ],
            const Divider(height: _spaceLg),
            _TotalRow(
              label: 'Total',
              value: order.total,
              bold: true,
            ),
            if (order.status != 'cancelled' && (order.paid > 0 || order.payPlan == 'deposit')) ...[
              const SizedBox(height: _spaceSm),
              if (order.payPlan == 'deposit')
                _TotalRow(
                  label: 'Deposit',
                  value: order.depositDue,
                ),
              if (order.payPlan == 'deposit') const SizedBox(height: _spaceSm),
              _TotalRow(
                label: 'Paid so far',
                value: order.paid,
              ),
              const SizedBox(height: _spaceSm),
              _TotalRow(
                label: order.balance > 0.009 ? 'Balance to pay' : 'Paid in full',
                value: order.balance,
                bold: true,
              ),
            ],
            if (order.status != 'cancelled' && order.balance > 0.009 && order.payInstructions.isNotEmpty) ...[
              const SizedBox(height: _spaceMd),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'How to pay: ${order.payInstructions}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style,
          ),
        ),
        Text(
          formatKsh(value),
          style: style,
        ),
      ],
    );
  }
}
