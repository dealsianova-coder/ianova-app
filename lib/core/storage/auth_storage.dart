import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/auth_user.dart';

class AuthStorage {
  AuthStorage._();

  static const _tokenKey = 'ianova_auth_token';
  static const _userIdKey = 'ianova_auth_user_id';
  static const _userNameKey = 'ianova_auth_user_name';
  static const _userEmailKey = 'ianova_auth_user_email';

  static Future<void> saveSession({
    required String token,
    required AuthUser user,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, user.id);
    await prefs.setString(_userNameKey, user.name);
    await prefs.setString(_userEmailKey, user.email);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<AuthUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final id = prefs.getInt(_userIdKey);
    final name = prefs.getString(_userNameKey);
    final email = prefs.getString(_userEmailKey);

    if (id == null || name == null || email == null) {
      return null;
    }

    return AuthUser(
      id: id,
      name: name,
      email: email,
    );
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}
