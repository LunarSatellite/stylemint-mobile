import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/repositories/group_cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/screens/group_cart_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// The group cart's empty state has always read "No items yet. Add something!"
/// while nothing on the screen could add anything — `addItem` reached
/// `POST /v1/cart-shares/{id}/items` but had no caller. These cover the way in.

const _money = Money(amount: 0, currency: 'NPR');

CartItem _line({
  required String id,
  required String productId,
  required String name,
  int quantity = 1,
  bool inStock = true,
}) => CartItem(
  id: id,
  productId: productId,
  productName: name,
  productImageUrl: '',
  variantName: 'One size',
  quantity: quantity,
  unitPrice: const Money(amount: 1200, currency: 'NPR'),
  isInStock: inStock,
);

Cart _cartWith(List<CartItem> items) => Cart(
  id: 'cart-id',
  items: items,
  subtotal: _money,
  shippingTotal: _money,
  taxTotal: _money,
  total: _money,
);

GroupCart _emptyGroupCart() => GroupCart(
  id: 'cart-share-id',
  name: 'Group Cart',
  inviteCode: '',
  ownerId: 'owner-id',
  ownerName: 'Cart owner',
  participants: const <GroupCartParticipant>[],
  items: const <GroupCartItem>[],
  subtotal: _money,
  status: GroupCartStatus.active,
  createdAt: DateTime.utc(2026, 9, 11),
);

class _FakeCartRepository implements CartRepository {
  _FakeCartRepository(this._cart);

  final Cart _cart;

  @override
  Future<Either<NetworkExceptions, Cart>> getCart() async => right(_cart);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not used by these tests.',
  );
}

class _RecordingGroupCartRepository implements GroupCartRepository {
  _RecordingGroupCartRepository(this.cart, {this.fail = false});

  final GroupCart cart;
  final bool fail;
  final List<({String cartId, String productId, int qty})> added = [];

  @override
  Future<Either<NetworkExceptions, GroupCart>> getGroupCart(
    String cartId,
  ) async => right(cart);

  @override
  Future<Either<NetworkExceptions, GroupCartItem>> addToGroupCart(
    String cartId,
    String productId,
    int qty,
  ) async {
    added.add((cartId: cartId, productId: productId, qty: qty));
    if (fail) {
      return left(const NetworkExceptions.unexpectedError());
    }
    return right(
      GroupCartItem(
        id: 'item-1',
        productId: productId,
        productName: 'Added',
        imageUrl: '',
        quantity: qty,
        unitPrice: _money,
        addedBy: 'me',
        addedByName: 'Me',
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} is not used by these tests.',
  );
}

Widget _app(_RecordingGroupCartRepository groupCarts, Cart cart) =>
    ProviderScope(
      overrides: [
        groupCartRepositoryProvider.overrideWithValue(groupCarts),
        cartRepositoryProvider.overrideWithValue(_FakeCartRepository(cart)),
      ],
      child: const MaterialApp(
        home: GroupCartDetailScreen(cartId: 'cart-share-id'),
      ),
    );

void main() {
  testWidgets('the empty group cart offers the add it has always asked for', (
    tester,
  ) async {
    final repo = _RecordingGroupCartRepository(_emptyGroupCart());
    await tester.pumpWidget(_app(repo, _cartWith(const <CartItem>[])));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group-cart-empty-add-item')), findsOneWidget);
    expect(find.byKey(const Key('group-cart-add-item-action')), findsOneWidget);
  });

  testWidgets('picking one of your own lines adds it to the group cart', (
    tester,
  ) async {
    final repo = _RecordingGroupCartRepository(_emptyGroupCart());
    await tester.pumpWidget(
      _app(
        repo,
        _cartWith([
          _line(id: 'l1', productId: 'p-1', name: 'Linen shirt', quantity: 2),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group-cart-empty-add-item')));
    await tester.pumpAndSettle();
    expect(find.text('Add from your cart'), findsWidgets);

    await tester.tap(find.text('Linen shirt'));
    await tester.pumpAndSettle();

    expect(repo.added, hasLength(1));
    expect(repo.added.single.productId, 'p-1');
    expect(repo.added.single.qty, 2);
    // The sheet closes and says so, rather than leaving the shopper guessing.
    expect(find.text('Linen shirt added to the group cart.'), findsOneWidget);
  });

  testWidgets('an out-of-stock line cannot be brought along', (tester) async {
    final repo = _RecordingGroupCartRepository(_emptyGroupCart());
    await tester.pumpWidget(
      _app(
        repo,
        _cartWith([
          _line(
            id: 'l1',
            productId: 'p-1',
            name: 'Sold out hat',
            inStock: false,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group-cart-add-item-action')));
    await tester.pumpAndSettle();
    expect(find.text('Out of stock'), findsOneWidget);

    await tester.tap(find.text('Sold out hat'));
    await tester.pumpAndSettle();
    expect(repo.added, isEmpty);
  });

  testWidgets('a quantity above the server cap is clamped, not sent', (
    tester,
  ) async {
    // AddCartShareItemVmValidator rejects >99 with a 400 instead of clamping,
    // so a cart line of 150 has to be trimmed client-side or the add just fails.
    final repo = _RecordingGroupCartRepository(_emptyGroupCart());
    await tester.pumpWidget(
      _app(
        repo,
        _cartWith([
          _line(id: 'l1', productId: 'p-1', name: 'Bulk socks', quantity: 150),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group-cart-add-item-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bulk socks'));
    await tester.pumpAndSettle();

    expect(repo.added.single.qty, 99);
  });

  testWidgets('a failed add says so and keeps the sheet open', (tester) async {
    final repo = _RecordingGroupCartRepository(_emptyGroupCart(), fail: true);
    await tester.pumpWidget(
      _app(
        repo,
        _cartWith([
          _line(id: 'l1', productId: 'p-1', name: 'Linen shirt'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('group-cart-add-item-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Linen shirt'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('group-cart-add-item-error')), findsOneWidget);
    expect(find.text('Linen shirt'), findsOneWidget);
  });
}
