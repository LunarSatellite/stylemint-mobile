import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final AnalyticsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, VendorAnalyticsSummary>> getSummary({
    String? window,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getSummary(
          window: window,
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

  @override
  Future<Either<NetworkExceptions, CreatorAnalyticsDeepDive>>
  getCreatorAnalytics(String partnershipId) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getCreatorAnalytics(partnershipId);
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
