import 'package:flutter/material.dart';

import 'seller_account_tab.dart';
import 'seller_inbox_view.dart';
import 'seller_models.dart';
import 'seller_orders_tab.dart';
import 'seller_overview_tab.dart';
import 'seller_products_tab.dart';
import 'seller_service.dart';

/// The seller's own admin: shown once the application is approved.
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
  int _index = 0;

  Widget _tab() {
    switch (_index) {
      case 0:
        return SellerOverviewTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
        );
      case 1:
        return SellerProductsTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
        );
      case 2:
        return SellerOrdersTab(
          session: widget.session,
          service: widget.service,
          onExpired: widget.onExpired,
        );
      case 3:
        return SellerInboxView(
          session: widget.session,
          service: widget.service,
          onStatus: widget.onStatus,
          onExpired: widget.onExpired,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: KeyedSubtree(key: ValueKey(_index), child: _tab())),
        NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ],
    );
  }
}
