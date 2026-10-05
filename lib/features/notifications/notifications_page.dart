import 'package:flutter/material.dart';
import '../../core/format/money.dart';

import '../../core/network/api_service.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import '../../models/order.dart';
import '../auth/login_page.dart';
import '../orders/orders_page.dart';

/// Order updates, built from the signed-in user's orders.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _api = ApiService();

  List<Order> _orders = const [];
  bool _loading = true;
  bool _signedOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _signedOut = false;
      _error = null;
    });

    try {
      final orders = await _api.getOrders(limit: 30);

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _signedOut = error.statusCode == 401;
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load notifications.';
        _loading = false;
      });
    }
  }

  Future<void> _signIn() async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    if (loggedIn == true && mounted) {
      await _load();
    }
  }

  void _openOrder(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(orderId: order.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_signedOut) {
      return _Message(
        icon: Icons.notifications_none_rounded,
        title: 'Sign in to see updates',
        message: 'Your order updates will show up here.',
        buttonLabel: 'Sign in',
        onPressed: _signIn,
      );
    }

    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: 'Something went wrong',
        message: _error!,
        buttonLabel: 'Try again',
        onPressed: _load,
      );
    }

    if (_orders.isEmpty) {
      return const _Message(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        message: 'Order updates will show up here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(IanovaSpacing.xl),
        itemCount: _orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = _orders[index];

          return _NotificationTile(
            order: order,
            onTap: () => _openOrder(order),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(IanovaSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: IanovaColors.muted),
            const SizedBox(height: IanovaSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: IanovaSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: IanovaColors.secondary),
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: IanovaSpacing.lg),
              FilledButton(
                onPressed: onPressed,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationInfo {
  const _NotificationInfo(this.icon, this.title, this.message);

  final IconData icon;
  final String title;
  final String message;
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.order,
    required this.onTap,
  });

  final Order order;
  final VoidCallback onTap;

  _NotificationInfo _describe() {
    final id = order.id;

    switch (order.status.toLowerCase()) {
      case 'pending':
        return _NotificationInfo(
          Icons.receipt_long_rounded,
          'Order #$id received',
          'We got your order of ${formatKsh(order.total)}. '
              'We will confirm it shortly.',
        );
      case 'approved':
        return _NotificationInfo(
          Icons.check_circle_outline_rounded,
          'Order #$id confirmed',
          'Your order has been confirmed and is being prepared.',
        );
      case 'paid':
        return _NotificationInfo(
          Icons.payments_outlined,
          'Payment received for order #$id',
          'Thanks! We are getting your order ready.',
        );
      case 'shipped':
        return _NotificationInfo(
          Icons.local_shipping_outlined,
          'Order #$id is on its way',
          'Your order has been shipped.',
        );
      case 'delivered':
        return _NotificationInfo(
          Icons.done_all_rounded,
          'Order #$id delivered',
          'Enjoy your purchase!',
        );
      case 'cancelled':
        return _NotificationInfo(
          Icons.cancel_outlined,
          'Order #$id cancelled',
          'This order was cancelled.',
        );
      default:
        return _NotificationInfo(
          Icons.notifications_none_rounded,
          'Order #$id update',
          'Status: ${order.status}.',
        );
    }
  }

  String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));

    if (parsed == null) {
      return raw;
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, '
        '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final info = _describe();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(IanovaSpacing.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(IanovaSpacing.lg),
        decoration: BoxDecoration(
          color: IanovaColors.surface,
          borderRadius: BorderRadius.circular(IanovaSpacing.radiusMedium),
          border: Border.all(color: IanovaColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: IanovaColors.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, size: 22),
            ),
            const SizedBox(width: IanovaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.message,
                    style: const TextStyle(
                      color: IanovaColors.secondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      color: IanovaColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
