import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../../core/storage/auth_storage.dart';
import 'auth_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    String? baseUrl,
    http.Client? client,
  })  : _baseUrl = baseUrl ?? IanovaApiConfig.baseUrl,
        _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/login.php'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        data['error']?.toString() ?? 'Unable to sign in.',
      );
    }

    if (data['success'] != true) {
      throw AuthException(
        data['error']?.toString() ?? 'Unable to sign in.',
      );
    }

    final token = data['token']?.toString() ?? '';
    final rawUser = data['user'];

    if (token.isEmpty || rawUser is! Map) {
      throw const AuthException('Invalid login response.');
    }

    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(rawUser),
    );

    await AuthStorage.saveSession(
      token: token,
      user: user,
    );

    return user;
  }

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/register.php'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    final data = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        data['error']?.toString() ?? 'Unable to create your account.',
      );
    }

    if (data['success'] != true) {
      throw AuthException(
        data['error']?.toString() ?? 'Unable to create your account.',
      );
    }

    final token = data['token']?.toString() ?? '';
    final rawUser = data['user'];

    if (token.isEmpty || rawUser is! Map) {
      throw const AuthException('Invalid registration response.');
    }

    final user = AuthUser.fromJson(
      Map<String, dynamic>.from(rawUser),
    );

    await AuthStorage.saveSession(
      token: token,
      user: user,
    );

    return user;
  }

  Future<String?> getToken() {
    return AuthStorage.getToken();
  }

  Future<AuthUser?> getCurrentUser() {
    return AuthStorage.getUser();
  }

  Future<void> logout() {
    return AuthStorage.clearSession();
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw const AuthException('Invalid server response.');
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Invalid server response.');
    }
  }

  void dispose() {
    _client.close();
  }
}
