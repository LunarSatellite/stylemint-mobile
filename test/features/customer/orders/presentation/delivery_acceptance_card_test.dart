import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_acceptance_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _tracking = 'SM-D-00000001';

DeliveryAcceptance _acceptance(
  DeliveryAcceptanceOutcome outcome, {
  bool? sealIntact,
  String? issueNote,
}) => DeliveryAcceptance(
  id: 'acc-1',
  packageId: 'pkg-1',
  trackingNumber: _tracking,
  outcome: outcome,
  sealIntact: sealIntact,
  issueNote: issueNote,
  recordedUtc: DateTime.utc(2026, 9, 13, 12),
);

void main() {
  late _MockOrdersRepository repository;

  setUpAll(() => registerFallbackValue(DeliveryAcceptanceOutcome.accepted));
  setUp(() => repository = _MockOrdersRepository());

  void stubChecks({
    required Either<NetworkExceptions, DeliveryPackageStatus> package,
    required Either<NetworkExceptions, DeliveryAcceptance> saved,
  }) {
    when(
      () => repository.getDeliveryPackageStatus(_tracking),
    ).thenAnswer((_) async => package);
    when(
      () => repository.getDeliveryAcceptance(_tracking),
    ).thenAnswer((_) async => saved);
  }

  void stubRecord(DeliveryAcceptance saved) {
    when(
      () => repository.recordDeliveryAcceptance(
        any(),
        outcome: any(named: 'outcome'),
        sealIntact: any(named: 'sealIntact'),
        issueNote: any(named: 'issueNote'),
      ),
    ).thenAnswer((_) async => right(saved));
  }

  void useTallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpCard(WidgetTester tester) async {
    useTallView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliveryAcceptanceCard(trackingNumber: _tracking),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  VoidCallback? sendAction(WidgetTester tester) => tester
      .widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Send answer'),
      )
      .onPressed;

  const sealed = DeliveryPackageStatus(
    state: DeliveryPackageState.outForDelivery,
    hasSeal: true,
  );
  const unsealed = DeliveryPackageStatus(
    state: DeliveryPackageState.delivered,
    hasSeal: false,
  );

  testWidgets('asks what arrived, with the seal question for a sealed parcel', (
    tester,
  ) async {
    stubChecks(
      package: right(sealed),
      saved: left(const NetworkExceptions.notFound()),
    );

    await pumpCard(tester);

    expect(find.text('Got your parcel?'), findsOneWidget);
    expect(find.text('Was the seal intact?'), findsOneWidget);
    expect(find.text('All good'), findsOneWidget);
    expect(find.text("Something's wrong"), findsOneWidget);
    expect(find.text('Refuse it'), findsOneWidget);
    expect(find.byKey(const ValueKey('acceptance-note')), findsNothing);
    expect(sendAction(tester), isNull);
  });

  testWidgets(
    'a broken seal rules out All good, and an issue needs a note to send',
    (tester) async {
      stubChecks(
        package: right(sealed),
        saved: left(const NetworkExceptions.notFound()),
      );
      final saved = _acceptance(
        DeliveryAcceptanceOutcome.acceptedWithIssue,
        sealIntact: false,
        issueNote: 'Box crushed',
      );
      stubRecord(saved);
      await pumpCard(tester);

      await tester.tap(find.byKey(const ValueKey('acceptance-seal-no')));
      await tester.pump();
      expect(
        find.text('Not available when the seal was broken.'),
        findsOneWidget,
      );
      await tester.tap(find.text('All good'));
      await tester.pump();
      expect(sendAction(tester), isNull);

      await tester.tap(find.text("Something's wrong"));
      await tester.pump();
      expect(find.byKey(const ValueKey('acceptance-note')), findsOneWidget);
      expect(sendAction(tester), isNull);

      await tester.enterText(
        find.byKey(const ValueKey('acceptance-note')),
        'Box crushed',
      );
      await tester.pump();
      expect(sendAction(tester), isNotNull);

      await tester.tap(find.text('Send answer'));
      await tester.pumpAndSettle();

      verify(
        () => repository.recordDeliveryAcceptance(
          _tracking,
          outcome: DeliveryAcceptanceOutcome.acceptedWithIssue,
          sealIntact: false,
          issueNote: 'Box crushed',
        ),
      ).called(1);
      expect(find.text(deliveryAcceptanceSummary(saved)), findsOneWidget);
      expect(find.text('The seal was broken.'), findsOneWidget);
      expect(find.text('Send answer'), findsNothing);
    },
  );

  testWidgets('an unsealed parcel skips the seal question', (tester) async {
    stubChecks(
      package: right(unsealed),
      saved: left(const NetworkExceptions.notFound()),
    );
    final saved = _acceptance(DeliveryAcceptanceOutcome.accepted);
    stubRecord(saved);
    await pumpCard(tester);

    expect(find.text('Was the seal intact?'), findsNothing);
    await tester.tap(find.text('All good'));
    await tester.pump();
    await tester.tap(find.text('Send answer'));
    await tester.pumpAndSettle();

    verify(
      () => repository.recordDeliveryAcceptance(
        _tracking,
        outcome: DeliveryAcceptanceOutcome.accepted,
        sealIntact: null,
        issueNote: null,
      ),
    ).called(1);
    expect(find.text(deliveryAcceptanceSummary(saved)), findsOneWidget);
  });

  testWidgets('shows a saved answer read-only', (tester) async {
    final saved = _acceptance(
      DeliveryAcceptanceOutcome.refused,
      sealIntact: false,
      issueNote: 'Wrong item',
    );
    stubChecks(package: right(sealed), saved: right(saved));

    await pumpCard(tester);

    expect(find.text(deliveryAcceptanceSummary(saved)), findsOneWidget);
    expect(find.text('The seal was broken.'), findsOneWidget);
    expect(find.text('Your note: Wrong item'), findsOneWidget);
    expect(find.text('Got your parcel?'), findsNothing);
    expect(find.text('Send answer'), findsNothing);
  });

  testWidgets('renders nothing when the checks fail', (tester) async {
    stubChecks(
      package: left(const NetworkExceptions.serverUnavailable()),
      saved: left(const NetworkExceptions.serverUnavailable()),
    );

    await pumpCard(tester);

    expect(
      find.byKey(const ValueKey('delivery-acceptance-card')),
      findsNothing,
    );
  });

  testWidgets('renders nothing before the parcel is out for delivery', (
    tester,
  ) async {
    stubChecks(
      package: right(
        const DeliveryPackageStatus(
          state: DeliveryPackageState.inTransit,
          hasSeal: true,
        ),
      ),
      saved: left(const NetworkExceptions.notFound()),
    );

    await pumpCard(tester);

    expect(
      find.byKey(const ValueKey('delivery-acceptance-card')),
      findsNothing,
    );
  });

  testWidgets('order detail shows the card for a delivered StyleMint order', (
    tester,
  ) async {
    useTallView(tester);
    final order = OrderDetail(
      id: 'order-id',
      orderNumber: 'NK2026-00015',
      status: OrderTrackStatus.delivered,
      placedAt: DateTime.utc(2026, 9, 11),
      estimatedDelivery: DateTime.utc(2026, 9, 14),
      items: const [],
      subtotal: const Money(amount: 1000, currency: 'NPR'),
      shipping: const Money(amount: 100, currency: 'NPR'),
      tax: const Money(amount: 0, currency: 'NPR'),
      total: const Money(amount: 1100, currency: 'NPR'),
      shippingAddress: 'Kathmandu, Nepal',
      paymentMethod: 'eSewa',
      trackingNumber: _tracking,
      canCancel: false,
      canReturn: true,
    );
    when(
      () => repository.getOrderDetail('NK2026-00015'),
    ).thenAnswer((_) async => right(order));
    stubChecks(
      package: right(unsealed),
      saved: left(const NetworkExceptions.notFound()),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(repository),
          deliveryStoryProvider.overrideWith(
            (ref, trackingNumber) async => <DeliveryStoryChapter>[],
          ),
        ],
        child: const MaterialApp(
          home: OrderDetailScreen(orderId: 'NK2026-00015'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Got your parcel?'), findsOneWidget);
    expect(find.text('Was the seal intact?'), findsNothing);
  });

  group('deliveryAcceptanceSummary', () {
    test('says what was recorded and when, in local time', () {
      final at = DateTime.utc(2026, 9, 13, 12);
      final day = DateFormat('MMM d, yyyy').format(at.toLocal());

      expect(
        deliveryAcceptanceSummary(
          _acceptance(DeliveryAcceptanceOutcome.accepted),
        ),
        'You accepted this parcel on $day.',
      );
      expect(
        deliveryAcceptanceSummary(
          _acceptance(DeliveryAcceptanceOutcome.acceptedWithIssue),
        ),
        'You kept this parcel and reported a problem on $day.',
      );
      expect(
        deliveryAcceptanceSummary(
          _acceptance(DeliveryAcceptanceOutcome.refused),
        ),
        'You refused this parcel on $day.',
      );
    });

    test('leaves the date out when it is missing', () {
      expect(
        deliveryAcceptanceSummary(
          const DeliveryAcceptance(
            id: 'acc-1',
            packageId: 'pkg-1',
            trackingNumber: _tracking,
            outcome: DeliveryAcceptanceOutcome.accepted,
          ),
        ),
        'You accepted this parcel.',
      );
    });
  });
}
