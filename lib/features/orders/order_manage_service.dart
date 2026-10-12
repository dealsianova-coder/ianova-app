import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/storage/auth_storage.dart';

class OrderManageException implements Exception {
  const OrderManageException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lets a customer cancel or edit an order that is still pending.
class OrderManageService {
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const OrderManageException('Please sign in again.');
    }

    final http.Response response;

    try {
      response = await http.post(
        Uri.parse('${IanovaApiConfig.baseUrl}/api/$path'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const OrderManageException(
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

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw OrderManageException(
        data['error']?.toString() ?? 'Something went wrong. Please try again.',
      );
    }

    return data;
  }

  Future<void> cancel(int orderId) async {
    await _post('order_cancel.php', {'id': orderId});
  }

  /// Returns true when removing every item cancelled the order.
  Future<bool> update(
    int orderId, {
    required String phone,
    required String address,
    required Map<int, int> quantities,
  }) async {
    final data = await _post('order_update.php', {
      'id': orderId,
      'phone': phone.trim(),
      'address': address.trim(),
      'items': [
        for (final entry in quantities.entries)
          {'id': entry.key, 'quantity': entry.value},
      ],
    });

    return data['cancelled'] == true;
  }
}
