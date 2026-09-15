import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/customer_returns_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/order_timeline_notifier.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

CustomerReturn returnFixture(String id) => CustomerReturn(
  id: id,
  orderId: 'o-$id',
  orderNumber: 'NK2026-00321',
  subOrderId: 's',
  subOrderLineId: 'l',
  product: const ReturnProductSnapshot(
    productVariantId: 'v',
    title: 'Linen Shirt',
    unitPrice: Money(amount: 1200, currency: 'NPR'),
  ),
  quantity: 1,
  reason: 'Too small',
  photoUrls: const [],
  status: ReturnRequestStatus.submitted,
  submittedUtc: DateTime.utc(2026, 9, 13, 13),
  timeline: const [],
);

PagedResult<CustomerReturn> page(List<String> ids, {String? next}) =>
    PagedResult(
      items: ids.map(returnFixture).toList(),
      totalCount: 99,
      pageSize: ids.length,
      nextCursor: next,
      hasMore: next != null,
    );

final _timeline = OrderTimeline(
  orderNumber: 'NK2026-00412',
  orderState: 3,
  placedUtc: DateTime.utc(2026, 9, 15, 8),
  subOrders: const [],
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _MockOrdersRepository repository;

  setUp(() => repository = _MockOrdersRepository());

  group('OrderTimelineNotifier', () {
    test('loads the timeline for its order number', () async {
      when(
        () => repository.getOrderTimeline('NK2026-00412'),
      ).thenAnswer((_) async => right(_timeline));

      final notifier = OrderTimelineNotifier(repository, 'NK2026-00412');
      expect(notifier.state, const OrderTimelineState.loadInProgress());
      await _settle();

      expect(notifier.state, OrderTimelineState.loadSuccess(_timeline));
    });

    test('a failure ends in loadFailure so the screen can fall back', () async {
      when(() => repository.getOrderTimeline(any())).thenAnswer(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      final notifier = OrderTimelineNotifier(repository, 'NK2026-00412');
      await _settle();

      expect(
        notifier.state,
        const OrderTimelineState.loadFailure(
          NetworkExceptions.serverUnavailable(),
        ),
      );
    });

    test('an unexpected throw is a failure, not a crash', () async {
      when(
        () => repository.getOrderTimeline(any()),
      ).thenThrow(StateError('boom'));

      final notifier = OrderTimelineNotifier(repository, 'NK2026-00412');
      await _settle();

      expect(
        notifier.state,
        const OrderTimelineState.loadFailure(
          NetworkExceptions.unexpectedError(),
        ),
      );
    });

    test('a failed refresh keeps the timeline on screen', () async {
      when(
        () => repository.getOrderTimeline(any()),
      ).thenAnswer((_) async => right(_timeline));
      final notifier = OrderTimelineNotifier(repository, 'NK2026-00412');
      await _settle();

      when(() => repository.getOrderTimeline(any())).thenAnswer(
        (_) async => left(const NetworkExceptions.noInternetConnection()),
      );
      await notifier.refresh();

      expect(notifier.state, OrderTimelineState.loadSuccess(_timeline));
    });
  });

  group('MyReturnsNotifier', () {
    test('loads the first page and pages with the cursor', () async {
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) async => right(page(['a', 'b'], next: 'c1')));
      when(
        () => repository.getMyReturns(cursor: 'c1', pageSize: 20),
      ).thenAnswer((_) async => right(page(['c'])));

      final notifier = MyReturnsNotifier(repository);
      await _settle();

      final first = notifier.state.maybeWhen(
        loadSuccess: (returns, nextCursor, _, _) => (returns, nextCursor),
        orElse: () => null,
      );
      expect(first!.$1.map((r) => r.id), ['a', 'b']);
      expect(first.$2, 'c1');

      await notifier.loadMore();
      final second = notifier.state.maybeWhen(
        loadSuccess: (returns, nextCursor, isLoadingMore, failure) =>
            (returns, nextCursor, isLoadingMore, failure),
        orElse: () => null,
      );
      expect(second!.$1.map((r) => r.id), ['a', 'b', 'c']);
      expect(second.$2, isNull);
      expect(second.$3, isFalse);
      expect(second.$4, isNull);

      // No cursor left: loadMore is a no-op.
      await notifier.loadMore();
      verify(
        () => repository.getMyReturns(cursor: 'c1', pageSize: 20),
      ).called(1);
    });

    test('an empty first page is a success with no rows', () async {
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) async => right(page(const [])));

      final notifier = MyReturnsNotifier(repository);
      await _settle();

      expect(
        notifier.state,
        const MyReturnsState.loadSuccess(<CustomerReturn>[]),
      );
    });

    test('a failed next page keeps the rows and records the failure', () async {
      when(
        () => repository.getMyReturns(pageSize: 20),
      ).thenAnswer((_) async => right(page(['a'], next: 'c1')));
      when(
        () => repository.getMyReturns(cursor: 'c1', pageSize: 20),
      ).thenAnswer(
        (_) async => left(const NetworkExceptions.noInternetConnection()),
      );

      final notifier = MyReturnsNotifier(repository);
      await _settle();
      await notifier.loadMore();

      notifier.state.maybeWhen(
        loadSuccess: (returns, nextCursor, isLoadingMore, failure) {
          expect(returns.map((r) => r.id), ['a']);
          expect(nextCursor, 'c1');
          expect(isLoadingMore, isFalse);
          expect(failure, const NetworkExceptions.noInternetConnection());
        },
        orElse: () => fail('expected loadSuccess, got ${notifier.state}'),
      );
    });

    test('a first-page failure is loadFailure', () async {
      when(() => repository.getMyReturns(pageSize: 20)).thenAnswer(
        (_) async => left(const NetworkExceptions.noInternetConnection()),
      );

      final notifier = MyReturnsNotifier(repository);
      await _settle();

      expect(
        notifier.state,
        const MyReturnsState.loadFailure(
          NetworkExceptions.noInternetConnection(),
        ),
      );
    });
  });

  group('ReturnDetailNotifier', () {
    test('loads one return by id', () async {
      final r = returnFixture('c1f2');
      when(
        () => repository.getReturn('c1f2'),
      ).thenAnswer((_) async => right(r));

      final notifier = ReturnDetailNotifier(repository, 'c1f2');
      await _settle();

      expect(notifier.state, ReturnDetailState.loadSuccess(r));
    });

    test('404 is a loadFailure(notFound)', () async {
      when(
        () => repository.getReturn(any()),
      ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

      final notifier = ReturnDetailNotifier(repository, 'missing');
      await _settle();

      expect(
        notifier.state,
        const ReturnDetailState.loadFailure(NetworkExceptions.notFound()),
      );
    });
  });
}
