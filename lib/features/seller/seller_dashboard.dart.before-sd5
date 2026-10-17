import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/ianova_theme.dart';
import 'seller_account_tab.dart';
import 'seller_auto_tab.dart';
import 'seller_home_tab.dart';
import 'seller_inbox_view.dart';
import 'seller_models.dart';
import 'seller_orders_tab.dart';
import 'seller_panel_ui.dart';
import 'seller_products_tab.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

/// The seller's own admin. Same menu and pages as the website's seller site.
class SellerDashboard extends StatefulWidget {
  const SellerDashboard({
    super.key,
    required this.session,
    required this.service,
    required this.onStatus,
    required this.onExpired,
    required this.onSignOut,
  });

  final SellerSession session;
  final SellerService service;
  final ValueChanged<String> onStatus;
  final VoidCallback onExpired;
  final VoidCallback onSignOut;

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  static const _titles = [
    'Dashboard',
    'Products',
    'Orders',
    'Messages',
    'Order approval',
    'Account',
  ];

  int _index = 0;
  bool _openAdd = false;
  String _productFilter = 'all';
  PanelDashboard? _dash;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _loadDash();
    _poll = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadDash(silent: true),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _loadDash({bool silent = false}) async {
    final dash = await runSeller<PanelDashboard>(
      context: context,
      onExpired: widget.onExpired,
      silent: silent,
      action: () => widget.service.fetchDashboard(widget.session.token),
    );

    if (!mounted || dash == null) return;

    setState(() => _dash = dash);
    widget.onStatus(dash.status);
  }

  void _go(int index, {String productFilter = 'all'}) {
    setState(() {
      _index = index;
      _productFilter = productFilter;
    });
    _loadDash(silent: true);
  }

  Widget _tab() {
    switch (_index) {
      case 0:
        return SellerHomeTab(
          dash: _dash,
          onGo: _go,
          onRefresh: _loadDash,
          onToggleAuto: (on) async {
            try {
              await widget.service.setPanelAuto(widget.session.token, on);
              await _loadDash();
            } catch (_) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not change it. Please try again.')),
              );
            }
          },
        );
      case 1:
        final openAdd = _openAdd;

        _openAdd = false;

        return SellerProductsTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
          openAddOnLoad: openAdd,
          initialFilter: _productFilter,
          onChanged: () => _loadDash(silent: true),
        );
      case 2:
        return SellerOrdersTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
          onChanged: () => _loadDash(silent: true),
        );
      case 3:
        return SellerInboxView(
          session: widget.session,
          service: widget.service,
          onStatus: widget.onStatus,
          onExpired: widget.onExpired,
        );
      case 4:
        return SellerAutoTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
          dash: _dash,
          onChanged: _loadDash,
        );
      default:
        return SellerAccountTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
          onSignOut: widget.onSignOut,
        );
    }
  }

  Widget _pill(
    String label, {
    required VoidCallback onTap,
    bool active = false,
    int badge = 0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? IanovaColors.primary : IanovaColors.soft,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: active ? Colors.white : IanovaColors.secondary,
                  ),
                ),
                NBadge(badge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _dash;
    final status = d?.status.isNotEmpty == true ? d!.status : widget.session.status;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titles[_index],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${widget.session.businessName} · ${sellerLabel(status)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: IanovaColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: IanovaColors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _pill('Dashboard', active: _index == 0, onTap: () => _go(0)),
                _pill(
                  'Products',
                  active: _index == 1,
                  badge: d?.locked ?? 0,
                  onTap: () => _go(1),
                ),
                _pill(
                  'Orders',
                  active: _index == 2,
                  badge: d?.pendingOrders ?? 0,
                  onTap: () => _go(2),
                ),
                _pill(
                  'Messages',
                  active: _index == 3,
                  badge: d?.unread ?? 0,
                  onTap: () => _go(3),
                ),
                _pill('Order approval', active: _index == 4, onTap: () => _go(4)),
                _pill(
                  '+ Add product',
                  onTap: () {
                    _openAdd = true;
                    _go(1);
                  },
                ),
                _pill('Account', active: _index == 5, onTap: () => _go(5)),
                _pill('Sign out', onTap: widget.onSignOut),
              ],
            ),
          ),
        ),
        Expanded(child: KeyedSubtree(key: ValueKey(_index), child: _tab())),
      ],
    );
  }
}
