import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';

class SellerApplyException implements Exception {
  const SellerApplyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SellerService {
  SellerService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? IanovaApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<String> apply({
    required String businessName,
    required String email,
    required String phone,
    required String description,
    required String password,
  }) async {
    final http.Response response;

    try {
      response = await _client.post(
        Uri.parse('$_baseUrl/api/seller_apply.php'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'business_name': businessName.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'business_description': description.trim(),
          'password': password,
        }),
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

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] != true) {
      throw SellerApplyException(
        data['error']?.toString() ?? 'Unable to send your application.',
      );
    }

    return data['message']?.toString() ??
        'Application received. We will review it and get back to you.';
  }

  void dispose() {
    _client.close();
  }
}
