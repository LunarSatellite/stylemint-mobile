import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/mall_catalog_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';

class MallCatalogRepositoryImpl implements MallCatalogRepository {
  MallCatalogRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final MallCatalogRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, CatalogPage<CatalogProduct>>> getProducts(
    ProductListingQuery query, {
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getProducts(
      query.toQueryParameters(),
      cursor: cursor,
      pageSize: pageSize,
    )).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, CollectionDetail>> getCollection(
    String slug, {
    String? cursor,
    int pageSize = 20,
  }) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getCollection(
      slug,
      cursor: cursor,
      pageSize: pageSize,
    )).toDomain(),
  );
}
