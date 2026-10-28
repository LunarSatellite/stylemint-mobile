import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_reason_category.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/delivery_confirmation_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_handover_confirm.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_pickup_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_reason_category_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_request_dialog.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../orders_test_harness.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

class _MockConfirmRepo extends Mock implements DeliveryConfirmationRepository {}

const _item = OrderDetailItem(
  id: 'line-1',
  subOrderId: 'sub-1',
  productId: 'prod-1',
  productName: 'Linen shirt',
  imageUrl: '',
  variantName: 'M',
  qty: 2,
  unitPrice: Money(amount: 2500, currency: 'NPR'),
  status: 'Delivered',
);

const _quote = ReturnPickupQuote(
  estimate: Money(amount: 150, currency: 'NPR'),
  upTo: Money(amount: 185, currency: 'NPR'),
  itemTotal: Money(amount: 2500, currency: 'NPR'),
  refundIfChangedMind: Money(amount: 2315, currency: 'NPR'),
);

ReturnPickup _pickup(Map<String, dynamic> extra) => ReturnPickup.fromJson({
  'id': 'p-1',
  'returnRequestId': 'ret-1',
  'trackingNumber': 'SM-R-00000042',
  'state': 2,
  'mode': 'Rider',
  'requestedUtc': '2026-10-28T08:00:00Z',
  ...extra,
});

void main() {
  group('return form', () {
    late _MockOrdersRepository repo;
    late List<ReturnRequestResult?> results;

    Future<void> pumpForm(WidgetTester tester) async {
      setPhoneView(tester);
      results = [];
      final notifier = OrderDetailNotifier(repo);
      addTearDown(notifier.dispose);
      await tester.pumpWidget(
        ordersTestApp(
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  results.add(
                    await showDialog<ReturnRequestResult>(
                      context: context,
                      builder: (_) => ReturnRequestDialog(
                        orderNumber: 'NK2026-00042',
                        items: const [_item],
                        notifier: notifier,
                        pickPhoto: () async => null,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      repo = _MockOrdersRepository();
      when(
        () => repo.getReturnPickupQuote(
          any(),
          subOrderId: any(named: 'subOrderId'),
          subOrderLineId: any(named: 'subOrderLineId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async => right(_quote));
    });

    testWidgets('a category is required before anything else', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.byKey(ReturnRequestDialog.submitKey));
      await tester.pump();

      expect(find.text(ReturnRequestDialog.categoryMissingText), findsOneWidget);
      expect(results, isEmpty, reason: 'the dialog stays open');

      await tester.tap(
        find.byKey(
          ReturnReasonCategoryPicker.chipKey(ReturnReasonCategory.damaged),
        ),
      );
      await tester.pump();
      expect(find.text(ReturnRequestDialog.categoryMissingText), findsNothing);

      // With a category, the next requirement is the photo.
      await tester.tap(find.byKey(ReturnRequestDialog.submitKey));
      await tester.pump();
      expect(find.text('Please add at least one photo.'), findsOneWidget);
    });

    testWidgets('only "Changed my mind" shows the fare deduction', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.tap(
        find.byKey(
          ReturnReasonCategoryPicker.chipKey(ReturnReasonCategory.damaged),
        ),
      );
      await tester.pump();
      expect(find.text(ReturnPickupFeeNote.freeText), findsOneWidget);
      expect(find.textContaining('deducted'), findsNothing);
      verifyNever(
        () => repo.getReturnPickupQuote(
          any(),
          subOrderId: any(named: 'subOrderId'),
          subOrderLineId: any(named: 'subOrderLineId'),
          quantity: any(named: 'quantity'),
        ),
      );

      await tester.tap(
        find.byKey(
          ReturnReasonCategoryPicker.chipKey(ReturnReasonCategory.changedMind),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          'Pickup fee about Rs 150. Up to Rs 185 will be deducted from your '
          'refund.',
        ),
        findsOneWidget,
      );
      expect(find.text(ReturnPickupFeeNote.freeText), findsNothing);
      verify(
        () => repo.getReturnPickupQuote(
          'NK2026-00042',
          subOrderId: 'sub-1',
          subOrderLineId: 'line-1',
          quantity: 1,
        ),
      ).called(1);
    });

    testWidgets('no quote still warns that the fee comes off the refund', (
      tester,
    ) async {
      when(
        () => repo.getReturnPickupQuote(
          any(),
          subOrderId: any(named: 'subOrderId'),
          subOrderLineId: any(named: 'subOrderLineId'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );
      await pumpForm(tester);

      await tester.tap(
        find.byKey(
          ReturnReasonCategoryPicker.chipKey(ReturnReasonCategory.changedMind),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text(ReturnPickupFeeNote.noQuoteText), findsOneWidget);
    });
  });

  group('return pickup on the return screen', () {
    late _MockOrdersRepository repo;
    late int refreshed;

    Future<void> pumpSection(WidgetTester tester, ReturnPickup pickup) async {
      setPhoneView(tester);
      refreshed = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ordersRepositoryProvider.overrideWithValue(repo),
            deliveryConfirmationRepositoryProvider.overrideWithValue(
              _MockConfirmRepo(),
            ),
          ],
          child: ordersTestApp(
            SingleChildScrollView(
              child: ReturnPickupSection(
                pickup: pickup,
                onChanged: () async => refreshed++,
                scanner: (_) async => null,
              ),
            ),
          ),
        ),
      );
    }

    setUp(() => repo = _MockOrdersRepository());

    testWidgets("rider at the door: the buyer scans the rider's code", (
      tester,
    ) async {
      await pumpSection(
        tester,
        _pickup({
          'stage': 'AwaitingBuyerConfirmation',
          'rider': {'displayName': 'Ramesh K.', 'rating': 4.8, 'vehicle': 'Bike'},
          'canCancel': true,
        }),
      );

      expect(find.text("Scan the rider's code to hand over"), findsOneWidget);
      expect(find.byKey(ReturnHandoverConfirm.scanKey), findsOneWidget);
      expect(find.text('Type the code instead'), findsOneWidget);
      expect(find.text('Ramesh K. · ★ 4.8 · Bike'), findsOneWidget);
      expect(find.byKey(ReturnPickupSection.cancelKey), findsOneWidget);
    });

    testWidgets('before the rider arrives there is nothing to scan', (
      tester,
    ) async {
      await pumpSection(
        tester,
        _pickup({
          'stage': 'RiderAssigned',
          'rider': {'displayName': 'Ramesh K.'},
        }),
      );

      expect(find.text('Ramesh K. is coming to collect it'), findsOneWidget);
      expect(find.byKey(ReturnHandoverConfirm.scanKey), findsNothing);
    });

    testWidgets('a failed attempt offers "Send a rider again"', (tester) async {
      when(() => repo.retryReturnPickup('ret-1')).thenAnswer(
        (_) async => right(_pickup({'stage': 'SearchingRider', 'state': 1})),
      );
      await pumpSection(
        tester,
        _pickup({
          'stage': 'AttemptFailed',
          'state': 5,
          'attempts': {'failed': 1, 'max': 3},
          'canRetry': true,
        }),
      );

      expect(find.text("Rider couldn't collect"), findsOneWidget);
      expect(find.textContaining('Attempt 1 of 3'), findsOneWidget);
      await tester.tap(find.byKey(ReturnPickupSection.sendAgainKey));
      await tester.pump();
      await tester.pump();

      verify(() => repo.retryReturnPickup('ret-1')).called(1);
      expect(refreshed, 1);
    });

    testWidgets('cancel asks first, then cancels', (tester) async {
      when(() => repo.cancelReturn('ret-1', note: any(named: 'note')))
          .thenAnswer((_) async => left(const NetworkExceptions.notFound()));
      await pumpSection(
        tester,
        _pickup({'stage': 'SearchingRider', 'state': 1, 'canCancel': true}),
      );

      await tester.tap(find.byKey(ReturnPickupSection.cancelKey));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this return?'), findsOneWidget);
      await tester.tap(find.byKey(ReturnPickupSection.confirmCancelKey));
      await tester.pump();
      await tester.pump();

      verify(() => repo.cancelReturn('ret-1', note: any(named: 'note')))
          .called(1);
    });

    test('fare wording follows the payer', () {
      expect(
        ReturnPickupSection.fareLine(
          const ReturnPickupFare(payer: ReturnFarePayer.seller),
        ),
        'Pickup is free for you.',
      );
      expect(
        ReturnPickupSection.fareLine(
          const ReturnPickupFare(
            payer: ReturnFarePayer.buyer,
            amount: Money(amount: 150, currency: 'NPR'),
            upTo: Money(amount: 185, currency: 'NPR'),
          ),
        ),
        'Pickup fee about Rs 150 (up to Rs 185) comes off your refund.',
      );
      expect(
        ReturnRefundBreakdownLine.text(
          const ReturnRefundBreakdown(
            itemTotal: Money(amount: 2500, currency: 'NPR'),
            pickupFareDeducted: Money(amount: 150, currency: 'NPR'),
            refundAmount: Money(amount: 2350, currency: 'NPR'),
          ),
        ),
        'Item Rs 2,500 − pickup Rs 150 = refund Rs 2,350',
      );
    });
  });
}

