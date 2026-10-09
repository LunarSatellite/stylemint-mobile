import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_delivery_refresh.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class _MockRepository extends Mock implements VendorOrdersRepository {}

VendorOrder _order(VendorOrderStatus status) => VendorOrder(
  id: 's-1',
  orderNumber: 'NK-1',
  itemCount: 1,
  total: const Money(amount: 1, currency: 'NPR'),
  status: status,
);

PagedResult<VendorOrder> _page(VendorOrderStatus status) => PagedResult(
  items: [_order(status)],
  totalCount: 1,
  pageSize: 20,
  hasMore: false,
);

void main() {
  late _MockRepository repository;

  setUp(() => repository = _MockRepository());

  Future<WidgetRef> pumpRef(WidgetTester tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorOrdersRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return captured;
  }

  testWidgets('Shipped becomes Delivered on a live signal, with no loader', (
    tester,
  ) async {
    var status = VendorOrderStatus.shipped;
    when(
      () => repository.getOrders(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => right(_page(status)));
    when(
      () => repository.getOrderDetail('s-1'),
    ).thenAnswer((_) async => right(_order(status)));

    final ref = await pumpRef(tester);
    // Both vendor views are alive, as when the vendor has the order open.
    ref.read(vendorOrdersNotifierProvider);
    await ref.read(vendorOrderDetailNotifierProvider.notifier).loadOrder('s-1');
    await tester.pumpAndSettle();

    status = VendorOrderStatus.delivered;
    final seen = <String>[];
    ref
      ..listenManual(
        vendorOrderDetailNotifierProvider,
        (_, next) => seen.add(
          next.maybeWhen(
            loadSuccess: (o) => o.status.name,
            orElse: () => 'other',
          ),
        ),
      )
      ..listenManual(
        vendorOrdersNotifierProvider,
        (_, next) => seen.add(
          next.maybeWhen(
            loadSuccess: (orders, _, _, _) =>
                'list:${orders.single.status.name}',
            orElse: () => 'list:other',
          ),
        ),
      );

    refreshVendorOrdersLive(
      ref,
      const LiveSignal(
        type: 'order.updated',
        scopes: [LiveScope.buyerOrders, LiveScope.vendorOrders],
        subOrderId: 's-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(seen, containsAll(['delivered', 'list:delivered']));
    expect(seen, isNot(contains('other')), reason: 'no loader flash');
    expect(seen, isNot(contains('list:other')), reason: 'no loader flash');
  });

  testWidgets('a rider or buyer signal never creates the vendor list', (
    tester,
  ) async {
    final ref = await pumpRef(tester);
    refreshVendorOrdersLive(
      ref,
      const LiveSignal(
        type: 'delivery.offer',
        scopes: [LiveScope.courierOffers],
      ),
    );
    refreshVendorOrdersLive(ref, const LiveSignal.reconnected());
    await tester.pumpAndSettle();
    verifyNever(
      () => repository.getOrders(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
        status: any(named: 'status'),
      ),
    );
  });
}
