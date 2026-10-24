import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../../core/push/push_service.dart';
import '../../core/network/api_service.dart' show ApiException;

/// Talks to the admin endpoints. Kept apart from the shopper API.
///
/// `admin.php` = login, store settings, alerts, seller chat.
/// `admin_panel.php` = everything else the website admin can do.
class AdminApi {
  AdminApi._();

  static final AdminApi instance = AdminApi._();
  static const _tokenKey = 'admin_token';

  /// Set by the admin shell: called when the server says the session ended.
  static void Function()? expiredHook;

  final http.Client _client = http.Client();

  Future<String?> token() async {
    return (await SharedPreferences.getInstance()).getString(_tokenKey);
  }

  Future<void> signOut() async {
    await PushService.unregister('admin');
    await (await SharedPreferences.getInstance()).remove(_tokenKey);
  }

  List<Map<String, dynamic>> _list(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> data;

    try {
      data = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw const ApiException('Unexpected server response.');
    }

    if (data['success'] != true) {
      if (response.statusCode == 401) {
        await signOut();
        final hook = expiredHook;
        if (hook != null) hook();
      }

      throw ApiException(
        data['error']?.toString() ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  Future<Map<String, dynamic>> _call(
    String action, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
    String file = 'admin.php',
  }) async {
    final uri = Uri.parse('${IanovaApiConfig.baseUrl}/api/$file')
        .replace(queryParameters: {'action': action, ...?query});
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (auth) {
      final saved = await token();
      if (saved != null) headers['Authorization'] = 'Bearer $saved';
    }

    final response = body == null
        ? await _client.get(uri, headers: headers)
        : await _client.post(uri, headers: headers, body: jsonEncode(body));

    return _decode(response);
  }

  Future<void> login(String email, String password) async {
    final data = await _call(
      'login',
      auth: false,
      body: {'email': email, 'password': password},
    );

    await (await SharedPreferences.getInstance())
        .setString(_tokenKey, data['token'].toString());
    PushService.sync();
  }

  Future<List<Map<String, dynamic>>> orders() async {
    return _list((await _call('orders'))['orders']);
  }

  Future<void> setOrderStatus(int id, String status) async {
    await _call('order_status', body: {'id': id, 'status': status});
  }

  Future<List<Map<String, dynamic>>> products(String query) async {
    return _list((await _call('products', query: {'q': query}))['products']);
  }

  Future<void> updateProduct(int id, Map<String, dynamic> fields) async {
    await _call('product_update', body: {'id': id, ...fields});
  }

  Future<Map<String, dynamic>> storeGet() async {
    final data = await _call('store_get');

    return Map<String, dynamic>.from(data['store'] as Map);
  }

  Future<void> storeSet(Map<String, dynamic> values) async {
    await _call('store_set', body: values);
  }

  /// Any `admin.php` action, for alerts and seller chat.
  Future<Map<String, dynamic>> raw(
    String action, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) {
    return _call(action, body: body, query: query);
  }

  /// Any `admin_panel.php` action. Pass [body] to POST, otherwise it is a GET.
  Future<Map<String, dynamic>> panel(
    String action, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) {
    return _call(action, body: body, query: query, file: 'admin_panel.php');
  }

  /// A `admin_panel.php` POST with photos. [files] maps a form field to a file path.
  Future<Map<String, dynamic>> panelUpload(
    String action,
    Map<String, String> fields,
    Map<String, String> files,
  ) async {
    final uri = Uri.parse('${IanovaApiConfig.baseUrl}/api/admin_panel.php')
        .replace(queryParameters: {'action': action});
    final request = http.MultipartRequest('POST', uri);
    final saved = await token();

    if (saved != null) request.headers['Authorization'] = 'Bearer $saved';
    request.headers['Accept'] = 'application/json';
    request.fields.addAll(fields);

    for (final entry in files.entries) {
      request.files.add(
        await http.MultipartFile.fromPath(entry.key, entry.value),
      );
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    return _decode(response);
  }
}
