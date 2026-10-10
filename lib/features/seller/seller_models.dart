class SellerSession {
  const SellerSession({
    required this.token,
    required this.businessName,
    required this.email,
    required this.status,
  });

  final String token;
  final String businessName;
  final String email;
  final String status;

  SellerSession copyWith({String? businessName, String? status}) {
    return SellerSession(
      token: token,
      businessName: businessName ?? this.businessName,
      email: email,
      status: status ?? this.status,
    );
  }
}

class SellerMessage {
  const SellerMessage({
    required this.id,
    required this.fromAdmin,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final bool fromAdmin;
  final String body;
  final DateTime? createdAt;

  factory SellerMessage.fromJson(Map<String, dynamic> json) {
    return SellerMessage(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      fromAdmin: json['sender']?.toString() == 'admin',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        (json['created_at']?.toString() ?? '').replaceFirst(' ', 'T'),
      ),
    );
  }
}

class SellerThread {
  const SellerThread({
    required this.businessName,
    required this.status,
    required this.messages,
  });

  final String businessName;
  final String status;
  final List<SellerMessage> messages;
}

double _asDouble(Object? v) => double.tryParse(v?.toString() ?? '') ?? 0;
int _asInt(Object? v) => int.tryParse(v?.toString() ?? '') ?? 0;

class SellerCategory {
  const SellerCategory({required this.id, required this.name});

  final int id;
  final String name;
}

class SellerProduct {
  const SellerProduct({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.status,
    required this.description,
    required this.emoji,
  });

  final int id;
  final String name;
  final int categoryId;
  final double price;
  final double? originalPrice;
  final int stock;
  final String status;
  final String description;
  final String emoji;

  factory SellerProduct.fromJson(Map<String, dynamic> j) {
    return SellerProduct(
      id: _asInt(j['id']),
      name: j['name']?.toString() ?? '',
      categoryId: _asInt(j['category_id']),
      price: _asDouble(j['price']),
      originalPrice:
          j['original_price'] == null ? null : _asDouble(j['original_price']),
      stock: _asInt(j['stock']),
      status: j['status']?.toString() ?? 'pending',
      description: j['description']?.toString() ?? '',
      emoji: j['emoji']?.toString() ?? '',
    );
  }
}

class SellerCatalog {
  const SellerCatalog({required this.products, required this.categories});

  final List<SellerProduct> products;
  final List<SellerCategory> categories;
}

class SellerOrderItem {
  const SellerOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String name;
  final int quantity;
  final double unitPrice;
}

class SellerOrder {
  const SellerOrder({
    required this.id,
    required this.customer,
    required this.phone,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.subtotal,
    required this.items,
  });

  final int id;
  final String customer;
  final String phone;
  final String address;
  final String status;
  final String createdAt;
  final double subtotal;
  final List<SellerOrderItem> items;

  factory SellerOrder.fromJson(Map<String, dynamic> j) {
    final raw = (j['items'] as List?) ?? const [];

    return SellerOrder(
      id: _asInt(j['id']),
      customer: j['customer']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      createdAt: j['created_at']?.toString() ?? '',
      subtotal: _asDouble(j['subtotal']),
      items: raw.whereType<Map>().map((i) {
        return SellerOrderItem(
          name: i['name']?.toString() ?? '',
          quantity: _asInt(i['quantity']),
          unitPrice: _asDouble(i['unit_price']),
        );
      }).toList(),
    );
  }
}

class SellerSales {
  const SellerSales({
    required this.revenue,
    required this.units,
    required this.orders,
  });

  final double revenue;
  final int units;
  final int orders;

  factory SellerSales.fromJson(Object? raw) {
    final j = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    return SellerSales(
      revenue: _asDouble(j['revenue']),
      units: _asInt(j['units']),
      orders: _asInt(j['orders']),
    );
  }
}

class SellerTopProduct {
  const SellerTopProduct({
    required this.name,
    required this.units,
    required this.revenue,
  });

  final String name;
  final int units;
  final double revenue;
}

class SellerSummary {
  const SellerSummary({
    required this.allTime,
    required this.last30,
    required this.last7,
    required this.approved,
    required this.pending,
    required this.rejected,
    required this.lowStock,
    required this.top,
  });

  final SellerSales allTime;
  final SellerSales last30;
  final SellerSales last7;
  final int approved;
  final int pending;
  final int rejected;
  final int lowStock;
  final List<SellerTopProduct> top;

  factory SellerSummary.fromJson(Map<String, dynamic> j) {
    final products = j['products'] is Map
        ? Map<String, dynamic>.from(j['products'] as Map)
        : <String, dynamic>{};
    final top = (j['top_products'] as List?) ?? const [];

    return SellerSummary(
      allTime: SellerSales.fromJson(j['all_time']),
      last30: SellerSales.fromJson(j['last_30_days']),
      last7: SellerSales.fromJson(j['last_7_days']),
      approved: _asInt(products['approved']),
      pending: _asInt(products['pending']),
      rejected: _asInt(products['rejected']),
      lowStock: _asInt(j['low_stock']),
      top: top.whereType<Map>().map((t) {
        return SellerTopProduct(
          name: t['name']?.toString() ?? '',
          units: _asInt(t['units']),
          revenue: _asDouble(t['revenue']),
        );
      }).toList(),
    );
  }
}

class SellerProfile {
  const SellerProfile({
    required this.businessName,
    required this.email,
    required this.status,
    required this.phone,
    required this.description,
  });

  final String businessName;
  final String email;
  final String status;
  final String phone;
  final String description;

  factory SellerProfile.fromJson(Map<String, dynamic> j) {
    final s = Map<String, dynamic>.from(j['seller'] as Map);

    return SellerProfile(
      businessName: s['business_name']?.toString() ?? '',
      email: s['email']?.toString() ?? '',
      status: s['status']?.toString() ?? '',
      phone: s['phone']?.toString() ?? '',
      description: s['business_description']?.toString() ?? '',
    );
  }
}
