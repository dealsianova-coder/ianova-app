import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_broadcast.dart';
import 'admin_extras.dart';
import 'admin_ui.dart';

/// Sellers: approve, suspend, auto-approval switches, messages.
class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({super.key, this.initialStatus = ''});

  /// '' = all, 'pending' = waiting for approval, 'messages' = unread messages.
  final String initialStatus;

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> with AdminLoad<AdminSellersScreen> {
  late String _filter = widget.initialStatus;

  bool _match(Map<String, dynamic> s) {
    switch (_filter) {
      case 'pending':
        return aStr(s['status']) == 'pending';
      case 'messages':
        return aInt(s['unread']) > 0;
      case 'approved':
        return aStr(s['status']) == 'approved';
      case 'suspended':
        return aStr(s['status']) == 'suspended' || aStr(s['status']) == 'rejected';
    }

    return true;
  }

  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('sellers_full');

  @override
  void initState() {
    super.initState();
    load();
  }

  void _expired() {
    final hook = AdminApi.expiredHook;
    if (hook != null) hook();
  }

  Future<void> _act(Map<String, dynamic> s, String action, [String? confirm]) async {
    if (confirm != null && !await adminConfirm(context, confirm)) return;
    if (!mounted) return;

    String note = 'Saved.';

    final ok = await adminTry(context, () async {
      final r = await AdminApi.instance.panel('seller_action', body: {'id': aInt(s['id']), 'do': action});
      note = aStr(r['note']);
    });

    if (!mounted) return;

    if (ok) adminSay(context, note);
    load();
  }

  Future<void> _master(bool on) async {
    await adminTry(context, () => AdminApi.instance.panel('auto_master', body: {'on': on}));
    load();
  }

  Future<void> _messages(Map<String, dynamic> s) async {
    await adminPush(
      context,
      AdminSellerThreadPage(
        sellerId: aInt(s['id']),
        name: aStr(s['business_name']),
        onExpired: _expired,
      ),
    );
    load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final all = aList(d['sellers']);
      final sellers = all.where((x) => _match(aMap(x))).toList();
      final master = aBool(d['master_auto']);
      int n(bool Function(Map<String, dynamic>) f) => all.where((x) => f(aMap(x))).length;

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdminSwitch(
                    label: 'Automatic order approval',
                    sub: master
                        ? 'ON: in-stock seller orders are approved for sellers who have it on.'
                        : 'OFF for everyone: sellers approve orders by hand.',
                    value: master,
                    onChanged: _master,
                  ),
                  const SizedBox(height: 4),
                  AdminButton(
                    'Message all sellers',
                    kind: 'gray',
                    small: true,
                    onPressed: () => adminPush(context, AdminBroadcastPage(onExpired: _expired)),
                  ),
                ],
              ),
            ),
            AdminChipRow(
              children: [
                AdminChip(label: 'All', count: all.length, selected: _filter == '', onTap: () => setState(() => _filter = '')),
                AdminChip(label: '🕒 To approve', count: n((x) => aStr(x['status']) == 'pending'), selected: _filter == 'pending', onTap: () => setState(() => _filter = 'pending')),
                AdminChip(label: '💬 New messages', count: n((x) => aInt(x['unread']) > 0), selected: _filter == 'messages', onTap: () => setState(() => _filter = 'messages')),
                AdminChip(label: 'Approved', count: n((x) => aStr(x['status']) == 'approved'), selected: _filter == 'approved', onTap: () => setState(() => _filter = 'approved')),
                AdminChip(label: 'Suspended', count: n((x) => aStr(x['status']) == 'suspended' || aStr(x['status']) == 'rejected'), selected: _filter == 'suspended', onTap: () => setState(() => _filter = 'suspended')),
              ],
            ),
            const SizedBox(height: 10),
            if (sellers.isEmpty) AdminCard(child: AdminMuted(all.isEmpty ? 'No sellers yet.' : 'No sellers in this list.')),
            for (final s in sellers)
              AdminCard(
                accent: aStr(s['status']) == 'pending' ? AC.gold : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            aStr(s['business_name']),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                        ATag(
                          aStr(s['status']).isEmpty
                              ? ''
                              : '${aStr(s['status'])[0].toUpperCase()}${aStr(s['status']).substring(1)}',
                          kind: aStr(s['status']) == 'approved'
                              ? 'ok'
                              : (aStr(s['status']) == 'pending' ? 'wait' : 'na'),
                        ),
                      ],
                    ),
                    if (aStr(s['business_description']).isNotEmpty) AdminMuted(aStr(s['business_description'])),
                    const SizedBox(height: 6),
                    Text(aStr(s['email'])),
                    if (aStr(s['phone']).isNotEmpty) Text(aStr(s['phone'])),
                    AdminMuted(
                      '${aInt(s['products'])} products · ${aInt(s['orders'])} orders'
                      '${aInt(s['waiting']) > 0 ? ' · ${aInt(s['waiting'])} waiting' : ''} · joined ${aStr(s['created_at'])}',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AdminButton(
                          aInt(s['unread']) > 0 ? 'Messages (${aInt(s['unread'])} new)' : 'Messages',
                          small: true,
                          onPressed: () => _messages(s),
                        ),
                        AdminButton(
                          aBool(s['auto']) ? 'Auto-approve: ON' : 'Auto-approve: OFF',
                          small: true,
                          kind: aBool(s['auto']) ? 'green' : 'gray',
                          onPressed: () => _act(s, aBool(s['auto']) ? 'auto_off' : 'auto_on'),
                        ),
                        if (aStr(s['status']) == 'pending') ...[
                          AdminButton('Approve', small: true, onPressed: () => _act(s, 'approved')),
                          AdminButton('Reject', small: true, kind: 'red', onPressed: () => _act(s, 'rejected')),
                        ],
                        if (aStr(s['status']) == 'approved')
                          AdminButton(
                            'Suspend',
                            small: true,
                            kind: 'red',
                            onPressed: () => _act(s, 'suspended', 'Suspend this seller? They will be unable to log in.'),
                          ),
                        if (aStr(s['status']) == 'suspended')
                          AdminButton('Reactivate', small: true, onPressed: () => _act(s, 'approved')),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
