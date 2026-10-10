import 'package:flutter/material.dart';

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
