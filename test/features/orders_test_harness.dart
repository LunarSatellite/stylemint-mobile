import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// Sizes [tester]'s view to a phone [width] (logical px) and resets it after
/// the test.
void setPhoneView(WidgetTester tester, {double width = 390}) {
  tester.view
    ..physicalSize = Size(width, width <= 320 ? 640 : 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The dark app theme with a text scale and animations off (so skeleton
/// shimmer and spinners don't keep frames pending).
Widget ordersTestApp(
  Widget home, {
  double textScale = 1,
  bool wrapInScaffold = true,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: true,
      ),
      child: app ?? const SizedBox.shrink(),
    ),
    home: wrapInScaffold ? Scaffold(body: home) : home,
  );
}

/// Fails on any layout exception such as a RenderFlex overflow.
void expectNoLayoutErrors(WidgetTester tester) =>
    expect(tester.takeException(), isNull);
