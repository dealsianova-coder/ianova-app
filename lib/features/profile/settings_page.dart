import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/api_config.dart';
import '../../core/storage/auth_storage.dart';
import '../../core/theme/ianova_theme.dart';
import '../auth/auth_user.dart';

const _supportEmail = 'dealsianova@gmail.com';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifyOrders = true;
  bool _notifyDeals = true;
  ThemeMode _themeMode = ThemeMode.system;
  AuthUser? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthStorage.getUser();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _user = user;
      _notifyOrders = prefs.getBool('set_notify_orders') ?? true;
      _notifyDeals = prefs.getBool('set_notify_deals') ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showThemePicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Appearance', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            for (final o in const [
              (ThemeMode.system, 'System default', Icons.brightness_auto_outlined),
              (ThemeMode.light, 'Light', Icons.light_mode_outlined),
              (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
            ])
              ListTile(
                leading: Icon(o.$3),
                title: Text(o.$2),
                trailing: _themeMode == o.$1
                    ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _themeMode = o.$1);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _info(String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _contact() async {
    final uri = Uri(scheme: 'mailto', path: _supportEmail, query: 'subject=IANOVA support');
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write to $_supportEmail')),
      );
    }
  }

  Future<void> _changePassword() async {
    final done = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeLabel = switch (_themeMode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    final user = _user;

    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Image.network(
                IanovaApiConfig.imageUrl('assets/img/ianova-wordmark.png'),
                height: 30,
                errorBuilder: (_, __, ___) => const Text(
                  'IANOVA',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.4),
                ),
              ),
            ),
          ),
          if (user != null)
            _Block(
              title: 'Account',
              children: [
                _Row(
                  icon: Icons.person_outline_rounded,
                  title: user.name,
                  subtitle: user.email,
                ),
                _Row(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  subtitle: 'Use a strong password you do not use elsewhere.',
                  onTap: _changePassword,
                ),
              ],
            ),
          _Block(
            title: 'Notifications',
            children: [
              _Switch(
                icon: Icons.local_shipping_outlined,
                title: 'Order updates',
                subtitle: 'Approved, shipped and delivered.',
                value: _notifyOrders,
                onChanged: (v) {
                  setState(() => _notifyOrders = v);
                  _saveBool('set_notify_orders', v);
                },
              ),
              _Switch(
                icon: Icons.bolt_outlined,
                title: 'Flash deals and offers',
                subtitle: 'Hear about sales as they start.',
                value: _notifyDeals,
                onChanged: (v) {
                  setState(() => _notifyDeals = v);
                  _saveBool('set_notify_deals', v);
                },
              ),
            ],
          ),
          _Block(
            title: 'Preferences',
            children: [
              _Row(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle: themeLabel,
                onTap: _showThemePicker,
              ),
            ],
          ),
          _Block(
            title: 'Help',
            children: [
              _Row(
                icon: Icons.support_agent_rounded,
                title: 'Contact IANOVA',
                subtitle: _supportEmail,
                onTap: _contact,
              ),
            ],
          ),
          _Block(
            title: 'Information',
            children: [
              _Row(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                onTap: () => _info(
                  'Privacy',
                  'IANOVA uses your account information to provide shopping, orders, '
                      'delivery, and account services. Your information is handled '
                      'according to IANOVA’s applicable privacy practices and policies.',
                ),
              ),
              _Row(
                icon: Icons.description_outlined,
                title: 'Terms',
                onTap: () => _info(
                  'Terms',
                  'By using IANOVA, you agree to use the service lawfully and to '
                      'provide accurate information for your account, orders, and delivery.',
                ),
              ),
              _Row(
                icon: Icons.info_outline_rounded,
                title: 'About IANOVA',
                onTap: () => _info(
                  'About IANOVA',
                  'IANOVA is a shopping platform designed to make product discovery, '
                      'purchasing, delivery, and order management simple and convenient.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('IANOVA · App settings', style: TextStyle(color: IanovaColors.muted, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: IanovaColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A0F0F12), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: const Color(0xFFF1F3F8), borderRadius: BorderRadius.circular(14)),
      child: Icon(icon, size: 21, color: IanovaColors.primary),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: _IconBox(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      secondary: _IconBox(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = _next.text;
    if (_current.text.isEmpty) return setState(() => _error = 'Enter your current password.');
    if (n.length < 8 || !RegExp(r'[A-Za-z]').hasMatch(n) || !RegExp(r'\d').hasMatch(n)) {
      return setState(() => _error = 'New password: 8+ characters with a letter and a number.');
    }
    if (n != _again.text) return setState(() => _error = 'The two new passwords do not match.');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await AuthStorage.getToken() ?? '';
      final r = await http.post(
        Uri.parse('${IanovaApiConfig.baseUrl}/api/change_password.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'current': _current.text, 'password': n}),
      );
      final d = jsonDecode(r.body);
      if (d is Map && d['success'] == true) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      setState(() => _error = (d is Map ? d['error']?.toString() : null) ?? 'Could not change the password.');
    } catch (_) {
      setState(() => _error = 'No connection. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFB0102F))),
              ),
            TextField(
              controller: _current,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _next,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _again,
              obscureText: true,
              enabled: !_busy,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _busy ? null : _save,
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }
}
