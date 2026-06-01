import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class DiscoveryRepository {
  Future<Either<NetworkExceptions, DiscoverData>> getDiscoverData();

  Future<Either<NetworkExceptions, ProductDetail>> getProductDetail(String productId);

  Future<Either<NetworkExceptions, PagedResult<ProductReviewPreview>>> getProductReviews(
    String productId, {
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, List<RelatedProduct>>> getRelatedProducts(
    String productId,
  );

  Future<Either<NetworkExceptions, Unit>> addToCart({
    required String productId,
    required int qty,
    String? variantId,
  });

  Future<Either<NetworkExceptions, bool>> toggleSaved(String productId);
}
