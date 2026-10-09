import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/order_by_id_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _zero = Money(amount: 0, currency: 'NPR');

TrackedOrder _order(String id, String number) => TrackedOrder(
  id: id,
  orderNumber: number,
  total: _zero,
  placedAt: DateTime(2026, 10, 9),
  itemCount: 1,
  status: OrderTrackStatus.preparingForShipping,
);

OrderDetail _detail(String number, String subOrderId) => OrderDetail(
  id: 'id-$number',
  orderNumber: number,
  status: OrderTrackStatus.preparingForShipping,
  placedAt: DateTime(2026, 10, 9),
  estimatedDelivery: DateTime(2026, 10, 12),
  items: [
    OrderDetailItem(
      subOrderId: subOrderId,
      productId: 'p1',
      productName: 'Tote',
      imageUrl: '',
      variantName: '',
      qty: 1,
      unitPrice: _zero,
      status: 'Packed',
    ),
  ],
  subtotal: _zero,
  shipping: _zero,
  tax: _zero,
  total: _zero,
  shippingAddress: '',
  paymentMethod: 'COD',
  canCancel: false,
  canReturn: false,
);

void main() {
  late _MockOrdersRepository repository;
  late ProviderContainer container;

  const orderA = '11111111-1111-4111-8111-111111111111';
  const orderB = '22222222-2222-4222-8222-222222222222';
  const subOfB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

  setUp(() {
    repository = _MockOrdersRepository();
    when(
      () => repository.getTrackedOrders(limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => right([_order(orderA, 'SM-A'), _order(orderB, 'SM-B')]),
    );
    when(
      () => repository.getOrderDetail('SM-A'),
    ).thenAnswer((_) async => right(_detail('SM-A', 'sub-of-a')));
    when(
      () => repository.getOrderDetail('SM-B'),
    ).thenAnswer((_) async => right(_detail('SM-B', subOfB)));
    container = ProviderContainer(
      overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      // Riverpod retries a failed provider by default; a test of the failure
      // wants the first one.
      retry: (_, _) => null,
    );
    addTearDown(container.dispose);
  });

  Future<String?> resolve(String id) {
    final sub = container.listen(orderNumberForOrderIdProvider(id), (_, _) {});
    addTearDown(sub.close);
    return container.read(orderNumberForOrderIdProvider(id).future);
  }

  test(
    'an order id resolves from the list, without opening any order',
    () async {
      expect(await resolve(orderB.toUpperCase()), 'SM-B');
      verifyNever(() => repository.getOrderDetail(any()));
    },
  );

  test('a sub-order id resolves to the order that holds it', () async {
    expect(await resolve(subOfB), 'SM-B');
  });

  test('an id on none of the recent orders resolves to null', () async {
    expect(await resolve('99999999-9999-4999-8999-999999999999'), isNull);
  });

  test('a failed list is an error, so the screen offers a retry', () async {
    when(
      () => repository.getTrackedOrders(limit: any(named: 'limit')),
    ).thenAnswer(
      (_) async => left(const NetworkExceptions.noInternetConnection()),
    );
    await expectLater(resolve(orderA), throwsA(isA<NetworkExceptions>()));
  });
}
