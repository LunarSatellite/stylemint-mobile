import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';

abstract interface class MallCatalogRepository {
  /// `GET v1/public/products` with the listing filters.
  Future<Either<NetworkExceptions, CatalogPage<CatalogProduct>>> getProducts(
    ProductListingQuery query, {
    String? cursor,
    int pageSize,
  });

  /// `GET v1/public/collections/{slug}` — header plus one page of items.
  Future<Either<NetworkExceptions, CollectionDetail>> getCollection(
    String slug, {
    String? cursor,
    int pageSize,
  });
}
