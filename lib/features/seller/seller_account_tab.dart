import 'package:flutter/material.dart';

import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

class SellerAccountTab extends StatefulWidget {
  const SellerAccountTab({
    super.key,
    required this.session,
    required this.service,
    required this.onExpired,
    required this.onSignOut,
  });

  final SellerSession session;
  final SellerService service;
  final VoidCallback onExpired;
  final VoidCallback onSignOut;

  @override
  State<SellerAccountTab> createState() => _SellerAccountTabState();
}

class _SellerAccountTabState extends State<SellerAccountTab> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _about = TextEditingController();
  final _current = TextEditingController();
  final _next = TextEditingController();

  SellerProfile? _profile;
  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _about.dispose();
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  void _fill(SellerProfile p) {
    _profile = p;
    _name.text = p.businessName;
    _phone.text = p.phone;
    _about.text = p.description;
  }

  Future<void> _load() async {
    final profile = await runSeller<SellerProfile>(
      context: context,
      onExpired: widget.onExpired,
      action: () => widget.service.fetchProfile(widget.session.token),
    );

    if (!mounted || profile == null) return;

    setState(() => _fill(profile));
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveProfile() async {
    if (_name.text.trim().isEmpty) {
      _toast('Enter your business name.');
      return;
    }

    setState(() => _savingProfile = true);

    final profile = await runSeller<SellerProfile>(
      context: context,
      onExpired: widget.onExpired,
      action: () => widget.service.saveProfile(
        widget.session.token,
        businessName: _name.text,
        phone: _phone.text,
        description: _about.text,
      ),
    );

    if (!mounted) return;

    setState(() {
      _savingProfile = false;

      if (profile != null) _fill(profile);
    });

    if (profile != null) _toast('Details saved.');
  }

  Future<void> _changePassword() async {
    if (_current.text.isEmpty || _next.text.length < 6) {
      _toast('Enter your current password and a new one (6+ characters).');
      return;
    }

    setState(() => _savingPassword = true);

    final done = await runSeller<bool>(
      context: context,
      onExpired: widget.onExpired,
      action: () async {
        await widget.service.changePassword(
          widget.session.token,
          current: _current.text,
          next: _next.text,
        );

        return true;
      },
    );

    if (!mounted) return;

    setState(() => _savingPassword = false);

    if (done == true) {
      _current.clear();
      _next.clear();
      _toast('Password changed. Other devices were signed out.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return ListView(
      padding: const EdgeInsets.all(IanovaSpacing.xl),
      children: [
        Container(
          padding: const EdgeInsets.all(IanovaSpacing.lg),
          decoration: sellerCardDecoration(IanovaColors.soft),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  profile?.email ?? widget.session.email,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SellerPill(
                sellerLabel(profile?.status ?? widget.session.status),
                color: SellerPill.forStatus(
                  profile?.status ?? widget.session.status,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: IanovaSpacing.xl),
        const Text(
          'Business details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Business name'),
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone'),
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextField(
          controller: _about,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'About your business'),
        ),
        const SizedBox(height: IanovaSpacing.sm),
        FilledButton(
          onPressed: _savingProfile ? null : _saveProfile,
          style: FilledButton.styleFrom(
            backgroundColor: IanovaColors.primary,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(_savingProfile ? 'Saving...' : 'Save details'),
        ),
        const SizedBox(height: IanovaSpacing.xxl),
        const Text(
          'Change password',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current password'),
        ),
        const SizedBox(height: IanovaSpacing.md),
        TextField(
          controller: _next,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        const SizedBox(height: IanovaSpacing.md),
        OutlinedButton(
          onPressed: _savingPassword ? null : _changePassword,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(_savingPassword ? 'Updating...' : 'Update password'),
        ),
        const SizedBox(height: IanovaSpacing.xxl),
        TextButton.icon(
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
