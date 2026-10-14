import 'package:flutter/material.dart';

import '../../core/theme/ianova_theme.dart';
import 'seller_models.dart';
import 'seller_panel_ui.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

/// "Order approval" page: switch automatic approval on or off.
class SellerAutoTab extends StatefulWidget {
  const SellerAutoTab({
    super.key,
    required this.session,
    required this.service,
    required this.onExpired,
    required this.dash,
    required this.onChanged,
  });

  final SellerSession session;
  final SellerService service;
  final VoidCallback onExpired;
  final PanelDashboard? dash;
  final Future<void> Function() onChanged;

  @override
  State<SellerAutoTab> createState() => _SellerAutoTabState();
}

class _SellerAutoTabState extends State<SellerAutoTab> {
  bool _saving = false;

  Future<void> _set(bool enabled) async {
    setState(() => _saving = true);

    final data = await runSeller<PanelOrdersData>(
      context: context,
      onExpired: widget.onExpired,
      action: () =>
          widget.service.setPanelAuto(widget.session.token, enabled),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (data != null) {
      await widget.onChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dash;

    if (d == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PanelBlock(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Automatic approval: ',
                  children: [
                    TextSpan(
                      text: d.autoOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: d.autoOn
                            ? const Color(0xFF0B6B37)
                            : const Color(0xFFB00F2F),
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                !d.autoMaster
                    ? 'IANOVA has switched automatic approval off for everyone, so you approve orders by hand.'
                    : d.autoMine
                        ? 'When your products are in stock, new orders are approved automatically and you get a message.'
                        : 'Automatic approval is off for you. You approve each order by hand from the Orders page.',
                style: const TextStyle(color: IanovaColors.secondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: _saving ? null : () => _set(!d.autoMine),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      d.autoMine ? const Color(0xFFB00F2F) : IanovaColors.primary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  _saving
                      ? 'Saving...'
                      : d.autoMine
                          ? 'Turn automatic approval off'
                          : 'Turn automatic approval on',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
