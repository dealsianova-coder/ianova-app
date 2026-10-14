import 'package:flutter/material.dart';

import '../../core/theme/ianova_theme.dart';

// Colours and shapes copied from the website's seller/admin theme.
const _okBg = Color(0xFFE7F6EC);
const _okFg = Color(0xFF0B6B37);
const _warnBg = Color(0xFFFFF1D6);
const _warnFg = Color(0xFF9A5B00);
const _badBg = Color(0xFFFDE7EB);
const _badFg = Color(0xFFB00F2F);

/// White block with a thin border, like the website's .blk.
class PanelBlock extends StatelessWidget {
  const PanelBlock({
    super.key,
    required this.child,
    this.color,
    this.borderColor,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? IanovaColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F0F12),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Status pill: kind is ok, warn or bad.
class SPill extends StatelessWidget {
  const SPill(this.text, this.kind, {super.key});

  final String text;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final bg = kind == 'ok' ? _okBg : kind == 'bad' ? _badBg : _warnBg;
    final fg = kind == 'ok' ? _okFg : kind == 'bad' ? _badFg : _warnFg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

/// Red count badge.
class NBadge extends StatelessWidget {
  const NBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      constraints: const BoxConstraints(minWidth: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5173F),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String orderPillKind(String status, bool approved) {
  if (approved) return 'ok';
  if (status == 'cancelled') return 'bad';

  return 'warn';
}

String orderPillText(String status, bool approved) {
  if (approved) return 'Approved';
  if (status == 'cancelled') return 'Cancelled';

  return 'Waiting for you';
}
