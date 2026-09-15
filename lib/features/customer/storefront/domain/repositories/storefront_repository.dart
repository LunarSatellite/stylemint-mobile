import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';

/// Sort orders of a creator's public reels.
enum CreatorReelSort {
  latest('latest'),
  popular('popular');

  const CreatorReelSort(this.wire);

  final String wire;
}

/// Public reads shared by the creator and brand storefronts.
abstract interface class StorefrontRepository {
  /// `GET v1/public/creators/{accountId}/reels`.
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontReel>>>
  getCreatorReels(
    String creatorAccountId, {
    required CreatorReelSort sort,
    String? cursor,
    int pageSize,
  });

  /// `GET v1/public/vendors/{vendorAccountId}/reels`.
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontReel>>>
  getVendorReels(String vendorAccountId, {String? cursor, int pageSize});

  /// `GET v1/public/collections?ownerKind=&ownerAccountId=&kind=`.
  Future<Either<NetworkExceptions, StorefrontPage<StorefrontCollection>>>
  getCollections({
    required StorefrontOwnerKind ownerKind,
    required String ownerAccountId,
    required CollectionKind kind,
    String? cursor,
    int pageSize,
  });

  /// `GET v1/follows/{accountId}/stats`.
  Future<Either<NetworkExceptions, StorefrontFollowSummary>> getFollowSummary(
    String accountId,
  );
}
