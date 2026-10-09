import 'package:flutter/material.dart';

import '../../core/theme/ianova_theme.dart';
import 'seller_forms.dart';
import 'seller_inbox_view.dart';
import 'seller_models.dart';
import 'seller_service.dart';
import 'seller_storage.dart';

/// Entry point of the "Sell on IANOVA" section: apply, sign in, and the
/// conversation with the IANOVA team.
class SellerHubPage extends StatefulWidget {
  const SellerHubPage({super.key});

  @override
  State<SellerHubPage> createState() => _SellerHubPageState();
}

class _SellerHubPageState extends State<SellerHubPage> {
  final _service = SellerService();

  SellerSession? _session;
  bool _isRestoring = true;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final session = await SellerStorage.load();

    if (!mounted) return;

    setState(() {
      _session = session;
      _isRestoring = false;
    });
  }

  Future<void> _onSession(SellerSession session) async {
    await SellerStorage.save(session);

    if (!mounted) return;

    setState(() => _session = session);
  }

  Future<void> _onStatus(String status) async {
    final current = _session;

    if (current == null || current.status == status) {
      return;
    }

    final updated = current.copyWith(status: status);

    await SellerStorage.save(updated);

    if (!mounted) return;

    setState(() => _session = updated);
  }

  Future<void> _signOut() async {
    await SellerStorage.clear();

    if (!mounted) return;

    setState(() => _session = null);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign in again any time with your seller email and password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      backgroundColor: IanovaColors.background,
      appBar: AppBar(
        title: const Text(
          'Sell on IANOVA',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (session != null)
            IconButton(
              tooltip: 'Sign out',
              onPressed: _confirmSignOut,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _isRestoring
            ? const Center(child: CircularProgressIndicator())
            : session == null
                ? DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: IanovaColors.primary,
                          unselectedLabelColor: IanovaColors.muted,
                          indicatorColor: IanovaColors.primary,
                          labelStyle: TextStyle(fontWeight: FontWeight.w800),
                          tabs: [
                            Tab(text: 'Apply'),
                            Tab(text: 'Sign in'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              SellerApplyForm(
                                service: _service,
                                onSession: _onSession,
                              ),
                              SellerLoginForm(
                                service: _service,
                                onSession: _onSession,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : SellerInboxView(
                    session: session,
                    service: _service,
                    onStatus: _onStatus,
                    onExpired: _signOut,
                  ),
      ),
    );
  }
}
