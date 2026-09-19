import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/core/network/guarded_network_call.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/datasources/in_store_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';

class InStoreRepositoryImpl implements InStoreRepository {
  InStoreRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final InStoreRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getProductReels(
      productId,
    )).map((dto) => dto.toDomain()).toList(growable: false),
  );

  @override
  Future<Either<NetworkExceptions, EndlessAisle>> getEndlessAisle(
    String code,
  ) => guardedNetworkCall(
    networkInfo,
    () async => (await remoteDataSource.getEndlessAisle(code)).toDomain(),
  );

  @override
  Future<Either<NetworkExceptions, Unit>> addScannedProductToCart(
    String code,
    CodeScanVia via,
  ) => guardedNetworkCall(networkInfo, () async {
    await remoteDataSource.addScannedProductToCart(
      code: code,
      via: via,
      idempotencyKey: _uuid.v4(),
    );
    return unit;
  });
  @override
  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  }) => guardedNetworkCall<StoreProductsPage>(networkInfo, () async {
    final page = await remoteDataSource.getVendorProducts(
      vendorAccountId,
      cursor: cursor,
    );
    return (
      products: page.products
          .map((dto) => dto.toDomain())
          .toList(growable: false),
      nextCursor: page.nextCursor,
    );
  });
}
