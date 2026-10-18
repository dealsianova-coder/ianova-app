import 'dart:async';

import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_extras.dart';
import 'admin_ui.dart';

// ------------------------------------------------------------------ store control

class AdminStoreScreen extends StatefulWidget {
  const AdminStoreScreen({super.key});

  @override
  State<AdminStoreScreen> createState() => _AdminStoreScreenState();
}

class _AdminStoreScreenState extends State<AdminStoreScreen> with AdminLoad<AdminStoreScreen> {
  static const _toggles = <String, String>{
    'show_flash': 'Flash deals',
    'show_sale': 'Sale shortcut (app)',
    'show_categories': 'Category shortcuts (app)',
    'show_recent': 'Recently viewed (app)',
    'show_popular': 'Popular picks (app)',
  };

  final TextEditingController _text = TextEditingController();
  final TextEditingController _free = TextEditingController();
  final TextEditingController _fee = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final Map<String, bool> _flags = <String, bool>{};
  String _endsAt = '';
  bool _saving = false;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final store = await AdminApi.instance.storeGet();

    _flags['announcement_enabled'] = aStr(store['announcement_enabled']) == '1';
    for (final k in _toggles.keys) {
      _flags[k] = aStr(store[k]) == '1';
    }
    _text.text = aStr(store['announcement_text']);
    _free.text = aStr(store['free_delivery_threshold']);
    _fee.text = aStr(store['delivery_fee']);
    _phone.text = aStr(store['support_phone']);
    _email.text = aStr(store['support_email']);
    _endsAt = aStr(store['flash_ends_at']);

    return store;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _text.dispose();
    _free.dispose();
    _fee.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.storeSet({
        for (final e in _flags.entries) e.key: e.value,
        'announcement_text': _text.text,
        'free_delivery_threshold': double.tryParse(_free.text) ?? 0,
        'delivery_fee': double.tryParse(_fee.text) ?? 0,
        'support_phone': _phone.text,
        'support_email': _email.text,
        'flash_ends_at': _endsAt,
      }),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) adminSay(context, 'Saved. The app and the website use these right away.');
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Announcement bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const AdminMuted('A message across the top of the website and the app home screen.'),
                const SizedBox(height: 10),
                AdminSwitch(
                  label: 'Show the announcement',
                  value: _flags['announcement_enabled'] == true,
                  onChanged: (v) => setState(() => _flags['announcement_enabled'] = v),
                ),
                AdminField(label: 'Message', controller: _text, maxLength: 160, hint: 'e.g. Weekend sale: up to 40% off'),
              ],
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                AdminField(
                  label: 'Free delivery on orders over (KSh)',
                  controller: _free,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
                AdminField(
                  label: 'Delivery fee below that (KSh)',
                  controller: _fee,
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Home screen sections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const AdminMuted('Turn parts of the front store on or off.'),
                const SizedBox(height: 10),
                for (final e in _toggles.entries)
                  AdminSwitch(
                    label: e.value,
                    value: _flags[e.key] == true,
                    onChanged: (v) => setState(() => _flags[e.key] = v),
                  ),
              ],
            ),
          ),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Support contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                AdminField(label: 'Phone', controller: _phone, keyboard: TextInputType.phone),
                AdminField(label: 'Email', controller: _email, keyboard: TextInputType.emailAddress),
              ],
            ),
          ),
          AdminButton('Save changes', busy: _saving, onPressed: _save),
          const SizedBox(height: 24),
        ],
      );
    });
  }
}

// ------------------------------------------------------------------ site content & settings

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> with AdminLoad<AdminSettingsScreen> {
  final Map<String, TextEditingController> _c = <String, TextEditingController>{};
  bool _saving = false;

  @override
  Future<Map<String, dynamic>> fetch() async {
    final d = await AdminApi.instance.panel('settings_get');

    for (final f in aList(d['fields'])) {
      _c.putIfAbsent(aStr(f['key']), () => TextEditingController()).text = aStr(f['value']);
    }

    return d;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('settings_set', body: {
        'values': {for (final e in _c.entries) e.key: e.value.text},
      }),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (ok) adminSay(context, 'Site content and settings saved.');
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final fields = aList(d['fields']);
      final groups = <String>[];

      for (final f in fields) {
        if (!groups.contains(aStr(f['group']))) groups.add(aStr(f['group']));
      }

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final g in groups)
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  for (final f in fields)
                    if (aStr(f['group']) == g)
                      AdminField(label: aStr(f['label']), controller: _c[aStr(f['key'])]!),
                ],
              ),
            ),
          AdminButton('Save settings', busy: _saving, onPressed: _save),
          const SizedBox(height: 24),
        ],
      );
    });
  }
}

// ------------------------------------------------------------------ alerts

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> with AdminLoad<AdminAlertsScreen> {
  Timer? _poll;

  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.raw('alerts');

  @override
  void initState() {
    super.initState();
    load();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) => load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _read({int? id}) async {
    await adminTry(
      context,
      () => AdminApi.instance.raw('alerts_read', body: id == null ? {'all': true} : {'id': id}),
    );
    await load();

    final cb = widget.onChanged;
    if (cb != null) cb();
  }

  Future<void> _open(Map<String, dynamic> a) async {
    final id = aInt(a['id']);

    if (a['read_at'] == null && id > 0) await _read(id: id);
    if (!mounted) return;

    final sellerId = aInt(a['seller_id']);

    if (sellerId > 0) {
      await adminPush(
        context,
        AdminSellerThreadPage(
          sellerId: sellerId,
          name: 'Seller',
          onExpired: () {
            final hook = AdminApi.expiredHook;
            if (hook != null) hook();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final items = aList(d['alerts']);
      final hasUnread = items.any((a) => a['read_at'] == null);

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (hasUnread)
              Align(
                alignment: Alignment.centerLeft,
                child: AdminButton('Mark all read', kind: 'gray', small: true, onPressed: () => _read()),
              ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              const AdminCard(
                child: AdminMuted('Nothing yet. You will see seller review requests and order approvals here.'),
              ),
            for (final a in items)
              AdminCard(
                color: a['read_at'] == null ? const Color(0xFFFFF8E6) : Colors.white,
                onTap: () => _open(a),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(aStr(a['title']), style: const TextStyle(fontWeight: FontWeight.w900)),
                    if (aStr(a['body']).isNotEmpty) AdminMuted(aStr(a['body'])),
                    const SizedBox(height: 4),
                    AdminMuted(aStr(a['created_at'])),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
