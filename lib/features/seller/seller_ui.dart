import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/ianova_spacing.dart';
import '../../core/theme/ianova_theme.dart';
import 'seller_service.dart';

/// Runs a seller API call. Shows the error as a snackbar, signs the seller out
/// if the session expired, and returns null on any failure.
Future<T?> runSeller<T>({
  required BuildContext context,
  required VoidCallback onExpired,
  required Future<T> Function() action,
  bool silent = false,
}) async {
  try {
    return await action();
  } on SellerApplyException catch (error) {
    if (!context.mounted) return null;

    if (error.sessionExpired) {
      onExpired();
      return null;
    }

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  } catch (_) {
    if (!context.mounted) return null;

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  return null;
}

class SellerPill extends StatelessWidget {
  const SellerPill(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  static Color forStatus(String status) {
    switch (status) {
      case 'approved':
      case 'delivered':
      case 'paid':
      case 'shipped':
        return IanovaColors.success;
      case 'rejected':
      case 'cancelled':
      case 'suspended':
        return IanovaColors.danger;
      default:
        return IanovaColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String sellerLabel(String status) {
  if (status.isEmpty) return '';

  return status[0].toUpperCase() + status.substring(1);
}

BoxDecoration sellerCardDecoration([Color? color]) {
  return BoxDecoration(
    color: color ?? Colors.white,
    borderRadius: BorderRadius.circular(IanovaSpacing.radiusLarge),
    border: color == null ? Border.all(color: IanovaColors.border) : null,
  );
}

Color sellerHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  final value = clean.length == 6 ? int.tryParse(clean, radix: 16) : null;

  return value == null ? const Color(0xFFEFF3EC) : Color(0xFF000000 | value);
}

/// Product photo, or the emoji on a coloured tile when there is no photo.
class SellerThumb extends StatelessWidget {
  const SellerThumb({
    super.key,
    required this.image,
    required this.emoji,
    required this.bgColor,
    this.size = 52,
  });

  final String image;
  final String emoji;
  final String bgColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        emoji.isEmpty ? '📦' : emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sellerHex(bgColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: image.isEmpty
          ? fallback
          : Image.network(
              IanovaApiConfig.imageUrl(image),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
