import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last products the shopper opened, newest first.
class RecentProducts {
  static const _key = 'recent_product_ids';
  static const _max = 12;

  /// Bumps every time the list changes so screens can refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];

    return [
      for (final value in raw)
        if (int.tryParse(value) != null) int.parse(value),
    ];
  }

  static Future<void> add(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key) ?? <String>[]).toList();

    ids.remove('$productId');
    ids.insert(0, '$productId');

    await prefs.setStringList(_key, ids.take(_max).toList());
    changes.value++;
  }
}
