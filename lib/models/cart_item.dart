import 'product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    required this.itemTotal,
  });

  final Product product;
  final int quantity;
  final double itemTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      itemTotal: double.tryParse(
            json['item_total'].toString(),
          ) ??
          0,
    );
  }

  int get productId => product.id;
}
