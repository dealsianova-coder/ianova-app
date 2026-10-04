import 'package:flutter/material.dart';

import '../core/config/api_config.dart';

class IanovaProductImage extends StatelessWidget {
  const IanovaProductImage({
    super.key,
    required this.image,
    required this.emoji,
    required this.backgroundColor,
    this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(22),
    ),
  });

  final String image;
  final String emoji;
  final String backgroundColor;
  final double? height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final imageValue = image.trim();

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: _parseColor(backgroundColor),
        borderRadius: borderRadius,
      ),
      child: imageValue.isEmpty
          ? _fallback()
          : _buildImage(imageValue),
    );
  }

  Widget _buildImage(String value) {
    if (_isRemoteImage(value)) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          IanovaApiConfig.imageUrl(value),
          fit: BoxFit.cover,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => _fallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                _fallback(),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        value,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _fallback(),
      ),
    );
  }

  bool _isRemoteImage(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('uploads/') ||
        value.startsWith('/uploads/');
  }

  Widget _fallback() {
    return Center(
      child: Text(
        emoji.isEmpty ? '📦' : emoji,
        style: const TextStyle(fontSize: 60),
      ),
    );
  }

  Color _parseColor(String value) {
    try {
      final cleaned = value.replaceAll('#', '');

      if (cleaned.length != 6) {
        return const Color(0xFFF1F1EE);
      }

      return Color(
        int.parse('FF$cleaned', radix: 16),
      );
    } catch (_) {
      return const Color(0xFFF1F1EE);
    }
  }
}
