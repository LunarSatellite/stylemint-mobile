
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/support/presentation/screens/contact_support_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/screens/brand_studio_screen.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: _DevApp(),
    ),
  );
}

class _DevApp extends StatelessWidget {
  const _DevApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const ContactSupportScreen(),
    );
  }
}
