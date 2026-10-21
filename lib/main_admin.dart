import 'package:flutter/material.dart';

import 'features/admin/admin_page.dart';
import 'features/splash/splash_page.dart';
import 'features/admin/admin_ui.dart';

/// Entry point of the separate "IANOVA Admin" app. The shop app never includes this.
void main() {
  runApp(const IanovaAdminApp());
}

class IanovaAdminApp extends StatelessWidget {
  const IanovaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IANOVA Admin',
      theme: adminTheme(),
      home: const SplashGate(next: AdminPage()),
    );
  }
}
