import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'seller_service.dart' show SellerApplyException;

class SellerSummary {
  const SellerSummary({
    required this.status,
    required this.unreadMessages,
    required this.pendingOrders,
    required this.lockedProducts,
  });

  static const empty = SellerSummary(
    status: '',
    unreadMessages: 0,
    pendingOrders: 0,
    lockedProducts: 0,
  );

  final String status;
  final int unreadMessages;
  final int pendingOrders;
  final int lockedProducts;

  int get total => unreadMessages + pendingOrders + lockedProducts;

  bool get restricted => status == 'suspended' || status == 'rejected';
}

class SellerProduct {
  const SellerProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.status,
    required this.option,
    required this.locked,
  });

  final int id;
  final String name;
  final double price;
  final int stock;
  final String status;
  final String option;
  final bool locked;

  factory SellerProduct.fromJson(Map<String, dynamic> json) {
    final color = json['color']?.toString() ?? '';
    final size = json['size']?.toString() ?? '';

    return SellerProduct(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      price: double.tryParse('${json['price']}') ?? 0,
      stock: int.tryParse('${json['stock']}') ?? 0,
      status: json['status']?.toString() ?? '',
      option: [color, size].where((v) => v.isNotEmpty).join(' · '),
      locked: json['locked'] == true,
    );
  }
}

class SellerOrderLine {
  const SellerOrderLine({
    required this.name,
    required this.option,
    required this.quantity,
    required this.lineTotal,
  });

  final String name;
  final String option;
  final int quantity;
  final double lineTotal;
}

class SellerOrder {
  const SellerOrder({
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
    required this.lines,
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
  final List<SellerOrderLine> lines;

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    final raw = (json['items'] as List?) ?? const [];

    return SellerOrder(
      id: int.tryParse('${json['id']}') ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      customer: json['customer']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      total: double.tryParse('${json['total']}') ?? 0,
      approved: json['approved'] == true,
      canApprove: json['can_approve'] == true,
      note: json['note']?.toString() ?? '',
      lines: raw.whereType<Map>().map((m) {
        final item = Map<String, dynamic>.from(m);

        return SellerOrderLine(
          name: item['name']?.toString() ?? '',
          option: item['option']?.toString() ?? '',
          quantity: int.tryParse('${item['quantity']}') ?? 1,
          lineTotal: double.tryParse('${item['line_total']}') ?? 0,
        );
      }).toList(),
    );
  }
}

/// Seller badges, products with restrictions, orders and approval.
class SellerOpsService {
  SellerOpsService() : _client = http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> _call(
    String token,
    String action, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${IanovaApiConfig.baseUrl}/api/seller_ops.php')
        .replace(queryParameters: {'action': action});
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final http.Response response;

    try {
      response = body == null
          ? await _client.get(uri, headers: headers)
          : await _client.post(uri, headers: headers, body: jsonEncode(body));
    } catch (_) {
      throw const SellerApplyException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (response.statusCode == 401) {
      throw SellerApplyException(
        data['error']?.toString() ?? 'Please sign in again.',
        sessionExpired: true,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw SellerApplyException(
        data['error']?.toString() ?? 'Something went wrong. Please try again.',
      );
    }

    return data;
  }

  Future<SellerSummary> summary(String token) async {
    final data = await _call(token, 'summary');

    return SellerSummary(
      status: data['status']?.toString() ?? '',
      unreadMessages: int.tryParse('${data['unread_messages']}') ?? 0,
      pendingOrders: int.tryParse('${data['pending_orders']}') ?? 0,
      lockedProducts: int.tryParse('${data['locked_products']}') ?? 0,
    );
  }

  Future<List<SellerProduct>> products(String token) async {
    final data = await _call(token, 'products');

    return ((data['products'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => SellerProduct.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<SellerOrder>> orders(String token) async {
    final data = await _call(token, 'orders');

    return ((data['orders'] as List?) ?? const [])
        .whereType<Map>()
        .map((m) => SellerOrder.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<String> approve(String token, int orderId) async {
    final data = await _call(token, 'approve', body: {'order_id': orderId});

    return data['message']?.toString() ?? 'Order approved.';
  }

  Future<String> requestReview(String token, int productId, String note) async {
    final data = await _call(
      token,
      'request_review',
      body: {'product_id': productId, 'note': note},
    );

    return data['message']?.toString() ?? 'Request sent.';
  }

  void dispose() {
    _client.close();
  }
}
