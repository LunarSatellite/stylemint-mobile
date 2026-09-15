import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/datasources/creator_storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_reel_stats.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/repositories/creator_storefront_repository.dart';

class CreatorStorefrontRepositoryImpl implements CreatorStorefrontRepository {
  CreatorStorefrontRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CreatorStorefrontRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const int shopPageSize = 24;

  @override
  Future<Either<NetworkExceptions, PublicCreatorProfile>> getProfile(
    String accountId,
  ) => guardedNetworkCall(
    networkInfo,
    () async =>
        (await remoteDataSource.getProfile(accountId)).toDomain(accountId),
  );

  @override
  Future<Either<NetworkExceptions, CreatorReelStats>> getReelStats(
    String accountId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getReelStats(accountId)).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, StorefrontPage<CreatorShopProduct>>> getShop(
    String accountId, {
    String? cursor,
    int pageSize = shopPageSize,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.getShop(
      accountId,
      cursor: cursor,
      pageSize: pageSize,
    );
    return page.toDomain((product) => product.toDomain());
  });
}
