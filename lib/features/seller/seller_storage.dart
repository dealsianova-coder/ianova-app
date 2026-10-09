import 'package:shared_preferences/shared_preferences.dart';

import 'seller_models.dart';

class SellerStorage {
  SellerStorage._();

  static const _tokenKey = 'ianova_seller_token';
  static const _nameKey = 'ianova_seller_name';
  static const _emailKey = 'ianova_seller_email';
  static const _statusKey = 'ianova_seller_status';

  static Future<void> save(SellerSession session) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_nameKey, session.businessName);
    await prefs.setString(_emailKey, session.email);
    await prefs.setString(_statusKey, session.status);
  }

  static Future<SellerSession?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    return SellerSession(
      token: token,
      businessName: prefs.getString(_nameKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
      status: prefs.getString(_statusKey) ?? 'pending',
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_statusKey);
  }
}
