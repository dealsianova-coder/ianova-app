import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

/// Who did what in the admin and the Admin app. Master admin only.
class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> with AdminLoad<AdminActivityScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('activity_list', query: {'limit': '200'});

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final rows = aList(d['rows']);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('🧾 Activity', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const AdminMuted('Who did what in the admin and the Admin app (last 180 days).'),
            const SizedBox(height: 14),
            if (rows.isEmpty) const AdminCard(child: AdminMuted('Nothing recorded yet.')),
            for (final r in rows)
              AdminCard(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(aStr(r['action']), style: const TextStyle(fontWeight: FontWeight.w900))),
                        Text(aStr(r['created_at']), style: const TextStyle(color: AC.muted, fontSize: 11)),
                      ],
                    ),
                    Text(aStr(r['admin_name']), style: const TextStyle(fontWeight: FontWeight.w700)),
                    if (aStr(r['detail']).isNotEmpty) AdminMuted(aStr(r['detail'])),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
