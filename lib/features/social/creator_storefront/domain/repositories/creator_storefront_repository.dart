import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_reel_stats.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/public_creator_profile.dart';

/// Anonymous reads behind a creator's storefront.
abstract interface class CreatorStorefrontRepository {
  /// `GET v1/public/creators/{accountId}`; `notFound` when not public.
  Future<Either<NetworkExceptions, PublicCreatorProfile>> getProfile(
    String accountId,
  );

  /// `GET v1/public/creators/{accountId}/reel-stats`.
  Future<Either<NetworkExceptions, CreatorReelStats>> getReelStats(
    String accountId,
  );

  /// `GET v1/public/creators/{accountId}/shop`, most recently tagged first.
  Future<Either<NetworkExceptions, StorefrontPage<CreatorShopProduct>>> getShop(
    String accountId, {
    String? cursor,
    int pageSize,
  });
}
