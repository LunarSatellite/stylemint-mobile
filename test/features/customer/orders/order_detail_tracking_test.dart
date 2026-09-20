import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_timeline_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_event_history.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import 'data/order_timeline_dto_test.dart' show contractTimelineJson;

class _MockOrdersRepository extends Mock implements OrdersRepository {}

OrderDetail _order({
  OrderTrackStatus status = OrderTrackStatus.inTransit,
}) => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: status,
  placedAt: DateTime.utc(2026, 9, 11),
  estimatedDelivery: DateTime.utc(2026, 9, 14),
  items: const [],
  subtotal: const Money(amount: 1000, currency: 'NPR'),
  shipping: const Money(amount: 100, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  total: const Money(amount: 1100, currency: 'NPR'),
  shippingAddress: 'Kathmandu, Nepal',
  paymentMethod: 'eSewa',
  trackingNumber: 'SM-D-00000001',
  canCancel: true,
  canReturn: false,
);

Widget _screen(
  _MockOrdersRepository repository, {
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    ordersRepositoryProvider.overrideWithValue(repository),
    deliveryStoryProvider.overrideWith(
      (ref, trackingNumber) async => [
        DeliveryStoryChapter(
          sequence: 1,
          kind: DeliveryStoryChapterKind.pickedUp,
          title: 'Package prepared for delivery',
          subtitle: 'Your StyleMint order is ready for its journey.',
          occurredUtc: DateTime.utc(2026, 9, 11),
        ),
      ],
    ),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: const OrderDetailScreen(orderId: 'NK2026-00015'),
    ),
  ),
);

/// Wires a repository that answers with [order] and has no backend timeline,
/// so the screen falls back to its own derived stages.
_MockOrdersRepository _repositoryFor(OrderDetail order) {
  final repository = _MockOrdersRepository();
  when(
    () => repository.getOrderDetail('NK2026-00015'),
  ).thenAnswer((_) async => right(order));
  when(() => repository.getOrderTimeline('NK2026-00015')).thenAnswer(
    (_) async => left(const NetworkExceptions.serverUnavailable()),
  );
  // The recorded history: placed, then cancelled. Nothing in between, because
  // nothing in between was ever recorded.
  when(() => repository.getOrderEventHistory('NK2026-00015')).thenAnswer(
    (_) async => right(
      OrderEventHistory(
        orderNumber: 'NK2026-00015',
        orderState: 5,
        placedUtc: DateTime.utc(2026, 9, 11, 9, 15),
        events: [
          OrderEvent(
            sequence: 1,
            code: 'order_placed',
            statement: 'You placed this order.',
            occurredUtc: DateTime.utc(2026, 9, 11, 9, 15),
            source: 'order',
          ),
          OrderEvent(
            sequence: 2,
            code: 'cancelled',
            statement: 'This order was cancelled.',
            occurredUtc: DateTime.utc(2026, 9, 12, 14, 30),
            source: 'cancellation_request',
          ),
        ],
        sources: const [
          OrderEventSource(name: 'order', status: OrderEventSourceStatus.ok),
        ],
      ),
    ),
  );
  return repository;
}

void main() {
  testWidgets('delivery shortcut scrolls to the real StyleMint timeline', (
    tester,
  ) async {
    final repository = _MockOrdersRepository();
    when(
      () => repository.getOrderDetail('NK2026-00015'),
    ).thenAnswer((_) async => right(_order()));
    // The backend timeline is unavailable: the derived stages stay.
    when(() => repository.getOrderTimeline('NK2026-00015')).thenAnswer(
      (_) async => left(const NetworkExceptions.serverUnavailable()),
    );

    await tester.pumpWidget(_screen(repository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('View other details'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View other details'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('View Delivery Tracking'),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Live StyleMint package updates'), findsOneWidget);
    expect(find.textContaining('FedEx'), findsNothing);
    expect(find.text('Live Delivery Updates'), findsOneWidget);
    for (var index = 0; index < 4; index++) {
      expect(
        find.byKey(ValueKey('delivery-stage-icon-$index')),
        findsOneWidget,
      );
    }
    expect(find.byIcon(Icons.back_hand_outlined), findsWidgets);
    await tester.tap(find.text('View Delivery Tracking'));
    await tester.pumpAndSettle();

    final timelineTop = tester.getTopLeft(find.text('Tracking Timeline')).dy;
    expect(timelineTop, greaterThanOrEqualTo(kToolbarHeight));
    expect(timelineTop, lessThan(200));
  });

  testWidgets('the backend timeline replaces the derived stages', (
    tester,
  ) async {
    final repository = _MockOrdersRepository();
    when(
      () => repository.getOrderDetail('NK2026-00015'),
    ).thenAnswer((_) async => right(_order()));
    when(() => repository.getOrderTimeline('NK2026-00015')).thenAnswer(
      (_) async => right(
        OrderTimelineDto.fromJson({
          ...contractTimelineJson,
          'orderNumber': 'NK2026-00015',
        }).toDomain(),
      ),
    );

    await tester.pumpWidget(_screen(repository));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(OrderTrackingTimeline),
      250,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byType(OrderTrackingTimeline), findsOneWidget);
    expect(find.text('With the courier'), findsOneWidget);
    expect(find.text('Tracking Timeline'), findsNothing);
    expect(find.byKey(const ValueKey('delivery-stage-icon-0')), findsNothing);
    // Live delivery updates still show beneath the new timeline.
    await tester.scrollUntilVisible(
      find.text('Live Delivery Updates'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Live Delivery Updates'), findsOneWidget);
  });

  testWidgets('the order state leads the page and is named in words', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _screen(_repositoryFor(_order(status: OrderTrackStatus.outForDelivery))),
    );
    await tester.pumpAndSettle();

    // The state, not the paperwork, is the first thing on the page.
    expect(find.byType(MallStatusSummary), findsOneWidget);
    final summaryTop = tester.getTopLeft(find.byType(MallStatusSummary)).dy;
    final numberTop = tester
        .getTopLeft(find.textContaining('NK2026-00015').first)
        .dy;
    expect(summaryTop, lessThanOrEqualTo(numberTop));

    // And it is carried by a glyph and a word, not only by a colour.
    expect(
      find.descendant(
        of: find.byType(MallStatusSummary),
        matching: find.byIcon(
          OrderStatusBadge.iconFor(OrderTrackStatus.outForDelivery),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Out for Delivery', caseSensitive: false)),
      findsWidgets,
    );
    semantics.dispose();
  });

  testWidgets('a cancelled order says where the money went', (tester) async {
    await tester.pumpWidget(
      _screen(_repositoryFor(_order(status: OrderTrackStatus.cancelled))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelled'), findsWidgets);
    // The refund is signed and glyphed, never a bare number.
    expect(find.text('+Rs 1,100.00'), findsOneWidget);
    expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
    // Two rungs, because two things were recorded. There is no third stage
    // standing in for a shipment that never happened.
    expect(find.byKey(const ValueKey('delivery-stage-icon-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('delivery-stage-icon-2')), findsNothing);
    expect(find.text('This order was cancelled.'), findsOneWidget);
  });

  testWidgets('order detail does not overflow at 320dp with text ×1.3', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _screen(
        _repositoryFor(_order(status: OrderTrackStatus.outForDelivery)),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the cancelled view does not overflow at 320dp with text ×1.3', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _screen(
        _repositoryFor(_order(status: OrderTrackStatus.cancelled)),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('order detail draws no uncached network image', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _screen(
        _repositoryFor(_order(status: OrderTrackStatus.outForDelivery)),
        textScale: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    // Raw Image.network gave no placeholder, so a grey box arrived late and
    // shifted the row it sat in. Every thumbnail on this screen now goes
    // through MallNetworkImage, which holds its box from the first frame.
    expect(
      find.byType(Image),
      findsNothing,
      reason: 'an uncached Image.network crept back into order detail',
    );
    expect(tester.takeException(), isNull);
  });
}
