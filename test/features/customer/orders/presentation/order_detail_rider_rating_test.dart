import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/presentation/widgets/rider_rating_card.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../orders_test_harness.dart';
import '../../../rider_ratings/fake_rider_rating_repository.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

OrderDetail _order({
  OrderTrackStatus status = OrderTrackStatus.delivered,
  OrderDelivery? delivery,
}) => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: status,
  placedAt: DateTime.utc(2026, 10, 1),
  estimatedDelivery: DateTime.utc(2026, 10, 9),
  items: const [],
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

OrderDelivery _delivery({RiderRatingEligibility? rating}) => OrderDelivery(
  packageNumber: 'SM-D-00000013',
  status: 'Delivered',
  riderName: 'Ram',
  awaitingConfirmation: false,
  subOrderId: 'sub-1',
  riderRating: rating,
);

Widget _screen(OrderDetail order, FakeRiderRatingRepository ratings) {
  final repository = _MockOrdersRepository();
  when(
    () => repository.getOrderDetail('NK2026-00015'),
  ).thenAnswer((_) async => right(order));
  when(() => repository.getOrderTimeline('NK2026-00015')).thenAnswer(
    (_) async => left(const NetworkExceptions.serverUnavailable()),
  );
  return ProviderScope(
    overrides: [
      ordersRepositoryProvider.overrideWithValue(repository),
      riderRatingRepositoryProvider.overrideWithValue(ratings),
      deliveryStoryProvider.overrideWith((ref, trackingNumber) async => []),
    ],
    child: ordersTestApp(
      const OrderDetailScreen(orderId: 'NK2026-00015'),
      wrapInScaffold: false,
    ),
  );
}

void main() {
  late FakeRiderRatingRepository ratings;

  setUp(() => ratings = FakeRiderRatingRepository());

  testWidgets('delivered by a rider who can be rated: "How was your rider?"', (
    tester,
  ) async {
    setPhoneView(tester);
    await tester.pumpWidget(
      _screen(
        _order(
          delivery: _delivery(
            rating: const RiderRatingEligibility(canRateRider: true),
          ),
        ),
        ratings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How was your rider?'), findsOneWidget);
    expect(find.text('Ram delivered your parcel'), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('already rated: the rating as given', (tester) async {
    setPhoneView(tester);
    await tester.pumpWidget(
      _screen(
        _order(
          delivery: _delivery(
            rating: const RiderRatingEligibility(
              canRateRider: true,
              rating: RiderRatingBrief(
                stars: 5,
                tags: [RiderRatingTag.onTime],
              ),
            ),
          ),
        ),
        ratings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How was your rider?'), findsNothing);
    expect(find.text('Your rating of your rider'), findsOneWidget);
    expect(find.byKey(RiderRatingCard.editKey), findsOneWidget);
  });

  testWidgets('a backend without ratings: no card at all', (tester) async {
    setPhoneView(tester);
    await tester.pumpWidget(_screen(_order(delivery: _delivery()), ratings));
    await tester.pumpAndSettle();

    expect(find.byType(RiderRatingCard), findsNothing);
    expect(find.text('How was your rider?'), findsNothing);
  });

  testWidgets('not eligible (no StyleMint rider): no card', (tester) async {
    setPhoneView(tester);
    await tester.pumpWidget(
      _screen(
        _order(
          delivery: _delivery(
            rating: const RiderRatingEligibility(canRateRider: false),
          ),
        ),
        ratings,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('How was your rider?'), findsNothing);
  });
}
