import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracking_lookup.dart';
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
  required TrackingLookup lookup,
  required bool atRisk,
}) => ProviderScope(
  overrides: [
    ordersRepositoryProvider.overrideWithValue(_repository()),
    orderNumberForTrackingProvider.overrideWith(
      (ref, trackingNumber) async => trackingNumber == _tracking
          ? lookup
          : const TrackingLookupNotFound(),
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
        _app(lookup: const TrackingLookupResolved(_orderNumber), atRisk: true),
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
      await tester.pumpWidget(
        _app(lookup: const TrackingLookupNotFound(), atRisk: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsNothing);
      expect(find.textContaining("couldn't find delivery"), findsOneWidget);
      expect(find.text('Track orders'), findsOneWidget);

      await tester.tap(find.text('Track orders'));
      await tester.pumpAndSettle();
      expect(find.text('Track orders'), findsOneWidget);
    });

    testWidgets('being rate limited is not the same as not found', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(lookup: const TrackingLookupRateLimited(), atRisk: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OrderDetailScreen), findsNothing);
      // The customer is told to come back, not that the parcel is unknown.
      expect(find.textContaining("couldn't find delivery"), findsNothing);
      expect(find.textContaining('try again'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('a delivery that recovered says so instead of going blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(lookup: const TrackingLookupResolved(_orderNumber), atRisk: false),
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

    DioException statusError(int code) => DioException(
      requestOptions: RequestOptions(path: '/v1/orders/by-tracking/$_tracking'),
      response: Response<dynamic>(
        requestOptions: RequestOptions(
          path: '/v1/orders/by-tracking/$_tracking',
        ),
        statusCode: code,
      ),
    );

    test('one call answers it, and it is the only call made', () async {
      final dataSource = _MockOrdersDataSource();
      when(
        () => dataSource.resolveOrderNumberByTracking(_tracking),
      ).thenAnswer((_) async => _orderNumber);

      final lookup = await containerWith(
        dataSource,
      ).read(orderNumberForTrackingProvider(_tracking).future);

      expect(lookup, isA<TrackingLookupResolved>());
      expect((lookup as TrackingLookupResolved).orderNumber, _orderNumber);
      verify(
        () => dataSource.resolveOrderNumberByTracking(_tracking),
      ).called(1);
      // No orders list, no order detail reads: the fan-out is gone.
      verifyNoMoreInteractions(dataSource);
    });

    test('a 404 is the one not-found answer, whatever caused it', () async {
      // Unknown, someone else's, unreadable: identical response, and the
      // client must not try to tell them apart.
      final dataSource = _MockOrdersDataSource();
      when(
        () => dataSource.resolveOrderNumberByTracking(_tracking),
      ).thenThrow(statusError(404));

      expect(
        await containerWith(
          dataSource,
        ).read(orderNumberForTrackingProvider(_tracking).future),
        isA<TrackingLookupNotFound>(),
      );
      verify(
        () => dataSource.resolveOrderNumberByTracking(_tracking),
      ).called(1);
      verifyNoMoreInteractions(dataSource);
    });

    test('a 429 is its own answer, not a not-found', () async {
      final dataSource = _MockOrdersDataSource();
      when(
        () => dataSource.resolveOrderNumberByTracking(_tracking),
      ).thenThrow(statusError(429));

      expect(
        await containerWith(
          dataSource,
        ).read(orderNumberForTrackingProvider(_tracking).future),
        isA<TrackingLookupRateLimited>(),
      );
    });

    test('a blank tracking number never spends a call', () async {
      final dataSource = _MockOrdersDataSource();
      expect(
        await containerWith(
          dataSource,
        ).read(orderNumberForTrackingProvider('   ').future),
        isA<TrackingLookupNotFound>(),
      );
      verifyNever(() => dataSource.resolveOrderNumberByTracking(any()));
    });

    test('nothing in the client caps how far back the lookup looks', () {
      final providers = File(
        'lib/features/customer/orders/shared/providers.dart',
      ).readAsStringSync();

      expect(
        providers.contains('resolveOrderNumberByTracking'),
        isTrue,
        reason: 'the single-call lookup is what resolves the deep link',
      );
      for (final gone in const [
        'getTrackedOrders',
        'getOrderDetail',
        '_trackingLookupDetailBudget',
      ]) {
        expect(
          providers.contains(gone),
          isFalse,
          reason: '$gone is part of the deleted client-side scan',
        );
      }

      // And it is gone from lib/ entirely, not just moved next door.
      final strays = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) => f.readAsStringSync().contains('_trackingLookupDetailBudget'),
          )
          .map((f) => f.path)
          .toList();
      expect(strays, isEmpty);
    });
  });
}
