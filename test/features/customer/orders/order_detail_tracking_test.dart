import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_timeline_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'data/order_timeline_dto_test.dart' show contractTimelineJson;

class _MockOrdersRepository extends Mock implements OrdersRepository {}

OrderDetail _order() => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: OrderTrackStatus.inTransit,
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

Widget _screen(_MockOrdersRepository repository) => ProviderScope(
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
  child: const MaterialApp(home: OrderDetailScreen(orderId: 'NK2026-00015')),
);

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
      find.text('View Other Details'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('View Other Details'));
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
}
