import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'seller_models.dart';

class SellerApplyException implements Exception {
  const SellerApplyException(this.message, {this.sessionExpired = false});

  final String message;
  final bool sessionExpired;

  @override
  String toString() => message;
}

class SellerService {
  SellerService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? IanovaApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final http.Response response;

    try {
      response = method == 'GET'
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

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    if (response.statusCode == 401 && token != null) {
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

  SellerSession _sessionFrom(Map<String, dynamic> data) {
    final seller = Map<String, dynamic>.from(data['seller'] as Map);

    return SellerSession(
      token: data['token']?.toString() ?? '',
      businessName: seller['business_name']?.toString() ?? '',
      email: seller['email']?.toString() ?? '',
      status: seller['status']?.toString() ?? 'pending',
    );
  }

  Future<SellerSession> apply({
    required String businessName,
    required String email,
    required String phone,
    required String description,
    required String password,
  }) async {
    final data = await _send(
      'POST',
      'seller_apply.php',
      body: {
        'business_name': businessName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'business_description': description.trim(),
        'password': password,
      },
    );

    return _sessionFrom(data);
  }

  Future<SellerSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _send(
      'POST',
      'seller_login.php',
      body: {'email': email.trim(), 'password': password},
    );

    return _sessionFrom(data);
  }

  SellerThread _threadFrom(Map<String, dynamic> data) {
    final seller = Map<String, dynamic>.from(data['seller'] as Map);
    final raw = (data['messages'] as List?) ?? const [];

    return SellerThread(
      businessName: seller['business_name']?.toString() ?? '',
      status: seller['status']?.toString() ?? 'pending',
      messages: raw
          .whereType<Map>()
          .map((m) => SellerMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  Future<SellerThread> fetchThread(String token) async {
    final data = await _send('GET', 'seller_thread.php', token: token);

    return _threadFrom(data);
  }

  Future<SellerThread> sendMessage(String token, String message) async {
    final data = await _send(
      'POST',
      'seller_thread.php',
      body: {'message': message.trim()},
      token: token,
    );

    return _threadFrom(data);
  }

  // ---- Seller admin: products, orders, sales, account ----------------------

  SellerCatalog _catalogFrom(Map<String, dynamic> data) {
    final products = (data['products'] as List?) ?? const [];
    final categories = (data['categories'] as List?) ?? const [];

    return SellerCatalog(
      autoApprove: data['auto_approve'] == true,
      products: products
          .whereType<Map>()
          .map((p) => SellerProduct.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      categories: categories.whereType<Map>().map((c) {
        return SellerCategory(
          id: int.tryParse(c['id']?.toString() ?? '') ?? 0,
          name: c['name']?.toString() ?? '',
        );
      }).toList(),
    );
  }

  Future<SellerCatalog> fetchCatalog(String token) async {
    return _catalogFrom(await _send('GET', 'seller_products.php', token: token));
  }

  Future<SellerCatalog> saveProduct(
    String token, {
    int? id,
    required String name,
    required int categoryId,
    required double price,
    double? originalPrice,
    required int stock,
    required String description,
    required String subcategory,
    required String color,
    required String size,
    required String emoji,
    required String bgColor,
    required bool isFlashDeal,
    String? imagePath,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/seller_products.php'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll({
      'action': 'save',
      if (id != null) 'id': '$id',
      'name': name.trim(),
      'category_id': '$categoryId',
      'price': '$price',
      'original_price': originalPrice == null ? '' : '$originalPrice',
      'stock': '$stock',
      'description': description.trim(),
      'subcategory': subcategory.trim(),
      'color': color.trim(),
      'size': size.trim(),
      'emoji': emoji.trim(),
      'bg_color': bgColor,
      'is_flash_deal': isFlashDeal ? '1' : '0',
    });

    if (imagePath != null) {
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final http.Response response;

    try {
      response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 90)),
      );
    } catch (_) {
      throw const SellerApplyException(
        'Could not reach the server. Check your connection and try again.',
      );
    }

    Map<String, dynamic> data = {};

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
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
        data['error']?.toString() ?? 'Could not save the product.',
      );
    }

    return _catalogFrom(data);
  }

  Future<SellerCatalog> setStock(String token, int id, int stock) async {
    return _catalogFrom(
      await _send(
        'POST',
        'seller_products.php',
        token: token,
        body: {'action': 'stock', 'id': id, 'stock': stock},
      ),
    );
  }

  Future<SellerCatalog> deleteProduct(String token, int id) async {
    return _catalogFrom(
      await _send(
        'POST',
        'seller_products.php',
        token: token,
        body: {'action': 'delete', 'id': id},
      ),
    );
  }

  Future<List<SellerOrder>> fetchOrders(String token) async {
    final data = await _send('GET', 'seller_orders.php', token: token);
    final raw = (data['orders'] as List?) ?? const [];

    return raw
        .whereType<Map>()
        .map((o) => SellerOrder.fromJson(Map<String, dynamic>.from(o)))
        .toList();
  }

  Future<SellerSummary> fetchSummary(String token) async {
    return SellerSummary.fromJson(
      await _send('GET', 'seller_summary.php', token: token),
    );
  }

  Future<SellerProfile> fetchProfile(String token) async {
    return SellerProfile.fromJson(
      await _send('GET', 'seller_account.php', token: token),
    );
  }

  Future<SellerProfile> saveProfile(
    String token, {
    required String businessName,
    required String phone,
    required String description,
  }) async {
    return SellerProfile.fromJson(
      await _send(
        'POST',
        'seller_account.php',
        token: token,
        body: {
          'action': 'profile',
          'business_name': businessName.trim(),
          'phone': phone.trim(),
          'business_description': description.trim(),
        },
      ),
    );
  }

  Future<void> changePassword(
    String token, {
    required String current,
    required String next,
  }) async {
    await _send(
      'POST',
      'seller_account.php',
      token: token,
      body: {
        'action': 'password',
        'current_password': current,
        'new_password': next,
      },
    );
  }

  void dispose() {
    _client.close();
  }
}
