import 'package:flutter/material.dart';

import '../../core/format/money.dart';
import 'admin_api.dart';
import 'admin_revenue.dart' show adminAsk;
import 'admin_ui.dart';

/// Everything that was cleared or deleted and can still be brought back (30 days).
class AdminTrashScreen extends StatefulWidget {
  const AdminTrashScreen({super.key});

  @override
  State<AdminTrashScreen> createState() => _AdminTrashScreenState();
}

class _AdminTrashScreenState extends State<AdminTrashScreen> with AdminLoad<AdminTrashScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('trash_list');

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> _restore(String action, int id, String title) async {
    final v = await adminAsk(context, title, 'Brings it back exactly as it was.', ['🔒 Security password']);

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel(action, body: {'id': id, 'security_password': v[0]}));

    if (ok && mounted) {
      adminSay(context, 'Restored.');
      load();
    }
  }

  String _when(dynamic v) {
    final t = aStr(v);

    return t.length >= 16 ? t.substring(0, 16) : t;
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final orders = aList(d['orders']);
      final resets = aList(d['resets']);
      final days = aInt(d['hold_days']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdminCard(
              color: const Color(0xFFFFF6E3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🗑️ Trash', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  AdminMuted('Deleted orders and cleared revenue stay here for $days days. After that they are permanently deleted.'),
                ],
              ),
            ),
            const AdminHeading('🛒 Deleted orders'),
            if (orders.isEmpty) const AdminCard(child: AdminMuted('Nothing here.')),
            for (final x in orders)
              AdminCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${aInt(aMap(x)['n'])} orders · ${formatKsh(aNum(aMap(x)['total']))}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          AdminMuted('Deleted ${_when(aMap(x)['created_at'])} by ${aStr(aMap(x)['admin'])}'),
                          AdminMuted(
                            aBool(aMap(x)['can_restore'])
                                ? '${aInt(aMap(x)['days_left'])} days left to restore'
                                : (aMap(x)['restored_at'] != null ? 'Restored' : 'Permanently deleted'),
                          ),
                        ],
                      ),
                    ),
                    if (aBool(aMap(x)['can_restore']))
                      AdminButton('Restore', kind: 'gray', small: true, onPressed: () => _restore('revenue_trash_restore_do', aInt(aMap(x)['id']), 'Restore orders')),
                  ],
                ),
              ),
            const AdminHeading('💰 Cleared revenue'),
            if (resets.isEmpty) const AdminCard(child: AdminMuted('Nothing here.')),
            for (final x in resets)
              AdminCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aMap(x)['confirmed'] == null ? 'Revenue archive' : '${formatKsh(aNum(aMap(x)['confirmed']))} from ${aInt(aMap(x)['orders'])} orders',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          AdminMuted('Cleared ${_when(aMap(x)['reset_at'])} by ${aStr(aMap(x)['admin'])}${aStr(aMap(x)['label']).isEmpty ? '' : ' · ${aStr(aMap(x)['label'])}'}'),
                          AdminMuted(
                            aBool(aMap(x)['can_restore'])
                                ? '${aInt(aMap(x)['days_left'])} days left to restore'
                                : (aMap(x)['restored_at'] != null ? 'Restored' : (aMap(x)['purged_at'] != null ? 'Permanently deleted' : 'Restore the newest clear first')),
                          ),
                        ],
                      ),
                    ),
                    if (aBool(aMap(x)['can_restore']))
                      AdminButton('Restore', kind: 'gray', small: true, onPressed: () => _restore('revenue_restore_do', aInt(aMap(x)['id']), 'Restore revenue')),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
