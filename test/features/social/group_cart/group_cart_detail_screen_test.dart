import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/repositories/group_cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/screens/group_cart_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _FakeGroupCartRepository implements GroupCartRepository {
  _FakeGroupCartRepository(this.cart);

  final GroupCart cart;

  @override
  Future<Either<NetworkExceptions, GroupCart>> getGroupCart(
    String cartId,
  ) async => right(cart);

  @override
  Future<Either<NetworkExceptions, GroupCartItem>> addToGroupCart(
    String cartId,
    String productId,
    int qty,
  ) => throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> checkoutGroupCart(String cartId) =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, GroupCart>> createGroupCart() =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, List<GroupCart>>> getGroupCarts() =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, GroupCart>> joinGroupCart(
    String inviteCode,
  ) => throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, String>> inviteToGroupCart(
    String cartId,
    String invitedAccountId,
  ) => throw UnimplementedError();
  @override
  Future<Either<NetworkExceptions, Unit>> removeFromGroupCart(
    String cartId,
    String itemId,
  ) => throw UnimplementedError();
}

void main() {
  testWidgets(
    'empty group cart detail lays out without an infinite width error',
    (tester) async {
      final cart = GroupCart(
        id: 'cart-share-id',
        name: 'Group Cart',
        inviteCode: '',
        ownerId: 'owner-id',
        ownerName: 'Cart owner',
        participants: const <GroupCartParticipant>[],
        items: const <GroupCartItem>[],
        subtotal: const Money(amount: 0, currency: 'NPR'),
        status: GroupCartStatus.active,
        createdAt: DateTime.utc(2026, 9, 11),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupCartRepositoryProvider.overrideWithValue(
              _FakeGroupCartRepository(cart),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 48),
                viewPadding: const EdgeInsets.only(bottom: 48),
              ),
              child: child!,
            ),
            home: const GroupCartDetailScreen(cartId: 'cart-share-id'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('No items yet. Add something!'), findsOneWidget);
      expect(find.text('Close Group Cart'), findsOneWidget);
      final bottomSafeArea = tester.widget<SafeArea>(
        find.byKey(const Key('group-cart-bottom-safe-area')),
      );
      expect(bottomSafeArea.top, isFalse);
      expect(bottomSafeArea.bottom, isTrue);
      final closeButton = find.ancestor(
        of: find.text('Close Group Cart'),
        matching: find.byType(ElevatedButton),
      );
      final logicalHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        tester.getBottomRight(closeButton).dy,
        lessThan(logicalHeight - 48),
      );
    },
  );
}
