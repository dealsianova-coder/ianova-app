import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/network/api_service.dart';

/// A category's picture, or its emoji when no picture has been uploaded.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    required this.size,
    required this.fontSize,
    this.radius,
  });

  final Category category;
  final double size;
  final double fontSize;

  /// Corner radius of the picture; null makes it a circle.
  final double? radius;

  Widget _emoji() {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(category.emoji, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = category.image.trim();

    if (image.isEmpty) return _emoji();

    final picture = Image.network(
      IanovaApiConfig.imageUrl(image),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _emoji(),
    );

    if (radius == null) return ClipOval(child: picture);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius!),
      child: picture,
    );
  }
}
