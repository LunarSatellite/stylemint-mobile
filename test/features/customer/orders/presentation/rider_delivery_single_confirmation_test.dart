import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/condition_assurance_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/confirm_receipt_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/custody_proof_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_acceptance_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_confirm_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../orders_test_harness.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

OrderDetail _order({
  OrderTrackStatus status = OrderTrackStatus.outForDelivery,
  OrderDelivery? delivery,
  List<OrderDetailItem> items = const [],
}) => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: status,
  placedAt: DateTime.utc(2026, 10, 1),
  estimatedDelivery: DateTime.utc(2026, 10, 9),
  items: items,
  subtotal: const Money(amount: 1000, currency: 'NPR'),
  shipping: const Money(amount: 100, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  total: const Money(amount: 1100, currency: 'NPR'),
  shippingAddress: 'Kupondole, Lalitpur',
  paymentMethod: 'eSewa',
  trackingNumber: 'SM-D-00000013',
  canCancel: false,
  canReturn: false,
  delivery: delivery,
);

OrderDelivery _delivery({
  String status = 'PickedUp',
  bool awaiting = false,
}) => OrderDelivery(
  packageNumber: 'SM-D-00000013',
  status: status,
  riderName: 'Ram',
  awaitingConfirmation: awaiting,
  subOrderId: 'sub-1',
);

SubOrderTimeline _sub({
  DeliveryProofStatus proof = DeliveryProofStatus.invalid,
  BuyerTimelineStep current = BuyerTimelineStep.inTransit,
  bool terminal = false,
  String? trackingNumber,
}) => SubOrderTimeline(
  subOrderId: 'sub-1',
  vendorAccountId: 'v',
  itemsCount: 1,
  currentStep: current,
  isTerminal: terminal,
  deliveryProofStatus: proof,
  trackingNumber: trackingNumber,
  steps: const [],
);

_MockOrdersRepository _repositoryFor(OrderDetail order) {
  final repository = _MockOrdersRepository();
  when(
    () => repository.getOrderDetail('NK2026-00015'),
  ).thenAnswer((_) async => right(order));
  when(() => repository.getOrderTimeline('NK2026-00015')).thenAnswer(
    (_) async => left(const NetworkExceptions.serverUnavailable()),
  );
  return repository;
}

Widget _screen(_MockOrdersRepository repository) => ProviderScope(
  overrides: [
    ordersRepositoryProvider.overrideWithValue(repository),
    deliveryStoryProvider.overrideWith((ref, trackingNumber) async => []),
  ],
  child: ordersTestApp(
    const OrderDetailScreen(orderId: 'NK2026-00015'),
    wrapInScaffold: false,
  ),
);

/// Every legacy receipt card the rider QR flow replaces.
void _expectNoLegacyReceiptCards() {
  expect(find.byType(ConfirmReceiptCard), findsNothing);
  expect(find.byType(DeliveryAcceptanceCard), findsNothing);
  expect(find.byType(CustodyProofCard), findsNothing);
  expect(find.byType(ConditionAssuranceCard), findsNothing);
}

void main() {
  group('"Delivery proof needs review"', () {
    test('never on a delivered or closed sub-order', () {
      for (final current in [
        BuyerTimelineStep.delivered,
        BuyerTimelineStep.collected,
        BuyerTimelineStep.cancelled,
        BuyerTimelineStep.returned,
      ]) {
        expect(
          OrderTrackingTimeline.proofBadgeFor(
            _sub(current: current, terminal: true),
          ),
          isNull,
          reason: '$current',
        );
      }
    });

    test('never on a StyleMint-rider parcel, in flight or delivered', () {
      expect(
        OrderTrackingTimeline.proofBadgeFor(_sub(), riderDelivery: true),
        isNull,
      );
      expect(
        OrderTrackingTimeline.proofBadgeFor(
          _sub(trackingNumber: 'SM-D-00000013'),
        ),
        isNull,
      );
    });

    test('still warns on an in-flight parcel of another carrier', () {
      expect(
        OrderTrackingTimeline.proofBadgeFor(_sub(trackingNumber: 'NCM-1')),
        DeliveryProofStatus.invalid,
      );
    });

    test('verified shows; unsealed shows nothing', () {
      expect(
        OrderTrackingTimeline.proofBadgeFor(
          _sub(
            proof: DeliveryProofStatus.verified,
            current: BuyerTimelineStep.delivered,
            terminal: true,
          ),
          riderDelivery: true,
        ),
        DeliveryProofStatus.verified,
      );
      expect(
        OrderTrackingTimeline.proofBadgeFor(
          _sub(proof: DeliveryProofStatus.legacyUnsealed),
        ),
        isNull,
      );
    });

    testWidgets('a delivered rider order draws no warning', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(
              timeline: _sub(
                current: BuyerTimelineStep.delivered,
                terminal: true,
              ),
              riderDelivery: true,
            ),
          ),
        ),
      );
      expect(find.text('Delivery proof needs review'), findsNothing);
      expectNoLayoutErrors(tester);
    });
  });

  group('one confirmation step for a rider QR delivery', () {
    testWidgets('on the way: no label scan, no acceptance, no custody card', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        _screen(_repositoryFor(_order(delivery: _delivery()))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeliveryConfirmCard), findsNothing);
      _expectNoLegacyReceiptCards();
    });

    testWidgets('at the door: only the rider QR card', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        _screen(
          _repositoryFor(
            _order(
              delivery: _delivery(
                status: 'AwaitingConfirmation',
                awaiting: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeliveryConfirmCard), findsOneWidget);
      _expectNoLegacyReceiptCards();
    });

    testWidgets('delivered: nothing left to confirm', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        _screen(
          _repositoryFor(
            _order(
              status: OrderTrackStatus.delivered,
              delivery: _delivery(status: 'Delivered'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeliveryConfirmCard), findsNothing);
      _expectNoLegacyReceiptCards();
    });

    testWidgets('an order with no rider delivery keeps the label scan', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(_screen(_repositoryFor(_order())));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmReceiptCard), findsOneWidget);
    });

    test('a stale awaiting flag on a delivered parcel offers nothing', () {
      expect(
        DeliveryConfirmCard.isOfferedFor(
          _order(delivery: _delivery(status: 'Delivered', awaiting: true)),
        ),
        isFalse,
      );
    });
  });

  group('after the buyer confirms', () {
    test('reads Delivered at once, and a stale re-read keeps it', () async {
      final awaiting = _order(
        delivery: _delivery(status: 'AwaitingConfirmation', awaiting: true),
      );
      final repository = _repositoryFor(awaiting);
      final notifier = OrderDetailNotifier(repository);
      addTearDown(notifier.dispose);
      await notifier.loadOrder('NK2026-00015');

      notifier.markDeliveryConfirmed();
      OrderDetail shown() => notifier.state.maybeWhen(
        loadSuccess: (o) => o,
        orElse: () => throw StateError('not loaded'),
      );
      expect(shown().status, OrderTrackStatus.delivered);
      expect(DeliveryConfirmCard.isOfferedFor(shown()), isFalse);

      // The server has not caught up yet: still awaiting on the wire.
      await notifier.refresh('NK2026-00015');
      expect(shown().status, OrderTrackStatus.delivered);
      expect(DeliveryConfirmCard.isOfferedFor(shown()), isFalse);
    });

    test('a split order: only the delivery flips', () async {
      final split = _order(
        delivery: _delivery(status: 'AwaitingConfirmation', awaiting: true),
        items: const [
          OrderDetailItem(
            subOrderId: 'sub-1',
            productId: 'p',
            productName: 'x',
            imageUrl: '',
            variantName: '',
            qty: 1,
            unitPrice: Money(amount: 1, currency: 'NPR'),
            status: '',
          ),
          OrderDetailItem(
            subOrderId: 'sub-2',
            productId: 'q',
            productName: 'y',
            imageUrl: '',
            variantName: '',
            qty: 1,
            unitPrice: Money(amount: 1, currency: 'NPR'),
            status: '',
          ),
        ],
      );
      final notifier = OrderDetailNotifier(_repositoryFor(split));
      addTearDown(notifier.dispose);
      await notifier.loadOrder('NK2026-00015');
      notifier.markDeliveryConfirmed();

      final shown = notifier.state.maybeWhen(
        loadSuccess: (o) => o,
        orElse: () => throw StateError('not loaded'),
      );
      expect(shown.status, OrderTrackStatus.outForDelivery);
      expect(shown.delivery!.isDelivered, isTrue);
      expect(DeliveryConfirmCard.isOfferedFor(shown), isFalse);
    });
  });
}
