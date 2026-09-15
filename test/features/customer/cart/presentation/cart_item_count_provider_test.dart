import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockCartRepository extends Mock implements CartRepository {}

const _zero = Money(amount: 0, currency: 'NPR');

Cart _cart(List<int> quantities) => Cart(
  id: 'cart-1',
  items: [
    for (var i = 0; i < quantities.length; i++)
      CartItem(
        id: 'line-$i',
        productId: 'prod-$i',
        productName: 'Linen shirt',
        productImageUrl: '',
        variantName: 'M',
        quantity: quantities[i],
        unitPrice: const Money(amount: 2500, currency: 'NPR'),
        isInStock: true,
      ),
  ],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

void main() {
  late _MockCartRepository repository;
  late ProviderContainer container;
  late List<int> counts;

  void stubAdd(Future<Either<NetworkExceptions, Cart>> answer) {
    when(
      () => repository.addToCart(
        productId: any(named: 'productId'),
        quantity: any(named: 'quantity'),
        variantId: any(named: 'variantId'),
        reelTagContextId: any(named: 'reelTagContextId'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) => answer);
  }

  Future<bool> add() => container
      .read(cartNotifierProvider.notifier)
      .addItem(productId: 'prod-7', quantity: 1, idempotencyKey: 'key-1');

  setUp(() {
    repository = _MockCartRepository();
    when(
      () => repository.getCart(),
    ).thenAnswer((_) async => right(_cart([2, 1])));
    container = ProviderContainer(
      overrides: [cartRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    counts = [];
    container.listen<int>(
      cartItemCountProvider,
      (_, next) => counts.add(next),
      fireImmediately: true,
    );
  });

  test('counts units across lines once the cart loads', () async {
    await pumpEventQueue();

    expect(container.read(cartItemCountProvider), 3);
    expect(counts, [0, 3]);
  });

  test('holds the count while an add is in flight, then rises', () async {
    await pumpEventQueue();
    final response = Completer<Either<NetworkExceptions, Cart>>();
    stubAdd(response.future);

    final adding = add();
    expect(container.read(cartItemCountProvider), 3);

    response.complete(right(_cart([2, 1, 1])));
    expect(await adding, isTrue);
    expect(container.read(cartItemCountProvider), 4);
    // Never dropped to 0 on the way.
    expect(counts, [0, 3, 4]);
  });

  test('a failed request keeps the last count', () async {
    await pumpEventQueue();
    stubAdd(Future.value(left(const NetworkExceptions.server('boom'))));

    expect(await add(), isFalse);
    expect(container.read(cartItemCountProvider), 3);
  });

  test('a reset for a new session starts again from 0', () async {
    await pumpEventQueue();
    when(() => repository.getCart()).thenAnswer((_) async => right(_cart([])));

    container.read(cartNotifierProvider.notifier).reset();
    expect(container.read(cartItemCountProvider), 0);
    await pumpEventQueue();
    expect(container.read(cartItemCountProvider), 0);
  });
}
