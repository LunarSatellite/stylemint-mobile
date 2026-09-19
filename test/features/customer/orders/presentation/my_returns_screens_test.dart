import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/my_returns_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/return_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/tracking_step_list.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

import '../../../orders_test_harness.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

CustomerReturn _return(
  String id, {
  ReturnRequestStatus status = ReturnRequestStatus.submitted,
  String title = 'Linen Shirt',
  String reason = 'Too small',
  List<String> photoUrls = const [],
  String? rejectionNote,
  List<ReturnTimelineEntry> timeline = const [],
}) => CustomerReturn(
  id: id,
  orderId: 'o-$id',
  orderNumber: 'NK2026-00321',
  subOrderId: 's',
  subOrderLineId: 'l',
  product: ReturnProductSnapshot(
    productVariantId: 'v',
    title: title,
    variantLabel: 'M / Blue',
    unitPrice: const Money(amount: 1200, currency: 'NPR'),
  ),
  quantity: 1,
  reason: reason,
  photoUrls: photoUrls,
  status: status,
  submittedUtc: DateTime.utc(2026, 9, 13, 13),
  resolvedUtc: status == ReturnRequestStatus.rejected
      ? DateTime.utc(2026, 9, 15, 9)
      : null,
  rejectionNote: rejectionNote,
  timeline: timeline,
);

PagedResult<CustomerReturn> _page(
  List<CustomerReturn> items, {
  String? next,
}) => PagedResult(
  items: items,
  totalCount: items.length,
  pageSize: 20,
  nextCursor: next,
  hasMore: next != null,
);

Widget _app(
  _MockOrdersRepository repository,
  Widget screen, {
  double textScale = 1,
}) => ProviderScope(
  overrides: [
    ordersRepositoryProvider.overrideWithValue(repository),
    returnPickupProvider.overrideWith((ref, returnId) async => null),
    replacementShipmentProvider.overrideWith((ref, returnId) async => null),
  ],
  child: ordersTestApp(screen, textScale: textScale, wrapInScaffold: false),
);

void main() {
  late _MockOrdersRepository repository;

  setUp(() => repository = _MockOrdersRepository());

  group('MyReturnsScreen', () {
    testWidgets('shows a skeleton while loading', (tester) async {
      setPhoneView(tester);
      final pending =
          Completer<Either<NetworkExceptions, PagedResult<CustomerReturn>>>();
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) => pending.future);

      await tester.pumpWidget(_app(repository, const MyReturnsScreen()));
      await tester.pump();

      expect(find.bySemanticsLabel('Loading returns'), findsOneWidget);
      expect(find.byType(ReturnListTile), findsNothing);

      pending.complete(right(_page(const [])));
      await tester.pump();
    });

    testWidgets('empty state points back to My Orders', (tester) async {
      setPhoneView(tester);
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) async => right(_page(const [])));

      await tester.pumpWidget(_app(repository, const MyReturnsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No returns yet'), findsOneWidget);
      expect(find.text('View my orders'), findsOneWidget);
    });

    testWidgets('offline error retries', (tester) async {
      setPhoneView(tester);
      when(() => repository.getMyReturns(pageSize: 20)).thenAnswer(
        (_) async => left(const NetworkExceptions.noInternetConnection()),
      );

      await tester.pumpWidget(_app(repository, const MyReturnsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('You’re offline'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      verify(() => repository.getMyReturns(pageSize: 20)).called(2);
    });

    testWidgets('rows show thumb, name, quantity, reason, pill and date', (
      tester,
    ) async {
      setPhoneView(tester);
      when(() => repository.getMyReturns(pageSize: 20)).thenAnswer(
        (_) async => right(
          _page([
            _return('a'),
            _return(
              'b',
              status: ReturnRequestStatus.rejected,
              title: 'Canvas tote',
              reason: 'Arrived torn',
            ),
          ]),
        ),
      );

      await tester.pumpWidget(_app(repository, const MyReturnsScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ReturnListTile), findsNWidgets(2));
      expect(find.text('Linen Shirt'), findsOneWidget);
      expect(find.text('Qty 1 · Too small'), findsOneWidget);
      expect(find.text('Qty 1 · Arrived torn'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      // 13:00 UTC on 13 Sep is 18:45 the same day in Kathmandu.
      expect(find.text('13 Sep 2026'), findsNWidgets(2));
    });

    testWidgets('loads the next page with the cursor', (tester) async {
      setPhoneView(tester);
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) async => right(_page([_return('a')], next: 'c1')));
      when(
        () => repository.getMyReturns(cursor: 'c1', pageSize: 20),
      ).thenAnswer(
        (_) async => right(_page([_return('b', title: 'Canvas tote')])),
      );

      await tester.pumpWidget(_app(repository, const MyReturnsScreen()));
      await tester.pumpAndSettle();

      verify(
        () => repository.getMyReturns(cursor: 'c1', pageSize: 20),
      ).called(1);
      expect(find.text('Canvas tote'), findsOneWidget);
      expect(find.byType(ReturnListTile), findsNWidgets(2));
    });

    testWidgets('a failed next page offers Retry', (tester) async {
      setPhoneView(tester);
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) async => right(_page([_return('a')], next: 'c1')));
      when(
        () => repository.getMyReturns(cursor: 'c1', pageSize: 20),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      await tester.pumpWidget(_app(repository, const MyReturnsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Couldn’t load more returns.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      setPhoneView(tester, width: 320);
      when(() => repository.getMyReturns(pageSize: 20)).thenAnswer(
        (_) async => right(
          _page([
            _return(
              'a',
              status: ReturnRequestStatus.completed,
              title:
                  'Oversized linen co-ord set in washed sand with contrast '
                  'stitching',
              reason:
                  'The fit runs much smaller than the size guide suggests '
                  'and the colour is different',
            ),
          ]),
        ),
      );

      await tester.pumpWidget(
        _app(repository, const MyReturnsScreen(), textScale: 1.3),
      );
      await tester.pumpAndSettle();

      expectNoLayoutErrors(tester);
    });
  });

  group('ReturnDetailScreen', () {
    testWidgets('shows photos, reason, timeline and the refund placeholder', (
      tester,
    ) async {
      setPhoneView(tester);
      when(() => repository.getReturn('c1f2')).thenAnswer(
        (_) async => right(
          _return(
            'c1f2',
            status: ReturnRequestStatus.rejected,
            photoUrls: const ['https://cdn.example.com/r1.jpg'],
            rejectionNote: 'Item shows signs of wear',
            timeline: [
              ReturnTimelineEntry(
                status: ReturnRequestStatus.submitted,
                occurredUtc: DateTime.utc(2026, 9, 13, 13),
              ),
              ReturnTimelineEntry(
                status: ReturnRequestStatus.rejected,
                occurredUtc: DateTime.utc(2026, 9, 15, 9),
              ),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        _app(repository, const ReturnDetailScreen(returnId: 'c1f2')),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('REASON'), findsOneWidget);
      expect(find.text('Too small'), findsOneWidget);
      expect(find.bySemanticsLabel('Return photo 1 of 1'), findsOneWidget);
      expect(find.text('Order #NK2026-00321'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(refundPendingCopy),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Return rejected'), findsOneWidget);
      expect(find.text('Item shows signs of wear'), findsOneWidget);
      // 09:00 UTC -> 2:45 PM in Kathmandu.
      expect(find.text('Tue 15 Sep, 2:45 PM'), findsOneWidget);
      expect(find.text(refundPendingCopy), findsOneWidget);
    });

    testWidgets('shows the refund status when the backend sends one', (
      tester,
    ) async {
      setPhoneView(tester);
      final base = _return('r2', status: ReturnRequestStatus.completed);
      when(() => repository.getReturn('r2')).thenAnswer(
        (_) async => right(
          CustomerReturn(
            id: base.id,
            orderId: base.orderId,
            orderNumber: base.orderNumber,
            subOrderId: base.subOrderId,
            subOrderLineId: base.subOrderLineId,
            product: base.product,
            quantity: base.quantity,
            reason: base.reason,
            photoUrls: const [],
            status: base.status,
            submittedUtc: base.submittedUtc,
            timeline: const [],
            refundStatus: 'Refunded to eSewa',
          ),
        ),
      );

      await tester.pumpWidget(
        _app(repository, const ReturnDetailScreen(returnId: 'r2')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Refunded to eSewa'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Refunded to eSewa'), findsOneWidget);
      expect(find.text(refundPendingCopy), findsNothing);
    });

    test('state timeline steps follow the return state', () {
      List<TrackingStepState> states(ReturnRequestStatus status) =>
          ReturnDetailScreen.stepsFor(
            _return('x', status: status),
          ).map((s) => s.state).toList();

      expect(states(ReturnRequestStatus.submitted), [
        TrackingStepState.current,
        TrackingStepState.upcoming,
        TrackingStepState.upcoming,
      ]);
      expect(states(ReturnRequestStatus.approved), [
        TrackingStepState.done,
        TrackingStepState.current,
        TrackingStepState.upcoming,
      ]);
      expect(states(ReturnRequestStatus.completed), [
        TrackingStepState.done,
        TrackingStepState.done,
        TrackingStepState.done,
      ]);
      final rejected = ReturnDetailScreen.stepsFor(
        _return('x', status: ReturnRequestStatus.rejected),
      );
      expect(rejected, hasLength(2));
      expect(rejected.last.tone, TrackingStepTone.negative);
    });

    testWidgets('not found shows its own message', (tester) async {
      setPhoneView(tester);
      when(
        () => repository.getReturn('missing'),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      await tester.pumpWidget(
        _app(repository, const ReturnDetailScreen(returnId: 'missing')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not found'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      setPhoneView(tester, width: 320);
      when(() => repository.getReturn('long')).thenAnswer(
        (_) async => right(
          _return(
            'long',
            status: ReturnRequestStatus.approved,
            title:
                'Oversized linen co-ord set in washed sand with contrast '
                'stitching',
            reason:
                'The fit runs much smaller than the size guide suggests and '
                'the colour is different from the photos',
            photoUrls: const [
              'https://cdn.example.com/r1.jpg',
              'https://cdn.example.com/r2.jpg',
              'https://cdn.example.com/r3.jpg',
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        _app(
          repository,
          const ReturnDetailScreen(returnId: 'long'),
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump();

      expectNoLayoutErrors(tester);
    });
  });
}
