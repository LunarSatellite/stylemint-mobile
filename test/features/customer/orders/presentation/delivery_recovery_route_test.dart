import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/tracked_order_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/delivery_recovery_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/routes/route_path_match.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

class _MockOrdersDataSource extends Mock implements OrdersRemoteDataSource {}

const String _tracking = 'SM-D-00000001';
const String _orderNumber = 'NK2026-00015';

/// The link the backend puts in the "your delivery is at risk" push.
const String _deepLink = 'stylemint://delivery/$_tracking/recovery';

OrderDetail _order() => OrderDetail(
  id: 'order-id',
  orderNumber: _orderNumber,
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
  trackingNumber: _tracking,
  canCancel: false,
  canReturn: false,
);

Map<String, dynamic> _riskJson({required bool atRisk}) => <String, dynamic>{
  'atRisk': atRisk,
  'riskReasonCode': atRisk ? 'delivery.risk.deadline_passed' : null,
  'customerMessage': atRisk
      ? 'This parcel is running later than promised.'
      : 'On track for Sunday.',
  'recommendedAction': atRisk ? 'Choose what you would like us to do.' : null,
  'remedies': atRisk
      ? [
          <String, dynamic>{
            'offerId': 'offer-cancel',
            'trackingNumber': _tracking,
            'remedy': 'CancelForRefund',
            'status': 'Offered',
            'riskReasonCode': 'delivery.risk.deadline_passed',
            'description':
                'We can stop this delivery now and refund you in full.',
            'requiresRefundWindowAcknowledgement': true,
            'offeredUtc': DateTime.now().toUtc().toIso8601String(),
            'expiresUtc': DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 20))
                .toIso8601String(),
          },
        ]
      : const <Map<String, dynamic>>[],
};

_MockOrdersRepository _repository() {
  final repository = _MockOrdersRepository();
  when(
    () => repository.getOrderDetail(_orderNumber),
  ).thenAnswer((_) async => right(_order()));
  when(() => repository.getOrderTimeline(_orderNumber)).thenAnswer(
    (_) async => left(const NetworkExceptions.serverUnavailable()),
  );
  return repository;
}

/// The real route patterns and the real screens, wired the way
/// `app_router.dart` wires them. The router there needs the whole auth stack
/// to build, so the wiring itself is checked as text below.
Widget _app({
  required String? resolvedOrderNumber,
  required bool atRisk,
}) => ProviderScope(
  overrides: [
    ordersRepositoryProvider.overrideWithValue(_repository()),
    orderNumberForTrackingProvider.overrideWith(
      (ref, trackingNumber) async =>
          trackingNumber == _tracking ? resolvedOrderNumber : null,
    ),
    deliveryRiskProvider.overrideWith(
      (ref, tracking) async =>
          DeliveryRiskAssessment.fromJson(_riskJson(atRisk: atRisk)),
    ),
    deliveryStoryProvider.overrideWith(
      (ref, tracking) async => const <DeliveryStoryChapter>[],
    ),
    packageSealProvider.overrideWith((ref, tracking) async => null),
  ],
  child: MaterialApp.router(
    routerConfig: GoRouter(
      initialLocation: '/delivery/$_tracking/recovery',
      routes: [
        GoRoute(
          path: RouteNames.deliveryRecovery,
          builder: (ctx, state) => DeliveryRecoveryScreen(
            trackingNumber: state.pathParameters['trackingNumber']!,
          ),
        ),
        GoRoute(
          path: RouteNames.orderDetail,
          builder: (ctx, state) => OrderDetailScreen(
            orderId: state.pathParameters['orderId']!,
            focusDeliveryRecovery:
                state.uri.queryParameters['focus'] ==
                RouteNames.orderDetailFocusRecovery,
          ),
        ),
        GoRoute(
          path: RouteNames.orders,
          builder: (ctx, state) => const Scaffold(body: Text('Track orders')),
        ),
      ],
    ),
  ),
);

void main() {
  late final routerSource = File(
    'lib/routes/app_router.dart',
  ).readAsStringSync();

  group('the at-risk delivery deep link', () {
    test('the push link normalizes onto the registered route', () {
      // main.dart turns `stylemint://delivery/x/recovery` into
      // `/delivery/x/recovery` before handing it to GoRouter.
      final uri = Uri.parse(_deepLink);
      final path = '/${uri.host}${uri.path}';
      expect(path, '/delivery/$_tracking/recovery');
      expect(routePathMatches(path, RouteNames.deliveryRecovery), isTrue);
    });

    test('the route is registered and builds the recovery screen', () {
      expect(
        routerSource.contains('path: RouteNames.deliveryRecovery'),
        isTrue,
        reason: 'the notification would open to nothing',
      );
      expect(routerSource.contains('DeliveryRecoveryScreen('), isTrue);
      expect(
        routerSource.contains('RouteNames.orderDetailFocusRecovery'),
        isTrue,
        reason: 'order detail must read the focus flag off the query',
      );
    });

    test('signed out: the route is not public, so it asks for sign-in', () {
      final publicList = routerSource.substring(
        routerSource.indexOf('const _publicPaths = {'),
        routerSource.indexOf('const _authOnlyPaths = {'),
      );
      expect(
        publicList.contains('RouteNames.deliveryRecovery'),
        isFalse,
        reason: "recovery offers are the customer's own",
      );
    });

    testWidgets('lands on the order with the recovery offers in view', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(resolvedOrderNumber: _orderNumber, atRisk: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(
        find.text('This parcel is running later than promised.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('stop this delivery now'),
        findsOneWidget,
      );

      // Scrolled to, not left below the fold.
      final offerTop = tester.getTopLeft(
        find.text('This parcel is running later than promised.'),
      );
      final viewportHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(offerTop.dy, lessThan(viewportHeight));
    });

    testWidgets('an unknown tracking number lands on a plain explanation', (
      tester,
    ) async {
      await tester.pumpWidget(_app(resolvedOrderNumber: null, atRisk: true));
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsNothing);
      expect(find.textContaining("couldn't find delivery"), findsOneWidget);
      expect(find.text('Track orders'), findsOneWidget);

      await tester.tap(find.text('Track orders'));
      await tester.pumpAndSettle();
      expect(find.text('Track orders'), findsOneWidget);
    });

    testWidgets('a delivery that recovered says so instead of going blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(resolvedOrderNumber: _orderNumber, atRisk: false),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsOneWidget);
      expect(find.textContaining('stop this delivery now'), findsNothing);
      expect(find.textContaining('back on track'), findsOneWidget);
    });
  });

  group('resolving a tracking number to an order', () {
    ProviderContainer containerWith(_MockOrdersDataSource dataSource) {
      final container = ProviderContainer(
        overrides: [
          ordersRemoteDataSourceProvider.overrideWithValue(dataSource),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    _MockOrdersDataSource dataSourceWith({required String? tracking}) {
      final dataSource = _MockOrdersDataSource();
      when(() => dataSource.getTrackedOrders(limit: any(named: 'limit')))
          .thenAnswer(
            (_) async => [
              TrackedOrderDto(
                id: 'order-id',
                orderNumber: _orderNumber,
                placedUtc: DateTime.utc(2026, 9, 11),
                state: 3,
              ),
            ],
          );
      when(() => dataSource.getOrderDetail(_orderNumber)).thenAnswer(
        (_) async => OrderDetailDto(
          id: 'order-id',
          orderNumber: _orderNumber,
          placedUtc: DateTime.utc(2026, 9, 11),
          subOrders: [SubOrderDto(id: 'sub-1', trackingNumber: tracking)],
        ),
      );
      return dataSource;
    }

    test('the customer own parcel resolves to its order number', () async {
      final container = containerWith(dataSourceWith(tracking: _tracking));
      expect(
        await container.read(
          orderNumberForTrackingProvider(_tracking).future,
        ),
        _orderNumber,
      );
    });

    test("someone else's parcel resolves to nothing", () async {
      // `/v1/orders` is scoped to the caller, so a stranger's tracking
      // number never appears among their orders.
      final container = containerWith(dataSourceWith(tracking: 'SM-D-999'));
      expect(
        await container.read(
          orderNumberForTrackingProvider(_tracking).future,
        ),
        isNull,
      );
    });
  });
}
