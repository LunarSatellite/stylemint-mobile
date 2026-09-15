import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_action_bar.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_step_sheets.dart';

import '../../orders_test_harness.dart';

void main() {
  group('VendorOrderActionBar', () {
    Future<List<VendorOrderAction>> pumpBar(
      WidgetTester tester,
      int stateCode, {
      double width = 390,
      double textScale = 1,
    }) async {
      final tapped = <VendorOrderAction>[];
      setPhoneView(tester, width: width);
      await tester.pumpWidget(
        ordersTestApp(
          Padding(
            padding: const EdgeInsets.all(16),
            child: VendorOrderActionBar(
              stateCode: stateCode,
              onAction: tapped.add,
            ),
          ),
          textScale: textScale,
        ),
      );
      return tapped;
    }

    final expectations = <int, List<String>>{
      SubOrderStateCode.paid: ['Reject', 'Accept'],
      SubOrderStateCode.awaitingFulfillment: ['Reject', 'Accept'],
      SubOrderStateCode.accepted: ['Mark packed'],
      SubOrderStateCode.packed: ['Hand over', 'Mark as Shipped'],
      SubOrderStateCode.handedOver: ['Mark as Delivered'],
      SubOrderStateCode.shipped: ['Mark as Delivered'],
      SubOrderStateCode.inTransit: ['Mark as Delivered'],
      SubOrderStateCode.outForDelivery: ['Mark as Delivered'],
    };

    for (final entry in expectations.entries) {
      testWidgets('state ${entry.key} shows ${entry.value.join(' + ')}', (
        tester,
      ) async {
        final tapped = await pumpBar(tester, entry.key);

        for (final label in entry.value) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.byType(FilledButton), findsNWidgets(entry.value.length));
        for (final button in tester.widgetList<FilledButton>(
          find.byType(FilledButton),
        )) {
          expect(tester.getSize(find.byWidget(button)).height, 52);
        }

        await tester.tap(find.text(entry.value.last));
        expect(tapped, hasLength(1));
      });
    }

    for (final state in [1, 4, 5, 7, 8, 9, 99]) {
      testWidgets('state $state has no vendor step', (tester) async {
        await pumpBar(tester, state);
        expect(find.byType(FilledButton), findsNothing);
      });
    }

    testWidgets('busy disables every button and spins the pending one', (
      tester,
    ) async {
      final tapped = <VendorOrderAction>[];
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          VendorOrderActionBar(
            stateCode: SubOrderStateCode.paid,
            onAction: tapped.add,
            busy: true,
            pendingAction: VendorOrderAction.accept,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      await tester.tap(find.text('Reject'));
      expect(tapped, isEmpty);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      for (final state in expectations.keys) {
        await pumpBar(tester, state, width: 320, textScale: 1.3);
        expectNoLayoutErrors(tester);
      }
    });
  });

  group('Reject sheet', () {
    Future<VendorRejectInput?> Function() openSheet(
      WidgetTester tester, {
      double width = 390,
      double textScale = 1,
    }) {
      setPhoneView(tester, width: width);
      VendorRejectInput? result;
      var closed = false;
      return () async {
        await tester.pumpWidget(
          ordersTestApp(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showVendorRejectSheet(context);
                  closed = true;
                },
                child: const Text('open'),
              ),
            ),
            textScale: textScale,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        return closed ? result : null;
      };
    }

    FilledButton submitButton(WidgetTester tester) =>
        tester.widget<FilledButton>(find.byKey(VendorRejectSheet.submitKey));

    testWidgets('lists the six contract reasons; submit waits for one', (
      tester,
    ) async {
      await openSheet(tester)();

      for (final reason in VendorRejectionReason.values) {
        expect(find.text(reason.label), findsOneWidget);
      }
      expect(submitButton(tester).onPressed, isNull);

      await tester.tap(find.text('Out of stock'));
      await tester.pump();
      expect(submitButton(tester).onPressed, isNotNull);
    });

    testWidgets('Other needs a note before it submits', (tester) async {
      VendorRejectInput? result;
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showVendorRejectSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Other'));
      await tester.tap(find.text('Other'));
      await tester.pump();
      await tester.ensureVisible(find.byKey(VendorRejectSheet.submitKey));
      await tester.tap(find.byKey(VendorRejectSheet.submitKey));
      await tester.pumpAndSettle();

      expect(find.text(VendorRejectSheet.noteRequiredError), findsOneWidget);
      expect(find.byType(VendorRejectSheet), findsOneWidget);

      await tester.enterText(
        find.byKey(VendorRejectSheet.noteFieldKey),
        '  Supplier recalled the batch  ',
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(VendorRejectSheet.submitKey));
      await tester.tap(find.byKey(VendorRejectSheet.submitKey));
      await tester.pumpAndSettle();

      expect(find.byType(VendorRejectSheet), findsNothing);
      expect(result?.reason, VendorRejectionReason.other);
      expect(result?.note, 'Supplier recalled the batch');
    });

    testWidgets('the note is capped at 200 characters', (tester) async {
      await openSheet(tester)();

      await tester.enterText(
        find.byKey(VendorRejectSheet.noteFieldKey),
        'x' * 250,
      );
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(VendorRejectSheet.noteFieldKey),
      );
      expect(field.controller!.text.length, vendorNoteMaxLength);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      await openSheet(tester, width: 320, textScale: 1.3)();
      expectNoLayoutErrors(tester);
    });
  });

  group('Handover sheet', () {
    Future<VendorHandoverInput?> Function() pumpAndOpen(
      WidgetTester tester, {
      double width = 390,
      double textScale = 1,
    }) {
      setPhoneView(tester, width: width);
      VendorHandoverInput? result;
      return () async {
        await tester.pumpWidget(
          ordersTestApp(
            Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    result = await showVendorHandoverSheet(context),
                child: const Text('open'),
              ),
            ),
            textScale: textScale,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        return result;
      };
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(VendorHandoverSheet.submitKey));
      await tester.tap(find.byKey(VendorHandoverSheet.submitKey));
      await tester.pumpAndSettle();
    }

    testWidgets('carrier without tracking number is blocked', (tester) async {
      await pumpAndOpen(tester)();

      await tester.enterText(
        find.byKey(VendorHandoverSheet.carrierFieldKey),
        'Pathao',
      );
      await submit(tester);

      expect(
        find.text(VendorHandoverSheet.trackingMissingError),
        findsOneWidget,
      );
      expect(find.byType(VendorHandoverSheet), findsOneWidget);
    });

    testWidgets('tracking number without carrier is blocked', (tester) async {
      await pumpAndOpen(tester)();

      await tester.enterText(
        find.byKey(VendorHandoverSheet.trackingFieldKey),
        'PTH-99812',
      );
      await submit(tester);

      expect(
        find.text(VendorHandoverSheet.carrierMissingError),
        findsOneWidget,
      );
      expect(find.byType(VendorHandoverSheet), findsOneWidget);
    });

    testWidgets('neither is fine, with an optional note', (tester) async {
      VendorHandoverInput? result;
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showVendorHandoverSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(VendorHandoverSheet.noteFieldKey),
        'Given to rider Ram at the gate',
      );
      await submit(tester);

      expect(find.byType(VendorHandoverSheet), findsNothing);
      expect(result, isNotNull);
      expect(result!.carrier, isNull);
      expect(result!.trackingNumber, isNull);
      expect(result!.note, 'Given to rider Ram at the gate');
    });

    testWidgets('both carrier and tracking number submit together', (
      tester,
    ) async {
      VendorHandoverInput? result;
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  result = await showVendorHandoverSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(VendorHandoverSheet.carrierFieldKey),
        ' Pathao ',
      );
      await tester.enterText(
        find.byKey(VendorHandoverSheet.trackingFieldKey),
        'PTH-99812',
      );
      await submit(tester);

      expect(result?.carrier, 'Pathao');
      expect(result?.trackingNumber, 'PTH-99812');
      expect(result?.note, isNull);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      await pumpAndOpen(tester, width: 320, textScale: 1.3)();
      expectNoLayoutErrors(tester);
    });
  });
}
