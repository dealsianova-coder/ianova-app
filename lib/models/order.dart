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
    this.discount = 0,
    this.couponCode = '',
    this.paid = 0,
    this.balance = 0,
    this.depositDue = 0,
    this.payPlan = 'full',
    this.payState = '',
    this.payInstructions = '',
    this.trackingCourier = '',
    this.trackingNo = '',
    this.trackingNote = '',
    this.timeline = const [],
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
  final double discount;
  final String couponCode;
  final double paid;
  final double balance;
  final double depositDue;
  final String payPlan;
  final String payState;
  final String payInstructions;
  final String trackingCourier;
  final String trackingNo;
  final String trackingNote;
  final List<Map<String, String>> timeline;

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
      discount: double.tryParse('${json['discount']}') ?? 0,
      couponCode: json['coupon_code']?.toString() ?? '',
      paid: double.tryParse('${json['paid']}') ?? 0,
      balance: double.tryParse('${json['balance']}') ?? 0,
      depositDue: double.tryParse('${json['deposit_due']}') ?? 0,
      payPlan: json['pay_plan']?.toString() ?? 'full',
      payState: json['pay_state']?.toString() ?? '',
      payInstructions: json['pay_instructions']?.toString() ?? '',
      trackingCourier: json['tracking_courier']?.toString() ?? '',
      trackingNo: json['tracking_no']?.toString() ?? '',
      trackingNote: json['tracking_note']?.toString() ?? '',
      timeline: json['timeline'] is List
          ? (json['timeline'] as List)
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
              .toList()
          : const [],
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
    this.itemStatus = '',
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
  final String itemStatus; // '', packed, shipped, delivered

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
      itemStatus: json['item_status']?.toString() ?? '',
    );
  }
}
