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

  void dispose() {
    _client.close();
  }
}
