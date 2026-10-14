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
    required this.bgColor,
    required this.isFlashDeal,
    required this.image,
    required this.subcategory,
    required this.color,
    required this.size,
    this.categoryName = '',
    this.locked = false,
  });

  final String categoryName;
  final bool locked;
  final int id;
  final String name;
  final int categoryId;
  final double price;
  final double? originalPrice;
  final int stock;
  final String status;
  final String description;
  final String emoji;
  final String bgColor;
  final bool isFlashDeal;
  final String image;
  final String subcategory;
  final String color;
  final String size;

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
      bgColor: j['bg_color']?.toString() ?? '#EFF3EC',
      isFlashDeal: _asInt(j['is_flash_deal']) == 1,
      image: j['image']?.toString() ?? '',
      subcategory: j['subcategory']?.toString() ?? '',
      color: j['color']?.toString() ?? '',
      size: j['size']?.toString() ?? '',
      categoryName: j['category_name']?.toString() ?? '',
      locked: j['locked'] == true,
    );
  }
}

class SellerCatalog {
  const SellerCatalog({
    required this.products,
    required this.categories,
    this.autoApprove = false,
  });

  final List<SellerProduct> products;
  final List<SellerCategory> categories;
  final bool autoApprove;
}

class SellerOrderItem {
  const SellerOrderItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.status,
    required this.image,
    required this.emoji,
    required this.bgColor,
  });

  final String name;
  final int quantity;
  final double unitPrice;
  final String status;
  final String image;
  final String emoji;
  final String bgColor;
}

class SellerOrder {
  const SellerOrder({
    required this.id,
    required this.customer,
    required this.phone,
    required this.address,
    required this.status,
    required this.sellerStatus,
    required this.createdAt,
    required this.subtotal,
    required this.items,
  });

  final int id;
  final String customer;
  final String phone;
  final String address;
  final String status;
  final String sellerStatus;
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
      sellerStatus: j['seller_status']?.toString() ?? 'approved',
      createdAt: j['created_at']?.toString() ?? '',
      subtotal: _asDouble(j['subtotal']),
      items: raw.whereType<Map>().map((i) {
        return SellerOrderItem(
          name: i['name']?.toString() ?? '',
          quantity: _asInt(i['quantity']),
          unitPrice: _asDouble(i['unit_price']),
          status: i['status']?.toString() ?? 'pending',
          image: i['image']?.toString() ?? '',
          emoji: i['emoji']?.toString() ?? '',
          bgColor: i['bg_color']?.toString() ?? '#EFF3EC',
        );
      }).toList(),
    );
  }
}

class SellerOrdersData {
  const SellerOrdersData({
    required this.orders,
    required this.autoApprove,
    required this.pending,
  });

  final List<SellerOrder> orders;
  final bool autoApprove;
  final int pending;
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
    this.pendingOrders = 0,
  });

  final SellerSales allTime;
  final SellerSales last30;
  final SellerSales last7;
  final int approved;
  final int pending;
  final int rejected;
  final int lowStock;
  final List<SellerTopProduct> top;
  final int pendingOrders;

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
      pendingOrders: _asInt(j['pending_orders']),
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


// ---- Website-style seller panel -------------------------------------------

class PanelPhoto {
  const PanelPhoto({
    required this.image,
    required this.emoji,
    required this.bgColor,
  });

  final String image;
  final String emoji;
  final String bgColor;

  factory PanelPhoto.fromJson(Map<String, dynamic> j) => PanelPhoto(
        image: j['image']?.toString() ?? '',
        emoji: j['emoji']?.toString() ?? '',
        bgColor: j['bg_color']?.toString() ?? '#EFF3EC',
      );
}

class PanelLine {
  const PanelLine({
    required this.name,
    required this.option,
    required this.quantity,
    required this.lineTotal,
    required this.photo,
  });

  final String name;
  final String option;
  final int quantity;
  final double lineTotal;
  final PanelPhoto photo;
}

class PanelOrder {
  const PanelOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.customer,
    required this.phone,
    required this.address,
    required this.total,
    required this.approved,
    required this.canApprove,
    required this.note,
    required this.items,
  });

  final int id;
  final String createdAt;
  final String status;
  final String customer;
  final String phone;
  final String address;
  final double total;
  final bool approved;
  final bool canApprove;
  final String note;
  final List<PanelLine> items;

  bool get waiting => !approved && status != 'cancelled';

  factory PanelOrder.fromJson(Map<String, dynamic> j) {
    final raw = (j['items'] as List?) ?? const [];

    return PanelOrder(
      id: _asInt(j['id']),
      createdAt: j['created_at']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      customer: j['customer']?.toString() ?? '',
      phone: j['phone']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      total: _asDouble(j['total']),
      approved: j['approved'] == true,
      canApprove: j['can_approve'] == true,
      note: j['note']?.toString() ?? '',
      items: raw.whereType<Map>().map((i) {
        final m = Map<String, dynamic>.from(i);

        return PanelLine(
          name: m['name']?.toString() ?? '',
          option: m['option']?.toString() ?? '',
          quantity: _asInt(m['quantity']),
          lineTotal: _asDouble(m['line_total']),
          photo: PanelPhoto.fromJson(m),
        );
      }).toList(),
    );
  }
}

class PanelOrdersData {
  const PanelOrdersData({
    required this.orders,
    required this.autoMaster,
    required this.autoMine,
  });

  final List<PanelOrder> orders;
  final bool autoMaster;
  final bool autoMine;

  bool get autoOn => autoMaster && autoMine;
}

class PanelRecent {
  const PanelRecent({
    required this.id,
    required this.customer,
    required this.status,
    required this.createdAt,
    required this.mine,
    required this.approved,
    required this.photos,
    required this.more,
  });

  final int id;
  final String customer;
  final String status;
  final String createdAt;
  final double mine;
  final bool approved;
  final List<PanelPhoto> photos;
  final int more;
}

class PanelDashboard {
  const PanelDashboard({
    required this.status,
    required this.products,
    required this.orders,
    required this.lowStock,
    required this.revenue,
    required this.pendingProducts,
    required this.pendingOrders,
    required this.unread,
    required this.locked,
    required this.autoMaster,
    required this.autoMine,
    required this.recent,
  });

  final String status;
  final int products;
  final int orders;
  final int lowStock;
  final double revenue;
  final int pendingProducts;
  final int pendingOrders;
  final int unread;
  final int locked;
  final bool autoMaster;
  final bool autoMine;
  final List<PanelRecent> recent;

  bool get autoOn => autoMaster && autoMine;

  factory PanelDashboard.fromJson(Map<String, dynamic> j) {
    final raw = (j['recent'] as List?) ?? const [];

    return PanelDashboard(
      status: j['status']?.toString() ?? '',
      products: _asInt(j['products']),
      orders: _asInt(j['orders']),
      lowStock: _asInt(j['low_stock']),
      revenue: _asDouble(j['revenue']),
      pendingProducts: _asInt(j['pending_products']),
      pendingOrders: _asInt(j['pending_orders']),
      unread: _asInt(j['unread_messages']),
      locked: _asInt(j['locked_products']),
      autoMaster: j['auto_master'] == true,
      autoMine: j['auto_mine'] == true,
      recent: raw.whereType<Map>().map((r) {
        final m = Map<String, dynamic>.from(r);
        final photos = (m['photos'] as List?) ?? const [];

        return PanelRecent(
          id: _asInt(m['id']),
          customer: m['customer']?.toString() ?? '',
          status: m['status']?.toString() ?? '',
          createdAt: m['created_at']?.toString() ?? '',
          mine: _asDouble(m['mine']),
          approved: m['approved'] == true,
          photos: photos
              .whereType<Map>()
              .map((x) => PanelPhoto.fromJson(Map<String, dynamic>.from(x)))
              .toList(),
          more: _asInt(m['more']),
        );
      }).toList(),
    );
  }
}
