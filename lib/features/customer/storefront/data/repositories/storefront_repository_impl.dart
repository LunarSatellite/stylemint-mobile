import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/datasources/storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';

class StorefrontRepositoryImpl implements StorefrontRepository {
  StorefrontRepositoryImpl({
    required this.remoteDataSource,
    required this.followApi,
    required this.networkInfo,
  });

  final StorefrontRemoteDataSource remoteDataSource;
  final FollowApi followApi;
  final NetworkInfoConnectivity networkInfo;

  static const int reelPageSize = 12;
  static const int collectionPageSize = 20;

  @override
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontReel>>>
  getCreatorReels(
    String creatorAccountId, {
    required CreatorReelSort sort,
    String? cursor,
    int pageSize = reelPageSize,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.getCreatorReels(
      creatorAccountId,
      sort: sort.wire,
      cursor: cursor,
      pageSize: pageSize,
    );
    return page.toDomain((reel) => reel.toDomain());
  });

  @override
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontReel>>>
  getVendorReels(
    String vendorAccountId, {
    String? cursor,
    int pageSize = reelPageSize,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.getVendorReels(
      vendorAccountId,
      cursor: cursor,
      pageSize: pageSize,
    );
    return page.toDomain((reel) => reel.toDomain());
  });

  @override
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontCollection>>>
  getCollections({
    required StorefrontOwnerKind ownerKind,
    required String ownerAccountId,
    required CollectionKind kind,
    String? cursor,
    int pageSize = collectionPageSize,
  }) => guardedNetworkCall(networkInfo, () async {
    final page = await remoteDataSource.getCollections(
      ownerKind: ownerKind.wire,
      ownerAccountId: ownerAccountId,
      kind: collectionKindWire(kind),
      cursor: cursor,
      pageSize: pageSize,
    );
    return page.toDomain((collection) => collection.toDomain());
  });

  @override
  Future<Either<NetworkExceptions, StorefrontFollowSummary>> getFollowSummary(
    String accountId,
  ) => guardedNetworkCall(networkInfo, () async {
    final stats = await followApi.stats(accountId);
    return StorefrontFollowSummary(
      followers: stats.followers < 0 ? 0 : stats.followers,
      isFollowedByViewer: stats.isFollowedByViewer,
    );
  });
}
