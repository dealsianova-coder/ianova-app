import 'package:flutter/material.dart';

import 'admin_api.dart';
import 'admin_ui.dart';

List<String> _strs(dynamic v) => v is List ? [for (final e in v) '$e'] : <String>[];

/// Admin team: the master admin, extra admins (with approval) and what each can see.
/// Separate from Users, which only lists sellers and customers.
class AdminTeamScreen extends StatefulWidget {
  const AdminTeamScreen({super.key});

  @override
  State<AdminTeamScreen> createState() => _AdminTeamScreenState();
}

class _AdminTeamScreenState extends State<AdminTeamScreen> with AdminLoad<AdminTeamScreen> {
  @override
  Future<Map<String, dynamic>> fetch() => AdminApi.instance.panel('team_get');

  @override
  void initState() {
    super.initState();
    load();
  }

  /// Small dialog asking for one or more secret fields. Returns the values, or null if cancelled.
  Future<List<String>?> _askSecrets(String title, String note, List<String> labels, {List<String> texts = const [], List<bool> secret = const []}) async {
    final ctrls = [for (int i = 0; i < labels.length; i++) TextEditingController(text: i < texts.length ? texts[i] : '')];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 12), child: AdminMuted(note)),
              for (int i = 0; i < labels.length; i++)
                AdminField(
                  label: labels[i],
                  controller: ctrls[i],
                  obscure: i < secret.length ? secret[i] : true,
                  keyboard: (i < secret.length && !secret[i] && labels[i].toLowerCase().contains('email')) ? TextInputType.emailAddress : null,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm')),
        ],
      ),
    );

    final vals = [for (final c in ctrls) c.text];

    for (final c in ctrls) {
      c.dispose();
    }

    if (ok != true || !mounted) return null;

    return vals;
  }

  Future<void> _editAdmin(Map<String, dynamic> a) async {
    final v = await _askSecrets(
      'Edit my account',
      'Protected by your security password.',
      ['Name', 'Email', 'New sign-in password (optional)', '🔒 Security password'],
      texts: [aStr(a['name']), aStr(a['email'])],
      secret: [false, false, true, true],
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('admin_account_save', body: {
        'id': aInt(a['id']),
        'name': v[0].trim(),
        'email': v[1].trim(),
        'new_password': v[2],
        'security_password': v[3],
      }),
    );

    if (ok) load();
  }

  Future<void> _setSecurity(bool has) async {
    final v = await _askSecrets(
      has ? 'Change security password' : 'Set security password',
      'A second password, different from your sign-in password. It protects editing your account and adding or approving admins.',
      [has ? 'Current security password' : 'Your sign-in password (to confirm it is you)', 'New security password (8+ characters)'],
    );

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('team_set_security', body: {'proof': v[0], 'new': v[1]}));

    if (ok) {
      adminSay(context, 'Security password saved.');
      load();
    }
  }

  /// Checklist of sections. Returns the chosen keys, or null if cancelled.
  Future<List<String>?> _pickAccess(String title, List<Map<String, dynamic>> sections, List<String> start) async {
    final on = <String>{...start};

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final sec in sections)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(aStr(sec['label'])),
                    value: on.contains(aStr(sec['key'])),
                    onChanged: (v) => setD(() {
                      if (v == true) {
                        on.add(aStr(sec['key']));
                      } else {
                        on.remove(aStr(sec['key']));
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(on.toList()), child: const Text('Next')),
          ],
        ),
      ),
    );
  }

  Future<void> _editAccess(Map<String, dynamic> a, List<Map<String, dynamic>> sections) async {
    final picked = await _pickAccess('What can ${aStr(a['name'])} see?', sections, _strs(a['allowed']));

    if (picked == null || !mounted) return;

    final v = await _askSecrets('Confirm access', 'Enter your security password to save.', ['🔒 Security password']);

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('team_perms', body: {'id': aInt(a['id']), 'perms': picked, 'security_password': v[0]}));

    if (ok) load();
  }

  Future<void> _addAdmin(List<Map<String, dynamic>> sections) async {
    final v = await _askSecrets(
      'Add admin',
      'The new admin is created as pending and cannot sign in until you approve them.',
      ['Full name', 'Email', 'Sign-in password for the new admin (8+)', '🔒 Your security password'],
      secret: [false, false, true, true],
    );

    if (v == null || !mounted) return;

    final picked = await _pickAccess('What can they see?', sections, const ['dashboard', 'products', 'orders']);

    if (picked == null || !mounted) return;

    final ok = await adminTry(
      context,
      () => AdminApi.instance.panel('team_add', body: {'name': v[0].trim(), 'email': v[1].trim(), 'password': v[2], 'security_password': v[3], 'perms': picked}),
    );

    if (ok) {
      adminSay(context, 'Admin added. Approve them to let them sign in.');
      load();
    }
  }

  Future<void> _teamDo(Map<String, dynamic> a, String act, String label) async {
    final v = await _askSecrets('$label ${aStr(a['name'])}?', 'Enter your security password to confirm.', ['🔒 Security password']);

    if (v == null || !mounted) return;

    final ok = await adminTry(context, () => AdminApi.instance.panel('team_do', body: {'id': aInt(a['id']), 'do': act, 'security_password': v[0]}));

    if (ok) load();
  }

  Widget _adminCard(Map<String, dynamic> a, int me, bool iAmMaster, bool hasSec, List<Map<String, dynamic>> sections) {
    final isMaster = aInt(a['is_master']) == 1;
    final mine = aInt(a['id']) == me;
    final st = aStr(a['status']).isEmpty ? 'active' : aStr(a['status']);
    final name = aStr(a['name']);
    final fg = isMaster ? Colors.white : AC.ink;
    final sub = isMaster ? const Color(0xCCFFFFFF) : AC.muted;

    final badges = <Widget>[
      if (isMaster) const ATag('👑 MASTER ADMIN', kind: 'wait'),
      if (!isMaster && st == 'pending') const ATag('PENDING APPROVAL', kind: 'wait'),
      if (!isMaster && st == 'suspended') const ATag('SUSPENDED', kind: 'na'),
      if (!isMaster && st == 'active') const ATag('ACTIVE', kind: 'ok'),
      if (mine) const ATag('YOU', kind: 'ok'),
    ];

    final actions = <Widget>[];
    final allowed = _strs(a['allowed']);

    if (mine) {
      actions.add(AdminButton(hasSec ? '🔒 Edit my account' : '🔒 Set security password first', small: true, kind: isMaster ? 'gray' : 'green', onPressed: () => hasSec ? _editAdmin(a) : _setSecurity(false)));
    } else if (iAmMaster && !isMaster) {
      actions.add(AdminButton('🔑 Access', small: true, kind: 'gray', onPressed: () => _editAccess(a, sections)));

      if (st == 'pending') {
        actions.add(AdminButton('✅ Approve', small: true, onPressed: () => _teamDo(a, 'approve', 'Approve')));
        actions.add(AdminButton('Reject', small: true, kind: 'red', onPressed: () => _teamDo(a, 'reject', 'Reject')));
      } else if (st == 'suspended') {
        actions.add(AdminButton('Restore', small: true, onPressed: () => _teamDo(a, 'restore', 'Restore')));
        actions.add(AdminButton('Remove', small: true, kind: 'red', onPressed: () => _teamDo(a, 'remove', 'Remove')));
      } else {
        actions.add(AdminButton('Suspend', small: true, kind: 'gray', onPressed: () => _teamDo(a, 'suspend', 'Suspend')));
        actions.add(AdminButton('Remove', small: true, kind: 'red', onPressed: () => _teamDo(a, 'remove', 'Remove')));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isMaster ? const LinearGradient(colors: [Color(0xFF17352C), Color(0xFF1D6B52)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        color: isMaster ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isMaster ? const Color(0xFF17352C) : const Color(0xFFE3EBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isMaster ? AC.goldLight : const Color(0xFFE9F1EC), borderRadius: BorderRadius.circular(14)),
                child: Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: isMaster ? AC.side : AC.green)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: fg)),
                    Text(aStr(a['email']), style: TextStyle(color: sub, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: badges),
          const SizedBox(height: 8),
          Text('Last sign-in: ${aStr(a['last_login']).isEmpty ? 'never' : aStr(a['last_login'])}', style: TextStyle(color: sub, fontSize: 12)),
          if (!isMaster) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Can see: ${allowed.length} of ${sections.length} sections', style: TextStyle(color: sub, fontSize: 12))),
          if (!mine && !(iAmMaster && !isMaster)) Padding(padding: const EdgeInsets.only(top: 8), child: Text('🔒 Protected: only this admin can edit this account.', style: TextStyle(color: sub, fontSize: 12))),
          if (actions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Wrap(spacing: 8, runSpacing: 8, children: actions)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return gate((d) {
      final me = aInt(d['me']);
      final iAmMaster = aBool(d['master']);
      final hasSec = aBool(d['has_security']);
      final admins = aList(d['admins']);
      final sections = [for (final x in aList(d['sections'])) aMap(x)];

      return RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('🛡️ Admin team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const AdminMuted('The master admin adds admins, approves them and chooses what each one can see.'),
            const SizedBox(height: 14),
            for (final a in admins) _adminCard(a, me, iAmMaster, hasSec, sections),
            AdminCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🔒 Security password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const AdminMuted('A second password, different from your sign-in password. It protects editing your account and adding or approving admins.'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AdminButton(hasSec ? 'Change security password' : 'Set security password', small: true, onPressed: () => _setSecurity(hasSec)),
                      if (iAmMaster) AdminButton('➕ Add admin', small: true, kind: 'gray', onPressed: () => hasSec ? _addAdmin(sections) : _setSecurity(false)),
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
