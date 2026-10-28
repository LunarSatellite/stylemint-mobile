import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_step_sheets.dart';

import '../../orders_test_harness.dart';

void main() {
  group('VendorReturnReceivedSheet', () {
    /// Opens the sheet from a button and records what it resolves to.
    Future<List<bool?>> openSheet(WidgetTester tester) async {
      final results = <bool?>[];
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async =>
                    results.add(await showVendorReturnReceivedSheet(context)),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return results;
    }

    testWidgets('shows the title, the switch on by default, and its hint', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text(VendorReturnReceivedSheet.title), findsOneWidget);
      expect(find.text(VendorReturnReceivedSheet.restockLabel), findsOneWidget);
      expect(find.text(VendorReturnReceivedSheet.restockHint), findsOneWidget);
      final toggle = tester.widget<SwitchListTile>(
        find.byKey(VendorReturnReceivedSheet.restockSwitchKey),
      );
      expect(toggle.value, isTrue);
    });

    testWidgets('confirming with the default sends restock true', (
      tester,
    ) async {
      final results = await openSheet(tester);

      await tester.tap(find.byKey(VendorReturnReceivedSheet.submitKey));
      await tester.pumpAndSettle();

      expect(results, [true]);
      expect(find.text(VendorReturnReceivedSheet.title), findsNothing);
    });

    testWidgets('switching off sends restock false', (tester) async {
      final results = await openSheet(tester);

      await tester.tap(find.byKey(VendorReturnReceivedSheet.restockSwitchKey));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(VendorReturnReceivedSheet.restockSwitchKey),
            )
            .value,
        isFalse,
      );

      await tester.tap(find.byKey(VendorReturnReceivedSheet.submitKey));
      await tester.pumpAndSettle();

      expect(results, [false]);
    });

    testWidgets('cancel completes nothing', (tester) async {
      final results = await openSheet(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });
  });
}
