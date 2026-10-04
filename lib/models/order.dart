class Order {
  const Order({
    required this.id,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.address,
    required this.total,
    required this.status,
    required this.createdAt,
    this.subtotal,
    this.delivery,
    this.items = const [],
  });

  final int id;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String address;
  final double total;
  final String status;
  final String createdAt;
  final double? subtotal;
  final double? delivery;
  final List<OrderItem> items;

  bool get hasItems => items.isNotEmpty;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];

    return Order(
      id: int.tryParse(json['id'].toString()) ?? 0,
      guestName: json['guest_name']?.toString() ?? '',
      guestEmail: json['guest_email']?.toString() ?? '',
      guestPhone: json['guest_phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      total: double.tryParse(json['total'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      subtotal: json.containsKey('subtotal')
          ? double.tryParse(json['subtotal'].toString())
          : null,
      delivery: json.containsKey('delivery')
          ? double.tryParse(json['delivery'].toString())
          : null,
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => OrderItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.name,
    required this.slug,
    required this.image,
    required this.variantColor,
    required this.variantSize,
    required this.variantSku,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotal,
  });

  final int id;
  final int productId;
  final int? variantId;
  final String name;
  final String slug;
  final String image;
  final String? variantColor;
  final String? variantSize;
  final String? variantSku;
  final int quantity;
  final double unitPrice;
  final double itemTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      productId: int.tryParse(json['product_id'].toString()) ?? 0,
      variantId: json['variant_id'] == null
          ? null
          : int.tryParse(json['variant_id'].toString()),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      variantColor: json['variant_color']?.toString(),
      variantSize: json['variant_size']?.toString(),
      variantSku: json['variant_sku']?.toString(),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0,
      itemTotal: double.tryParse(json['item_total'].toString()) ?? 0,
    );
  }
}
