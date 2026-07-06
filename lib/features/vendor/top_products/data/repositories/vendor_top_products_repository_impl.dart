import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/data/datasources/vendor_top_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/entities/vendor_top_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/repositories/vendor_top_products_repository.dart';

class VendorTopProductsRepositoryImpl implements VendorTopProductsRepository {
  VendorTopProductsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorTopProductsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, List<VendorTopProduct>>> getTopProducts({
    DateTime? fromUtc,
    DateTime? toUtc,
    int? limit,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getTopProducts(
          fromUtc: fromUtc,
          toUtc: toUtc,
          limit: limit,
        );
        return right(dto.toDomain());
      } on DioException catch (e) {
        return left(NetworkExceptions.server(e.message.toString()));
      } on NetworkExceptions catch (e) {
        return left(e);
      } on Object catch (_) {
        return left(const NetworkExceptions.unexpectedError());
      }
    } else {
      return left(const NetworkExceptions.noInternetConnection());
    }
  }
}
