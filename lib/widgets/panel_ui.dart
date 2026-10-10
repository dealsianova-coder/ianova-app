import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_service.dart';
import '../core/theme/ianova_theme.dart';

/// Looks up product photos from the public catalogue so seller and admin
/// screens can show pictures even when their own API has none.
class PhotoLookup {
  PhotoLookup._();

  static Map<int, String>? _byId;
  static Map<String, String> _byName = {};

  static Future<void> ensureLoaded() async {
    if (_byId != null) return;

    final api = ApiService();

    try {
      final products = await api.getProducts();
      final ids = <int, String>{};
      final names = <String, String>{};

      for (final p in products) {
        final photo = p.photos.isEmpty ? '' : p.photos.first;

        if (photo.isEmpty) continue;
        ids[p.id] = photo;
        names.putIfAbsent(p.name.trim().toLowerCase(), () => photo);
      }

      _byId = ids;
      _byName = names;
    } catch (_) {
      // Leave unloaded so the next screen can retry.
    } finally {
      api.dispose();
    }
  }

  static String forProduct({int? id, String name = '', String own = ''}) {
    if (own.trim().isNotEmpty) return own;
    if (id != null && (_byId?[id] ?? '').isNotEmpty) return _byId![id]!;

    return _byName[name.trim().toLowerCase()] ?? '';
  }
}

/// Square photo block with rounded corners and a tidy placeholder.
class ImageBlock extends StatelessWidget {
  const ImageBlock({
    super.key,
    required this.url,
    this.size,
    this.radius = 16,
  });

  final String url;
  final double? size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final full = IanovaApiConfig.imageUrl(url);

    final placeholder = Container(
      color: IanovaColors.soft,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: IanovaColors.muted,
        size: (size ?? 64) * 0.4,
      ),
    );

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: full.isEmpty
          ? placeholder
          : Image.network(
              full,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : placeholder,
            ),
    );

    if (size != null) return SizedBox(width: size, height: size, child: image);

    return AspectRatio(aspectRatio: 1, child: image);
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.color, {super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  const InfoChip(this.label, {super.key, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: IanovaColors.soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: IanovaColors.secondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: IanovaColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays children out as a tidy two-column grid with natural heights.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({super.key, required this.children, this.gap = 12});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

BoxDecoration panelDecoration({Color? color}) => BoxDecoration(
      color: color ?? IanovaColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: IanovaColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F0F12),
          blurRadius: 14,
          offset: Offset(0, 6),
        ),
      ],
    );
