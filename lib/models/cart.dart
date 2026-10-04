import 'cart_item.dart';

class Cart {
  const Cart({
    required this.items,
    required this.itemCount,
    required this.subtotal,
  });

  final List<CartItem> items;
  final int itemCount;
  final double subtotal;

  factory Cart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => CartItem.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <CartItem>[];

    return Cart(
      items: items,
      itemCount: int.tryParse(json['item_count'].toString()) ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0,
    );
  }

  bool get isEmpty => items.isEmpty;
}
