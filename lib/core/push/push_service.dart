import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

/// Phone notifications (Firebase). Safe by design: if Firebase is not set up or the
/// phone blocks notifications, the app simply carries on without them.
///
/// Three kinds of sign-in can exist in one app, each stored by its own screen:
///   app (customer) | seller | admin.
/// [sync] tells the server this phone's token for every kind that is signed in;
/// [unregister] removes it when that person signs out.
class PushService {
  PushService._();

  static bool _ready = false;
  static bool _listening = false;

  static const Map<String, String> _tokenKeys = {
    'app': 'ianova_auth_token',
    'seller': 'ianova_seller_token',
    'admin': 'admin_token',
  };

  static Future<bool> _init() async {
    if (_ready) return true;
    try {
      await Firebase.initializeApp();
      _ready = true;
      if (!_listening) {
        _listening = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((_) => sync());
      }
      return true;
    } catch (e) {
      debugPrint('Push not available: $e');
      return false;
    }
  }

  /// Call once at app start.
  static Future<void> start() async {
    if (!await _init()) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (_) {}
    await sync();
  }

  static Future<void> _post(String bearer, Map<String, dynamic> body) async {
    await http
        .post(
          Uri.parse('${IanovaApiConfig.baseUrl}/api/push_register.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $bearer',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 6));
  }

  /// Register this phone for everyone who is signed in right now.
  static Future<void> sync() async {
    try {
      if (!await _init()) return;
      final fcm = await FirebaseMessaging.instance.getToken();
      if (fcm == null || fcm.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      for (final e in _tokenKeys.entries) {
        final t = prefs.getString(e.value);
        if (t == null || t.isEmpty) continue;
        try {
          await _post(t, {'kind': e.key, 'token': fcm, 'platform': 'android'});
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Stop notifications for [kind] on this phone. Call BEFORE the sign-in token is erased.
  static Future<void> unregister(String kind) async {
    try {
      if (!await _init()) return;
      final fcm = await FirebaseMessaging.instance.getToken();
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(_tokenKeys[kind] ?? '');
      if (fcm == null || t == null || t.isEmpty) return;
      await _post(t, {'kind': kind, 'token': fcm, 'remove': true});
    } catch (_) {}
  }
}
