import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;

  void _showThemePicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Appearance',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ThemeOption(
                title: 'System default',
                icon: Icons.brightness_auto_outlined,
                selected: _themeMode == ThemeMode.system,
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.system;
                  });
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                title: 'Light',
                icon: Icons.light_mode_outlined,
                selected: _themeMode == ThemeMode.light,
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.light;
                  });
                  Navigator.pop(context);
                },
              ),
              _ThemeOption(
                title: 'Dark',
                icon: Icons.dark_mode_outlined,
                selected: _themeMode == ThemeMode.dark,
                onTap: () {
                  setState(() {
                    _themeMode = ThemeMode.dark;
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showInformation({
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeLabel = switch (_themeMode) {
      ThemeMode.system => 'System default',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionTitle(title: 'Preferences'),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text(
              'Receive updates about orders and your account.',
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: Text(themeLabel),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showThemePicker,
          ),
          const Divider(height: 32),
          const _SectionTitle(title: 'Information'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showInformation(
                title: 'Privacy',
                body:
                    'IANOVA uses your account information to provide shopping, '
                    'orders, delivery, and account services. Your information '
                    'should be handled according to IANOVA’s applicable privacy '
                    'practices and policies.',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showInformation(
                title: 'Terms',
                body:
                    'By using IANOVA, you agree to use the service lawfully '
                    'and to provide accurate information for your account, '
                    'orders, and delivery.',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About IANOVA'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              _showInformation(
                title: 'About IANOVA',
                body:
                    'IANOVA is a shopping platform designed to make product '
                    'discovery, purchasing, delivery, and order management '
                    'simple and convenient.',
              );
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'IANOVA',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'App settings',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
