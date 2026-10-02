import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/mall_catalog_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';

class MallCatalogRepositoryImpl implements MallCatalogRepository {
  MallCatalogRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    this.digitalGoodsPolicy = const DigitalGoodsPolicy.allowed(),
  });

  final MallCatalogRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  /// Store billing rules for this build. When digital goods may not be sold
  /// here, products the server marked digital are dropped from every listing
  /// this repository serves, so a buyer never reaches a page with no way to
  /// buy. The product page itself still loads by deep link and simply offers
  /// no purchase action.
  ///
  /// Note the paging consequence: the server still returns and counts those
  /// rows, so a filtered page can come back shorter than `pageSize` (or
  /// empty) while `nextCursor` is still set. Callers page on the cursor, not
  /// on the item count, so that is correct — just not tidy.
  final DigitalGoodsPolicy digitalGoodsPolicy;

  bool _isSellable(CatalogProduct product) =>
      !digitalGoodsPolicy.blocksPurchaseOf(product.productKind);

  @override
  Future<Either<NetworkExceptions, CatalogPage<CatalogProduct>>> getProducts(
    ProductListingQuery query, {
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getProducts(
      query.toApiParameters(),
      cursor: cursor,
      pageSize: pageSize,
    )).toDomain().where(_isSellable),
  );

  @override
  Future<Either<NetworkExceptions, CollectionDetail>> getCollection(
    String slug, {
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(
    networkInfo,
    () async {
      final detail = (await remoteDataSource.getCollection(
        slug,
        cursor: cursor,
        pageSize: pageSize,
      )).toDomain();
      return detail.withItems(
        detail.items.where((item) => _isSellable(item.product)),
      );
    },
  );
}
