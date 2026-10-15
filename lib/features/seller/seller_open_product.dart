import 'package:flutter/material.dart';

import 'seller_models.dart';
import 'seller_products_tab.dart';
import 'seller_service.dart';
import 'seller_ui.dart';

/// Opens one of the seller's products (the same page as Products > tap a product)
/// from anywhere, for example from a line of an order. Matches by name and color/size.
Future<void> openSellerProduct({
  required BuildContext context,
  required SellerSession session,
  required SellerService service,
  required VoidCallback onExpired,
  required String name,
  String option = '',
  VoidCallback? onChanged,
}) async {
  final catalog = await runSeller<SellerCatalog>(
    context: context,
    onExpired: onExpired,
    action: () => service.fetchCatalog(session.token),
  );

  if (catalog == null || !context.mounted) return;

  final same = catalog.products
      .where((p) => p.name.trim().toLowerCase() == name.trim().toLowerCase())
      .toList();

  if (same.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This product is no longer in your list.')),
    );
    return;
  }

  final wanted = option.trim().toLowerCase();
  var product = same.first;

  for (final p in same) {
    if ('${p.color} ${p.size}'.trim().toLowerCase() == wanted) {
      product = p;
      break;
    }
  }

  final result = await Navigator.of(context).push<SellerCatalog>(
    MaterialPageRoute(
      builder: (_) => SellerProductFormPage(
        session: session,
        service: service,
        categories: catalog.categories,
        product: product,
        onExpired: onExpired,
      ),
    ),
  );

  if (result != null) onChanged?.call();
}
