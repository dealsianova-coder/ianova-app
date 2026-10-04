import 'package:flutter/foundation.dart';

import '../network/api_service.dart';

/// Tracks which products are in the signed-in user's wishlist so every heart
/// icon in the app stays in sync.
class WishlistController extends ChangeNotifier {
  WishlistController._();

  static final WishlistController instance = WishlistController._();

  final ApiService _api = ApiService();
  final Set<int> _ids = <int>{};

  bool contains(int productId) => _ids.contains(productId);

  /// Loads the wishlist from the server. Signed-out users get an empty set.
  Future<void> load() async {
    try {
      final products = await _api.getWishlist();
      _ids
        ..clear()
        ..addAll(products.map((product) => product.id));
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        _ids.clear();
      }
    } catch (_) {
      // Keep the last known state when the server cannot be reached.
    }

    notifyListeners();
  }

  /// Forgets everything, used when the user signs out.
  void clear() {
    _ids.clear();
    notifyListeners();
  }

  /// Adds or removes a product. Returns an error message, or null on success.
  Future<String?> toggle(int productId) async {
    final wasSaved = _ids.contains(productId);

    // Update the heart straight away, then undo it if the server refuses.
    if (wasSaved) {
      _ids.remove(productId);
    } else {
      _ids.add(productId);
    }
    notifyListeners();

    try {
      if (wasSaved) {
        await _api.removeFromWishlist(productId);
      } else {
        await _api.addToWishlist(productId);
      }
      return null;
    } on ApiException catch (error) {
      _revert(productId, wasSaved);
      return error.statusCode == 401
          ? 'Please sign in to save favorites.'
          : error.message;
    } catch (_) {
      _revert(productId, wasSaved);
      return 'Unable to update your wishlist.';
    }
  }

  void _revert(int productId, bool wasSaved) {
    if (wasSaved) {
      _ids.add(productId);
    } else {
      _ids.remove(productId);
    }
    notifyListeners();
  }
}
