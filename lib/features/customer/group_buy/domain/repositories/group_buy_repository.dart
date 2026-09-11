import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/entities/group_buy.dart';

abstract interface class GroupBuyRepository {
  /// Active group buys for one product — used to show a joinable banner on
  /// the product detail screen. There's no server-side product filter, so
  /// this pages the global active list and filters client-side.
  Future<Either<NetworkExceptions, List<GroupBuy>>> getActiveForProduct(
    String productId,
  );

  Future<Either<NetworkExceptions, List<GroupBuy>>> getMine();

  Future<Either<NetworkExceptions, GroupBuy>> start({
    required String productId,
    required int targetBuyerCount,
    required double discountPercent,
    required DateTime expiresAt,
  });

  Future<Either<NetworkExceptions, GroupBuy>> join(String groupBuyId);
}
