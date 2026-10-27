import 'package:flutter/material.dart';

import 'features/admin/admin_dark.dart';
import 'core/push/push_service.dart';
import 'features/admin/admin_page.dart';
import 'features/splash/splash_page.dart';
import 'features/admin/admin_ui.dart';

/// Entry point of the separate "IANOVA Admin" app. The shop app never includes this.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IanovaAdminApp());
  PushService.start(); // phone notifications
}

class IanovaAdminApp extends StatelessWidget {
  const IanovaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IANOVA Admin',
      theme: adminTheme(),
      builder: (context, child) => AdminDarkShell(child: child ?? const SizedBox.shrink()),
      home: const SplashGate(next: AdminPage()),
    );
  }
}
