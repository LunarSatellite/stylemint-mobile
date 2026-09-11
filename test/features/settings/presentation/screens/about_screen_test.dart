import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stylemint_mobile_frontend/features/settings/presentation/screens/about_screen.dart';

void main() {
  testWidgets('shows runtime package metadata without unsupported stats', (
    tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'StyleMint',
      packageName: 'com.example.stylemint_mobile_frontend',
      version: '2.3.4',
      buildNumber: '57',
      buildSignature: '',
    );

    await tester.pumpWidget(const MaterialApp(home: AboutScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Version 2.3.4 (Build 57)'), findsOneWidget);
    expect(find.text('Platform Stats'), findsNothing);
    expect(find.text('250k'), findsNothing);
    expect(find.text('15m'), findsNothing);
    expect(find.textContaining('StyleMint Inc.'), findsNothing);
  });
}
