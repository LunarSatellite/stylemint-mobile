import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_return_record.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class DiscoveryRepository {
  Future<Either<NetworkExceptions, DiscoverData>> getDiscoverData();

  /// The curated product cards for one category landing page.
  Future<Either<NetworkExceptions, List<TrendingProduct>>> getCategoryProducts(
    String categoryId,
  );

  Future<Either<NetworkExceptions, ProductDetail>> getProductDetail(
    String productId,
  );

  Future<Either<NetworkExceptions, PagedResult<ProductReviewPreview>>>
  getProductReviews(
    String productId, {
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, List<RelatedProduct>>> getRelatedProducts(
    String productId,
  );

  Future<Either<NetworkExceptions, ProductUrgency>> getProductUrgency(
    String productId,
  );

  /// Measured social proof for a batch of products, keyed by product id.
  /// Products the backend has nothing recorded for are simply absent from
  /// the map — there is no zero-filled entry to mistake for a fact.
  Future<Either<NetworkExceptions, Map<String, ProductSocialProof>>>
  getSocialProof(List<String> productIds);

  Future<Either<NetworkExceptions, List<ProductFaqEntry>>> getProductFaq(
    String productId,
  );

  /// Structured "which one should I buy" guidance, or `right(null)` when the
  /// endpoint answers `204 No Content` — it has nothing grounded to say and
  /// no longer invents filler to fill the shape. That is a success, not a
  /// failure, and callers render no card for it.
  Future<Either<NetworkExceptions, ProductComparison?>> getProductComparison(
    String productId,
  );

  Future<Either<NetworkExceptions, ProductPassport>> getProductPassport(
    String productId,
  );

  /// The product's own return record and that of up to four same-category
  /// alternatives: counts, the category's measured rate, and a comparison
  /// against that rate. Nothing is scored, levelled or ranked.
  Future<Either<NetworkExceptions, ProductReturnRecord>> getReturnRecord(
    String productId,
  );

  Future<Either<NetworkExceptions, MissionShoppingPlan>>
  getMissionShoppingPlan({
    required String missionText,
    double? budgetAmount,
    int maxItems,
  });

  Future<Either<NetworkExceptions, Unit>> addToCart({
    required String productId,
    required int qty,
    String? variantId,
  });

  Future<Either<NetworkExceptions, bool>> toggleSaved(
    String productId, {
    String? variantId,
  });
}
