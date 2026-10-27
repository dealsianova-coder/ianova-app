import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin_ui.dart';

/// Dark mode for the Admin app. The whole screen is colour-flipped (keeping the hues), and the
/// parts that are already dark (top bar, side menu) and every picture are flipped back so they look normal.
final ValueNotifier<bool> adminDark = ValueNotifier<bool>(false);

const List<double> _flip = <double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0,
];

Future<void> adminDarkLoad() async {
  try {
    final p = await SharedPreferences.getInstance();
    adminDark.value = p.getBool('admin_dark') ?? false;
  } catch (_) {}
}

Future<void> adminDarkSet(bool value) async {
  adminDark.value = value;
  try {
    final p = await SharedPreferences.getInstance();
    await p.setBool('admin_dark', value);
  } catch (_) {}
}

/// Wraps the whole Admin app (MaterialApp.builder).
class AdminDarkShell extends StatefulWidget {
  const AdminDarkShell({super.key, required this.child});

  final Widget child;

  @override
  State<AdminDarkShell> createState() => _AdminDarkShellState();
}

class _AdminDarkShellState extends State<AdminDarkShell> {
  @override
  void initState() {
    super.initState();
    adminDarkLoad();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: adminDark,
      builder: (context, dark, child) {
        if (!dark) return child!;

        return ColorFiltered(
          colorFilter: const ColorFilter.matrix(_flip),
          child: ColoredBox(color: AC.bg, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Keeps the original colours of its child in dark mode (pictures, the dark top bar and side menu).
class AdminKeepColors extends StatelessWidget {
  const AdminKeepColors({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: adminDark,
      builder: (context, dark, child) {
        if (!dark) return child!;

        return ColorFiltered(colorFilter: const ColorFilter.matrix(_flip), child: child);
      },
      child: child,
    );
  }
}

/// AppBar that keeps its colours in dark mode.
class AdminKeepBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminKeepBar(this.bar, {super.key});

  final PreferredSizeWidget bar;

  @override
  Size get preferredSize => bar.preferredSize;

  @override
  Widget build(BuildContext context) => AdminKeepColors(child: bar);
}
