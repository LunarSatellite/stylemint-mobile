import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_pill.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_status_pill.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

// Track Orders, My Returns, Return Detail and Order Detail all speak the same
// status vocabulary now. The guarantee these tests protect: a state is never
// carried by colour alone, anywhere in the journey.

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, 600)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: Align(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('OrderStatusBadge', () {
    testWidgets('every order state draws its own mark', (tester) async {
      final seen = <IconData>{};
      for (final status in OrderTrackStatus.values) {
        await _pump(tester, OrderStatusBadge(status: status));
        expect(
          find.descendant(
            of: find.byType(OrderStatusBadge),
            matching: find.byIcon(OrderStatusBadge.iconFor(status)),
          ),
          findsOneWidget,
          reason: '$status must show a glyph',
        );
        seen.add(OrderStatusBadge.iconFor(status));
      }
      // In transit and Out for delivery share the accent; to a buyer waiting
      // at home they are not the same thing, so they must not share a mark.
      expect(seen.length, OrderTrackStatus.values.length);
    });

    testWidgets('a delivered order is not a green slab', (tester) async {
      await _pump(
        tester,
        const OrderStatusBadge(status: OrderTrackStatus.delivered),
      );
      expect(find.byType(MallStatusPill), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('no overflow — ${width.toInt()}dp, text ×$scale', (
          tester,
        ) async {
          await _pump(
            tester,
            Column(
              children: [
                for (final status in OrderTrackStatus.values)
                  OrderStatusBadge(status: status),
              ],
            ),
            width: width,
            textScale: scale,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('ReturnStatusPill', () {
    testWidgets('approved and rejected differ by more than colour', (
      tester,
    ) async {
      await _pump(
        tester,
        const ReturnStatusPill(status: ReturnRequestStatus.approved),
      );
      expect(
        find.byIcon(ReturnStatusPill.iconFor(ReturnRequestStatus.approved)),
        findsOneWidget,
      );
      await _pump(
        tester,
        const ReturnStatusPill(status: ReturnRequestStatus.rejected),
      );
      expect(
        find.byIcon(ReturnStatusPill.iconFor(ReturnRequestStatus.rejected)),
        findsOneWidget,
      );
      expect(
        ReturnStatusPill.iconFor(ReturnRequestStatus.approved),
        isNot(ReturnStatusPill.iconFor(ReturnRequestStatus.rejected)),
      );
    });
  });

  group('OrderPillTone', () {
    test('every tone maps onto the kit vocabulary', () {
      for (final tone in OrderPillTone.values) {
        expect(OrderStatusPill.mallToneFor(tone), isA<MallStatusTone>());
        final (background, foreground) = OrderStatusPill.colorsFor(tone);
        expect(background, isNot(foreground));
      }
    });
  });
}
