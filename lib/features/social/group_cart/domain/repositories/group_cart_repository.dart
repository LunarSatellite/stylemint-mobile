import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';

abstract interface class GroupCartRepository {
  Future<Either<NetworkExceptions, List<GroupCart>>> getGroupCarts();

  Future<Either<NetworkExceptions, GroupCart>> getGroupCart(String cartId);

  Future<Either<NetworkExceptions, GroupCart>> createGroupCart(String name);

  Future<Either<NetworkExceptions, GroupCart>> joinGroupCart(String inviteCode);

  Future<Either<NetworkExceptions, GroupCartItem>> addToGroupCart(
    String cartId,
    String productId,
    int qty,
  );

  Future<Either<NetworkExceptions, Unit>> removeFromGroupCart(
    String cartId,
    String itemId,
  );

  Future<Either<NetworkExceptions, Unit>> checkoutGroupCart(String cartId);
}
