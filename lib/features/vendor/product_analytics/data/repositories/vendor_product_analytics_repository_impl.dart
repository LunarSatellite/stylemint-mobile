import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/data/datasources/vendor_product_analytics_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/entities/vendor_product_analytics.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/repositories/vendor_product_analytics_repository.dart';

class VendorProductAnalyticsRepositoryImpl
    implements VendorProductAnalyticsRepository {
  VendorProductAnalyticsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final VendorProductAnalyticsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, VendorProductAnalytics>> getProductAnalytics({
    required String productId,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getProductAnalytics(
          productId: productId,
          fromUtc: fromUtc,
          toUtc: toUtc,
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
