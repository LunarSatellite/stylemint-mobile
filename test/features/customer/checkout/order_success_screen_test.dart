import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool paymentPending = false,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, width <= 320 ? 568 : 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: OrderSuccessScreen(
          orderId: 'NK2026-00015',
          paymentPending: paymentPending,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a confirmed order says so, and shows its number', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    expect(find.text('NK2026-00015'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsWidgets);
  });

  testWidgets('a pending payment never claims the order is paid', (
    tester,
  ) async {
    await _pump(tester, paymentPending: true);
    expect(find.text('Thank you'), findsNothing);
    expect(find.text('Almost there'), findsOneWidget);
    expect(
      find.textContaining('Nothing has been charged'),
      findsOneWidget,
    );
    // A different mark, not merely a different colour: the confirmed state's
    // tick must not appear on an unpaid order.
    expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MallStatusStepper),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
  });

  testWidgets('what happens next is spelled out for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(
      find.bySemanticsLabel(RegExp('Confirmed. completed')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Delivered. not started')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('both actions are present and reachable', (tester) async {
    await _pump(tester);
    expect(find.text('View order'), findsOneWidget);
    expect(find.text('Keep shopping'), findsOneWidget);
  });

  for (final pending in [false, true]) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          'no overflow — ${width.toInt()}dp, text ×$scale'
          '${pending ? ', payment pending' : ''}',
          (tester) async {
            await _pump(
              tester,
              paymentPending: pending,
              width: width,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
