import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_service.dart';

/// One extra color of a product (own photo, stock and optional price).
class ExtraColorRow {
  final color = TextEditingController();
  final stock = TextEditingController(text: '0');
  final price = TextEditingController();
  String? imagePath;

  void dispose() {
    color.dispose();
    stock.dispose();
    price.dispose();
  }
}

/// Holds what the seller picked in the "More photos" and "More colors" blocks.
class SellerExtrasController extends ChangeNotifier {
  final List<String> newPhotos = [];
  final List<Map<String, dynamic>> existing = [];
  final Set<int> removeIds = {};
  final List<ExtraColorRow> colors = [];

  bool get hasChanges =>
      newPhotos.isNotEmpty ||
      removeIds.isNotEmpty ||
      colors.any((c) => c.color.text.trim().isNotEmpty);

  void changed() => notifyListeners();

  Future<void> loadExisting(String token, int productId) async {
    try {
      final r = await http
          .get(
            Uri.parse(
              '${IanovaApiConfig.baseUrl}/api/seller_product_extras.php?id=$productId',
            ),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));
      final data = jsonDecode(r.body);
      if (data is Map && data['gallery'] is List) {
        existing
          ..clear()
          ..addAll(
            (data['gallery'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e)),
          );
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Sends the extras for a saved product. Throws SellerApplyException on failure.
  Future<void> upload(String token, int productId) async {
    if (!hasChanges) return;

    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${IanovaApiConfig.baseUrl}/api/seller_product_extras.php'),
    );
    req.headers['Authorization'] = 'Bearer $token';
    req.headers['Accept'] = 'application/json';
    req.fields['id'] = '$productId';

    var n = 0;
    for (final id in removeIds) {
      req.fields['del_img[$n]'] = '$id';
      n++;
    }
    for (final path in newPhotos) {
      req.files.add(await http.MultipartFile.fromPath('gallery[]', path));
    }

    var i = 0;
    for (final c in colors) {
      if (c.color.text.trim().isEmpty) continue;
      req.fields['opt_color[$i]'] = c.color.text.trim();
      req.fields['opt_stock[$i]'] = c.stock.text.trim();
      req.fields['opt_price[$i]'] = c.price.text.trim();
      if (c.imagePath != null) {
        req.files.add(
          await http.MultipartFile.fromPath('opt_image[$i]', c.imagePath!),
        );
      }
      i++;
    }

    final http.Response res;
    try {
      res = await http.Response.fromStream(
        await req.send().timeout(const Duration(seconds: 120)),
      );
    } catch (_) {
      throw const SellerApplyException(
        'Product saved, but the extra photos or colors could not be sent. Edit the product to try again.',
      );
    }

    Map<String, dynamic> data = {};
    try {
      final d = jsonDecode(res.body);
      if (d is Map) data = Map<String, dynamic>.from(d);
    } catch (_) {}

    if (res.statusCode == 401) {
      throw SellerApplyException(
        data['error']?.toString() ?? 'Please sign in again.',
        sessionExpired: true,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || data['success'] != true) {
      throw SellerApplyException(
        data['error']?.toString() ?? 'Could not save the extra photos or colors.',
      );
    }
  }

  @override
  void dispose() {
    for (final c in colors) {
      c.dispose();
    }
    super.dispose();
  }
}

class SellerExtrasSection extends StatelessWidget {
  const SellerExtrasSection({super.key, required this.controller});

  final SellerExtrasController controller;

  Future<void> _pickPhotos(BuildContext context) async {
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (files.isNotEmpty) {
        controller.newPhotos.addAll(files.map((f) => f.path));
        controller.changed();
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your photos.')),
      );
    }
  }

  Future<void> _pickColorPhoto(BuildContext context, ExtraColorRow row) async {
    try {
      final f = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (f != null) {
        row.imagePath = f.path;
        controller.changed();
      }
    } catch (_) {}
  }

  Widget _thumb(Widget child, VoidCallback onRemove, {bool faded = false}) {
    return Stack(
      children: [
        Opacity(
          opacity: faded ? 0.35 : 1,
          child: Container(
            width: 72,
            height: 72,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: IanovaColors.border,
              borderRadius: BorderRadius.circular(10),
            ),
            child: child,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: Icon(
                faded ? Icons.undo : Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'More photos',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Front, back, sides. Pick several at once.',
              style: TextStyle(fontSize: 12, color: IanovaColors.muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in controller.existing)
                  _thumb(
                    Image.network(
                      IanovaApiConfig.imageUrl('${g['image']}'),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined),
                    ),
                    () {
                      final id = (g['id'] as num).toInt();
                      if (!controller.removeIds.remove(id)) {
                        controller.removeIds.add(id);
                      }
                      controller.changed();
                    },
                    faded: controller.removeIds.contains((g['id'] as num).toInt()),
                  ),
                for (final path in controller.newPhotos)
                  _thumb(Image.file(File(path), fit: BoxFit.cover), () {
                    controller.newPhotos.remove(path);
                    controller.changed();
                  }),
                InkWell(
                  onTap: () => _pickPhotos(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(color: IanovaColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: IanovaSpacing.xl),
            const Text(
              'More colors of this product',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Customers swipe between colors. Each color has its own photo and '
              'stock. Leave price empty to use the main price. The Color field '
              'above is the first color.',
              style: TextStyle(fontSize: 12, color: IanovaColors.muted),
            ),
            for (final row in controller.colors)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: IanovaColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.color,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Color'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: row.stock,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Stock'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: row.price,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price (optional)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        row.imagePath == null
                            ? OutlinedButton.icon(
                                onPressed: () => _pickColorPhoto(context, row),
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: const Text('Photo'),
                              )
                            : _thumb(
                                Image.file(File(row.imagePath!), fit: BoxFit.cover),
                                () {
                                  row.imagePath = null;
                                  controller.changed();
                                },
                              ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          controller.colors.remove(row);
                          row.dispose();
                          controller.changed();
                        },
                        child: const Text('Remove color'),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                controller.colors.add(ExtraColorRow());
                controller.changed();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add another color'),
            ),
          ],
        );
      },
    );
  }
}
