import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/format/money.dart';
import '../../core/network/api_service.dart' show ApiException;
import '../../core/theme/ianova_theme.dart';

/// Colours of the website admin, so the app looks the same.
class AC {
  static const bg = Color(0xFFF5F7F6);
  static const side = Color(0xFF17352C);
  static const side2 = Color(0xFF285445);
  static const ink = Color(0xFF17231E);
  static const muted = Color(0xFF6B7973);
  static const line = Color(0xFFDCE4DF);
  static const line2 = Color(0xFFCCD7D1);
  static const green = Color(0xFF1D6B52);
  static const gold = Color(0xFFB58117);
  static const goldLight = Color(0xFFE9B949);
  static const red = Color(0xFFB83B3B);
  static const gray = Color(0xFF64736D);
  static const soft = Color(0xFFF7F9F8);
  static const warnBg = Color(0xFFFFF3D6);
  static const warnFg = Color(0xFF92600A);
  static const okBg = Color(0xFFE1F3E8);
  static const okFg = Color(0xFF166534);
  static const naBg = Color(0xFFEEF1F0);
  static const naFg = Color(0xFF52615A);
}

ThemeData adminTheme() {
  final base = IanovaTheme.light();

  return base.copyWith(
    scaffoldBackgroundColor: AC.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: AC.green,
      onPrimary: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AC.side,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ---------------------------------------------------------------- JSON helpers

List<Map<String, dynamic>> aList(dynamic raw) {
  if (raw is! List) return <Map<String, dynamic>>[];

  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> aMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);

  return <String, dynamic>{};
}

String aStr(dynamic v) => v == null ? '' : '$v';

int aInt(dynamic v) => int.tryParse('$v') ?? (double.tryParse('$v')?.toInt() ?? 0);

double aNum(dynamic v) => double.tryParse('$v') ?? 0;

bool aBool(dynamic v) => v == true || '$v' == '1' || '$v' == 'true';

String aMoney(dynamic v) => formatKsh(aNum(v));

Color aHex(String value, Color fallback) {
  final text = value.replaceAll('#', '').trim();

  if (text.length != 6 && text.length != 8) return fallback;

  final parsed = int.tryParse(text, radix: 16);

  if (parsed == null) return fallback;

  return Color(text.length == 6 ? 0xFF000000 | parsed : parsed);
}

const Map<String, String> kShowOn = {
  'both': 'Website and app',
  'web': 'Website only',
  'app': 'App only',
};

String adminErr(Object error) {
  if (error is ApiException) return error.message;

  return 'Unable to reach the server.';
}

void adminSay(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Runs an admin call. Returns null (and shows the reason) when it fails.
Future<T?> adminRun<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } on ApiException catch (error) {
    if (context.mounted && error.statusCode != 401) {
      adminSay(context, error.message);
    }
  } catch (_) {
    if (context.mounted) adminSay(context, 'Unable to reach the server.');
  }

  return null;
}

/// Like [adminRun] for calls that return nothing: true when it worked.
Future<bool> adminTry(BuildContext context, Future<void> Function() action) async {
  try {
    await action();

    return true;
  } on ApiException catch (error) {
    if (context.mounted && error.statusCode != 401) {
      adminSay(context, error.message);
    }
  } catch (_) {
    if (context.mounted) adminSay(context, 'Unable to reach the server.');
  }

  return false;
}

Future<bool> adminConfirm(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Yes'),
        ),
      ],
    ),
  );

  return result == true;
}

// ---------------------------------------------------------------- building blocks

class AdminCard extends StatelessWidget {
  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accent,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? accent;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget inner = Padding(padding: padding, child: child);

    if (accent != null) {
      inner = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(child: inner),
          ],
        ),
      );
    }

    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AC.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A142D23),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: onTap == null
          ? inner
          : Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap, child: inner),
            ),
    );
  }
}

class ATag extends StatelessWidget {
  const ATag(this.text, {super.key, this.kind = 'na'});

  final String text;
  final String kind; // ok | wait | na

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    if (kind == 'ok') {
      bg = AC.okBg;
      fg = AC.okFg;
    } else if (kind == 'wait') {
      bg = AC.warnBg;
      fg = AC.warnFg;
    } else {
      bg = AC.naBg;
      fg = AC.naFg;
    }

    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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

Widget statusTag(String status) {
  const kinds = {
    'pending': 'wait',
    'approved': 'ok',
    'paid': 'ok',
    'shipped': 'ok',
    'delivered': 'ok',
    'cancelled': 'na',
  };

  return ATag(status, kind: kinds[status] ?? 'na');
}

class AdminButton extends StatelessWidget {
  const AdminButton(
    this.label, {
    super.key,
    this.onPressed,
    this.kind = 'green',
    this.icon,
    this.small = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final String kind; // green | gold | red | gray
  final IconData? icon;
  final bool small;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final Color bg;

    switch (kind) {
      case 'gold':
        bg = AC.gold;
        break;
      case 'red':
        bg = AC.red;
        break;
      case 'gray':
        bg = AC.gray;
        break;
      default:
        bg = AC.green;
    }

    final enabled = onPressed != null && !busy;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 11 : 16,
              vertical: small ? 8 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: small ? 15 : 18),
                  const SizedBox(width: 6),
                ],
                Text(
                  busy ? 'Please wait...' : label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: small ? 12.5 : 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminField extends StatelessWidget {
  const AdminField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboard,
    this.maxLines = 1,
    this.hint,
    this.maxLength,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final int maxLines;
  final String? hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  static InputDecoration decoration(String? hint) {
    const radius = BorderRadius.all(Radius.circular(9));

    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AC.line2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AC.line2),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AC.green, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AC.ink,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            maxLength: maxLength,
            onChanged: onChanged,
            style: const TextStyle(color: AC.ink),
            decoration: decoration(hint),
          ),
        ],
      ),
    );
  }
}

/// A "select" that opens a list at the bottom. [options] maps value -> label.
class AdminPicker extends StatelessWidget {
  const AdminPicker({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final entry in options.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == value
                    ? const Icon(Icons.check_rounded, color: AC.green)
                    : null,
                onTap: () => Navigator.of(ctx).pop(entry.key),
              ),
          ],
        ),
      ),
    );

    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AC.ink,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () => _open(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AC.line2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      options[value] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AC.ink),
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded, color: AC.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSwitch extends StatelessWidget {
  const AdminSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
  });

  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AC.ink,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: const TextStyle(color: AC.muted, fontSize: 12.5),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class AdminThumb extends StatelessWidget {
  const AdminThumb({
    super.key,
    this.image = '',
    this.emoji = '',
    this.bg = '',
    this.size = 44,
  });

  final String image;
  final String emoji;
  final String bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = aHex(bg, const Color(0xFFEFF3EC));
    final radius = BorderRadius.circular(10);

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Text(
        emoji.isEmpty ? '📦' : emoji,
        style: TextStyle(fontSize: size * 0.48),
      ),
    );

    if (image.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        IanovaApiConfig.imageUrl(image),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class AdminChip extends StatelessWidget {
  const AdminChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AC.green : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AC.green : AC.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              count == null ? label : '$label  $count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: selected ? Colors.white : AC.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sideways scrolling row of chips.
class AdminChipRow extends StatelessWidget {
  const AdminChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: children),
      ),
    );
  }
}

class AdminHeading extends StatelessWidget {
  const AdminHeading(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AC.ink,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class AdminMuted extends StatelessWidget {
  const AdminMuted(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AC.muted, fontSize: 13));
  }
}

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key, this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            AdminButton('Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

/// The page used for screens opened from the menu (orders, products...).
class AdminSubPage extends StatelessWidget {
  const AdminSubPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(top: false, child: child),
    );
  }
}

Future<T?> adminPush<T>(BuildContext context, Widget page) {
  return Navigator.of(context).push<T>(MaterialPageRoute<T>(builder: (_) => page));
}

/// Small order product row used by lists and the order view.
class AdminLineRow extends StatelessWidget {
  const AdminLineRow({
    super.key,
    required this.line,
    this.onTap,
    this.size = 46,
    this.showSeller = false,
  });

  final Map<String, dynamic> line;
  final VoidCallback? onTap;
  final double size;
  final bool showSeller;

  @override
  Widget build(BuildContext context) {
    final option = '${aStr(line['color'])} ${aStr(line['size'])}'.trim();
    final qty = aInt(line['quantity']);
    final price = aNum(line['unit_price']);
    final lineTotal = price * qty;
    final sub = StringBuffer('$qty × ${formatKsh(price)}');

    if (option.isNotEmpty) sub.write(' · $option');
    if (showSeller) sub.write(' · ${aStr(line['seller_name'])}');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AdminThumb(
              image: aStr(line['image']),
              emoji: aStr(line['emoji']),
              bg: aStr(line['bg_color']),
              size: size,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aStr(line['name']),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AC.ink,
                    ),
                  ),
                  Text(
                    sub.toString(),
                    style: const TextStyle(color: AC.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatKsh(lineTotal),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading, error and retry for a screen that fetches one JSON map.
mixin AdminLoad<T extends StatefulWidget> on State<T> {
  Map<String, dynamic>? data;
  String? error;
  bool loading = true;

  Future<Map<String, dynamic>> fetch();

  Future<void> load() async {
    try {
      final d = await fetch();

      if (!mounted) return;

      setState(() {
        data = d;
        error = null;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = adminErr(e);
        loading = false;
      });
    }
  }

  Widget gate(Widget Function(Map<String, dynamic> d) build) {
    if (loading && data == null) return const AdminLoading();

    final d = data;

    if (d == null) return AdminLoading(error: error, onRetry: load);

    return build(d);
  }
}

String adminDate(DateTime date, TimeOfDay time) {
  String two(int v) => v.toString().padLeft(2, '0');

  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(time.hour)}:${two(time.minute)}';
}

Future<String?> adminPickDateTime(BuildContext context) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 365)),
  );

  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 23, minute: 59),
  );

  if (time == null) return null;

  return adminDate(date, time);
}
