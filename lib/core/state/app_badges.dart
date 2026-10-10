import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/admin/admin_api.dart';
import '../../features/seller/seller_ops_service.dart';
import '../../features/seller/seller_storage.dart';

/// Counters behind the red "new" signs for sellers and admins.
class AppBadges {
  AppBadges._();

  static final ValueNotifier<int> seller = ValueNotifier<int>(0);
  static final ValueNotifier<int> adminAlerts = ValueNotifier<int>(0);
  static final ValueNotifier<int> adminMessages = ValueNotifier<int>(0);
  static final ValueNotifier<int> adminTotal = ValueNotifier<int>(0);

  static Future<void> refreshAll() async {
    await Future.wait([refreshSeller(), refreshAdmin()]);
  }

  static Future<void> refreshSeller() async {
    try {
      final session = await SellerStorage.load();

      if (session == null) {
        seller.value = 0;
        return;
      }

      final ops = SellerOpsService();

      try {
        final summary = await ops.summary(session.token);
        seller.value = summary.total;
      } finally {
        ops.dispose();
      }
    } catch (_) {
      // Badges are optional; ignore network problems.
    }
  }

  static Future<void> refreshAdmin() async {
    try {
      if (await AdminApi.instance.token() == null) {
        adminAlerts.value = 0;
        adminMessages.value = 0;
        adminTotal.value = 0;
        return;
      }

      final data = await AdminApi.instance.raw('badges');
      final alerts = int.tryParse('${data['alerts']}') ?? 0;
      final messages = int.tryParse('${data['messages']}') ?? 0;

      adminAlerts.value = alerts;
      adminMessages.value = messages;
      adminTotal.value = alerts + messages;
    } catch (_) {
      // Badges are optional; ignore network problems.
    }
  }
}

class CountBubble extends StatelessWidget {
  const CountBubble(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFE5173F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Tab text with a red count next to it.
class BadgeLabel extends StatelessWidget {
  const BadgeLabel({super.key, required this.label, required this.count});

  final String label;
  final ValueListenable<int> count;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (context, n, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (n > 0) ...[
              const SizedBox(width: 6),
              CountBubble(n),
            ],
          ],
        );
      },
    );
  }
}

/// An icon with a red count on its corner.
class BadgeIcon extends StatelessWidget {
  const BadgeIcon({super.key, required this.icon, required this.count});

  final IconData icon;
  final ValueListenable<int> count;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: count,
      builder: (context, n, _) {
        return Badge(
          isLabelVisible: n > 0,
          label: Text(n > 99 ? '99+' : '$n'),
          child: Icon(icon),
        );
      },
    );
  }
}

/// Puts a red count on the top-right corner of any widget.
class BadgeCorner extends StatelessWidget {
  const BadgeCorner({super.key, required this.count, required this.child});

  final ValueListenable<int> count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: ValueListenableBuilder<int>(
            valueListenable: count,
            builder: (context, n, _) {
              if (n <= 0) return const SizedBox.shrink();

              return CountBubble(n);
            },
          ),
        ),
      ],
    );
  }
}

/// Keeps the admin counters fresh while the admin screen is open.
class AdminBadgePoller extends StatefulWidget {
  const AdminBadgePoller({super.key, required this.child});

  final Widget child;

  @override
  State<AdminBadgePoller> createState() => _AdminBadgePollerState();
}

class _AdminBadgePollerState extends State<AdminBadgePoller> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppBadges.refreshAdmin();
    _timer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => AppBadges.refreshAdmin(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
