import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/network/api_service.dart' show ApiException;
import '../../core/state/app_badges.dart';
import '../../core/theme/ianova_theme.dart';
import 'admin_api.dart';

void _say(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

List<Map<String, dynamic>> _maps(dynamic raw) {
  if (raw is! List) return <Map<String, dynamic>>[];

  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

/// Alerts for the admin: review requests and order approvals from sellers.
class AdminAlertsTab extends StatefulWidget {
  const AdminAlertsTab({super.key, required this.onExpired});

  final VoidCallback onExpired;

  @override
  State<AdminAlertsTab> createState() => _AdminAlertsTabState();
}

class _AdminAlertsTabState extends State<AdminAlertsTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.raw('alerts');

      if (!mounted) return;

      setState(() {
        _items = _maps(data['alerts']);
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) widget.onExpired();

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load alerts.';
        _loading = false;
      });
    }
  }

  Future<void> _markRead({int? id}) async {
    try {
      await AdminApi.instance.raw(
        'alerts_read',
        body: id == null ? {'all': true} : {'id': id},
      );
    } catch (_) {}

    await _load();
    await AppBadges.refreshAdmin();
  }

  Future<void> _open(Map<String, dynamic> alert) async {
    final id = int.tryParse('${alert['id']}');

    if (alert['read_at'] == null && id != null) {
      await _markRead(id: id);
    }

    final sellerId = int.tryParse('${alert['seller_id']}') ?? 0;

    if (sellerId > 0 && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminSellerThreadPage(
            sellerId: sellerId,
            name: 'Seller',
            onExpired: widget.onExpired,
          ),
        ),
      );

      await AppBadges.refreshAdmin();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    final hasUnread = _items.any((a) => a['read_at'] == null);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (hasUnread)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _markRead(),
                child: const Text('Mark all read'),
              ),
            ),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 100),
              child: Center(
                child: Text(
                  'No alerts yet. Seller review requests and order approvals show here.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          for (final alert in _items)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: alert['read_at'] == null
                    ? const Color(0xFFFFF8E6)
                    : IanovaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: IanovaColors.border),
              ),
              child: ListTile(
                onTap: () => _open(alert),
                leading: Icon(
                  alert['kind'] == 'review_request'
                      ? Icons.report_gmailerrorred_rounded
                      : Icons.check_circle_outline_rounded,
                  color: alert['read_at'] == null
                      ? const Color(0xFFE5173F)
                      : IanovaColors.muted,
                ),
                title: Text(
                  '${alert['title']}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${alert['body'] ?? ''}\n${alert['created_at']}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sellers with unread messages first; tap one to read, reply or restrict.
class AdminSellersTab extends StatefulWidget {
  const AdminSellersTab({super.key, required this.onExpired});

  final VoidCallback onExpired;

  @override
  State<AdminSellersTab> createState() => _AdminSellersTabState();
}

class _AdminSellersTabState extends State<AdminSellersTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.raw('seller_list');

      if (!mounted) return;

      setState(() {
        _items = _maps(data['sellers']);
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) widget.onExpired();

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load sellers.';
        _loading = false;
      });
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

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final seller = _items[index];
          final unread = int.tryParse('${seller['unread']}') ?? 0;
          final status = '${seller['status']}';
          final last = '${seller['last_message'] ?? ''}';

          return Container(
            decoration: BoxDecoration(
              color: IanovaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: IanovaColors.border),
            ),
            child: ListTile(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AdminSellerThreadPage(
                      sellerId: int.tryParse('${seller['id']}') ?? 0,
                      name: '${seller['business_name']}',
                      onExpired: widget.onExpired,
                    ),
                  ),
                );

                await _load();
                await AppBadges.refreshAdmin();
              },
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${seller['business_name']}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (unread > 0) CountBubble(unread),
                ],
              ),
              subtitle: Text(
                '${status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1)}'
                ' · ${seller['products']} products'
                '${last.isEmpty ? '' : '\n$last'}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: last.isNotEmpty,
              trailing: Icon(
                Icons.circle,
                size: 12,
                color: _statusColor(status),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One seller's conversation, with reply box and account restriction.
class AdminSellerThreadPage extends StatefulWidget {
  const AdminSellerThreadPage({
    super.key,
    required this.sellerId,
    required this.name,
    required this.onExpired,
  });

  final int sellerId;
  final String name;
  final VoidCallback onExpired;

  @override
  State<AdminSellerThreadPage> createState() => _AdminSellerThreadPageState();
}

class _AdminSellerThreadPageState extends State<AdminSellerThreadPage> {
  final _controller = TextEditingController();

  Map<String, dynamic> _seller = {};
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await AdminApi.instance.raw(
        'seller_thread',
        query: {'id': '${widget.sellerId}'},
      );

      if (!mounted) return;

      setState(() {
        _seller = Map<String, dynamic>.from(data['seller'] as Map);
        _messages = _maps(data['messages']);
        _error = null;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401) widget.onExpired();

      if (!mounted) return;

      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not load the conversation.';
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await AdminApi.instance.raw(
        'seller_reply',
        body: {'id': widget.sellerId, 'message': text},
      );
      _controller.clear();
      await _load();
    } on ApiException catch (error) {
      if (mounted) _say(context, error.message);
    }

    if (mounted) setState(() => _sending = false);
  }

  Future<void> _setStatus(String status) async {
    try {
      await AdminApi.instance.raw(
        'seller_set_status',
        body: {'id': widget.sellerId, 'status': status},
      );

      if (mounted) _say(context, 'Seller ${status == 'approved' ? 'approved' : status}.');
      await _load();
    } on ApiException catch (error) {
      if (mounted) _say(context, error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = '${_seller['status'] ?? ''}';
    final title = '${_seller['business_name'] ?? widget.name}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: _setStatus,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'approved', child: Text('Approve account')),
              PopupMenuItem(value: 'suspended', child: Text('Restrict (suspend)')),
              PopupMenuItem(value: 'rejected', child: Text('Reject')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    if (status.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: IanovaColors.surface,
                        child: Text(
                          'Account: ${status[0].toUpperCase()}${status.substring(1)}'
                          ' · ${_seller['email'] ?? ''}',
                          style: const TextStyle(color: IanovaColors.muted),
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final m in _messages.reversed)
                            Align(
                              alignment: m['sender'] == 'admin'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.78,
                                ),
                                decoration: BoxDecoration(
                                  color: m['sender'] == 'admin'
                                      ? IanovaColors.primary
                                      : IanovaColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: IanovaColors.border),
                                ),
                                child: Text(
                                  '${m['body']}',
                                  style: TextStyle(
                                    color: m['sender'] == 'admin'
                                        ? Colors.white
                                        : IanovaColors.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 2000,
                                decoration: const InputDecoration(
                                  hintText: 'Reply to the seller',
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: _sending ? null : _send,
                              icon: const Icon(Icons.send_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
