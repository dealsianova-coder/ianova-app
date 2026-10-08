import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/auth_storage.dart';

import '../../models/product.dart';
import '../../models/cart.dart';
import '../../models/product_detail.dart';
import '../../models/user_address.dart';
import '../../models/checkout_result.dart';
import '../../models/order.dart';
import '../../models/store_config.dart';
import '../../models/store_settings.dart';

class ApiService {
  ApiService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? IanovaApiConfig.baseUrl;

  final http.Client _client;
  final String baseUrl;


  Future<List<Product>> getProducts({int? categoryId}) async {
    final uri = Uri.parse('$baseUrl/api/products.php').replace(
      queryParameters:
          categoryId == null ? null : {'category': categoryId.toString()},
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load products.',
        statusCode: response.statusCode,
      );
    }

    final data = _decode(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load products.',
      );
    }

    final products = data['products'];

    if (products is! List) {
      throw const ApiException('Invalid products response.');
    }

    return products
        .whereType<Map>()
        .map(
          (item) => Product.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Product> getProduct(int productId) async {
    if (productId < 1) {
      throw const ApiException('Invalid product ID.');
    }

    final uri = Uri.parse('$baseUrl/api/product.php').replace(
      queryParameters: {'id': productId.toString()},
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load product.',
        statusCode: response.statusCode,
      );
    }

    final data = _decode(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load product.',
      );
    }

    final product = data['product'];

    if (product is! Map) {
      throw const ApiException('Invalid product response.');
    }

    return Product.fromJson(
      Map<String, dynamic>.from(product),
    );
  }

  Future<ProductDetail> getProductDetail(int productId) async {
    if (productId < 1) {
      throw const ApiException('Invalid product ID.');
    }

    final uri = Uri.parse('$baseUrl/api/product.php').replace(
      queryParameters: {'id': productId.toString()},
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load product.',
        statusCode: response.statusCode,
      );
    }

    final data = _decode(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load product.',
      );
    }

    return ProductDetail.fromJson(data);
  }

  Future<StoreConfig> getStoreConfig() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/store.php'),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load store config.',
        statusCode: response.statusCode,
      );
    }

    final data = _decode(response.body);

    if (data['success'] != true || data['store'] is! Map) {
      throw ApiException('Unable to load store config.');
    }

    return StoreConfig.fromJson(
      Map<String, dynamic>.from(data['store'] as Map),
    );
  }

  Future<StoreSettings> getStoreSettings() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/api/settings.php'),
    );

    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load store settings.',
        statusCode: response.statusCode,
      );
    }

    final data = _decode(response.body);

    if (data['success'] != true || data['settings'] is! Map) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load store settings.',
      );
    }

    return StoreSettings.fromJson(
      Map<String, dynamic>.from(data['settings'] as Map),
    );
  }

  Future<Cart> getCart() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to view your cart.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/cart.php');

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load cart.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load cart.',
        statusCode: response.statusCode,
      );
    }

    return Cart.fromJson(data);
  }


  Future<List<Order>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to view your orders.',
        statusCode: 401,
      );
    }

    if (page < 1 || limit < 1) {
      throw const ApiException('Invalid orders pagination.');
    }

    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final cleanStatus = status?.trim() ?? '';
    if (cleanStatus.isNotEmpty) {
      query['status'] = cleanStatus;
    }

    final uri = Uri.parse('$baseUrl/api/orders.php').replace(
      queryParameters: query,
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load orders.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load orders.',
        statusCode: response.statusCode,
      );
    }

    final orders = data['orders'];

    if (orders is! List) {
      throw const ApiException('Invalid orders response.');
    }

    return orders
        .whereType<Map>()
        .map(
          (item) => Order.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<Order> getOrder(int orderId) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to view this order.',
        statusCode: 401,
      );
    }

    if (orderId < 1) {
      throw const ApiException('Invalid order ID.');
    }

    final uri = Uri.parse('$baseUrl/api/order.php').replace(
      queryParameters: {
        'id': orderId.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load order.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load order.',
        statusCode: response.statusCode,
      );
    }

    final rawOrder = data['order'];

    if (rawOrder is! Map) {
      throw const ApiException('Invalid order response.');
    }

    final orderJson = Map<String, dynamic>.from(rawOrder);
    orderJson['items'] = data['items'];

    return Order.fromJson(orderJson);
  }


  Future<List<Product>> getWishlist() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to view your wishlist.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/wishlist.php');

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load wishlist.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load wishlist.',
        statusCode: response.statusCode,
      );
    }

    final products = data['products'];

    if (products is! List) {
      throw const ApiException('Invalid wishlist response.');
    }

    return products
        .whereType<Map>()
        .map(
          (item) => Product.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> addToWishlist(int productId) async {
    await _updateWishlist(
      productId: productId,
      method: 'POST',
    );
  }

  Future<void> removeFromWishlist(int productId) async {
    await _updateWishlist(
      productId: productId,
      method: 'DELETE',
    );
  }

  Future<void> _updateWishlist({
    required int productId,
    required String method,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to update your wishlist.',
        statusCode: 401,
      );
    }

    if (productId < 1) {
      throw const ApiException('Invalid product ID.');
    }

    final uri = Uri.parse('$baseUrl/api/wishlist_update.php');

    final request = http.Request(
      method,
      uri,
    )
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..body = jsonEncode({
        'product_id': productId,
      });

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to update wishlist.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to update wishlist.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> addToCart({
    required int productId,
    int quantity = 1,
  }) async {
    if (productId < 1) {
      throw const ApiException('Invalid product ID.');
    }

    if (quantity < 1) {
      throw const ApiException('Quantity must be at least 1.');
    }

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in before adding products to your cart.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/cart_update.php');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to add product to cart.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to add product to cart.',
        statusCode: response.statusCode,
      );
    }
  }


  Future<void> updateCartItem({
    required int productId,
    required int quantity,
  }) async {
    if (productId < 1) {
      throw const ApiException('Invalid product ID.');
    }

    if (quantity < 1) {
      throw const ApiException('Quantity must be at least 1.');
    }

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to update your cart.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/cart_update.php');

    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to update cart.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to update cart.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> removeFromCart({
    required int productId,
  }) async {
    if (productId < 1) {
      throw const ApiException('Invalid product ID.');
    }

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to update your cart.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/cart_update.php');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'product_id': productId,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to remove product from cart.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to remove product from cart.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<List<Category>> getCategories() async {
    final uri = Uri.parse('$baseUrl/api/categories.php');

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw ApiException(
        'Unable to load categories.',
        statusCode: response.statusCode,
      );
    }

    final data = _decode(response.body);

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load categories.',
      );
    }

    final categories = data['categories'];

    if (categories is! List) {
      throw const ApiException('Invalid categories response.');
    }

    return categories
        .whereType<Map>()
        .map(
          (item) => Category.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }


  Future<List<UserAddress>> getAddresses() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to view your addresses.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/addresses.php');

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load addresses.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to load addresses.',
        statusCode: response.statusCode,
      );
    }

    final addresses = data['addresses'];

    if (addresses is! List) {
      throw const ApiException('Invalid addresses response.');
    }

    return addresses
        .whereType<Map>()
        .map(
          (item) => UserAddress.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<UserAddress> addAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    bool isDefault = false,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to add an address.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/addresses.php');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'label': label.trim(),
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'is_default': isDefault,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to add address.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to add address.',
        statusCode: response.statusCode,
      );
    }

    final rawAddress = data['address'];

    if (rawAddress is! Map) {
      throw const ApiException('Invalid address response.');
    }

    return UserAddress.fromJson(
      Map<String, dynamic>.from(rawAddress),
    );
  }

  Future<UserAddress> updateAddress({
    required int id,
    required String label,
    required String recipientName,
    required String phone,
    required String address,
    bool isDefault = false,
  }) async {
    if (id < 1) {
      throw const ApiException('Invalid address ID.');
    }

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to update an address.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/addresses.php');

    final response = await _client.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': id,
        'label': label.trim(),
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'is_default': isDefault,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to update address.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to update address.',
        statusCode: response.statusCode,
      );
    }

    final rawAddress = data['address'];

    if (rawAddress is! Map) {
      throw const ApiException('Invalid address response.');
    }

    return UserAddress.fromJson(
      Map<String, dynamic>.from(rawAddress),
    );
  }

  Future<void> deleteAddress({
    required int id,
  }) async {
    if (id < 1) {
      throw const ApiException('Invalid address ID.');
    }

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in to delete an address.',
        statusCode: 401,
      );
    }

    final uri = Uri.parse('$baseUrl/api/addresses.php');

    final response = await _client.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': id,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to delete address.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to delete address.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<CheckoutResult> checkout({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Please sign in before checking out.',
        statusCode: 401,
      );
    }

    final cleanName = name.trim();
    final cleanEmail = email.trim();
    final cleanPhone = phone.trim();
    final cleanAddress = address.trim();

    if (cleanName.isEmpty ||
        cleanEmail.isEmpty ||
        cleanPhone.isEmpty ||
        cleanAddress.isEmpty) {
      throw const ApiException(
        'Name, email, phone and address are required.',
      );
    }

    final uri = Uri.parse('$baseUrl/api/checkout.php');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': cleanName,
        'email': cleanEmail,
        'phone': cleanPhone,
        'address': cleanAddress,
      }),
    );

    final data = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to place order.',
        statusCode: response.statusCode,
      );
    }

    if (data['success'] != true) {
      throw ApiException(
        data['error']?.toString() ?? 'Unable to place order.',
        statusCode: response.statusCode,
      );
    }

    final order = data['order'];

    if (order is! Map) {
      throw const ApiException('Invalid checkout response.');
    }

    return CheckoutResult.fromJson(
      Map<String, dynamic>.from(order),
    );
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is! Map) {
        throw const FormatException('Expected JSON object.');
      }

      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      debugPrint('IANOVA API JSON error: $error');
      throw const ApiException('The server returned invalid data.');
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.emoji,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String slug;
  final String emoji;
  final int sortOrder;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      emoji: json['emoji']?.toString() ?? '',
      sortOrder: int.tryParse(json['sort_order'].toString()) ?? 0,
    );
  }
}
