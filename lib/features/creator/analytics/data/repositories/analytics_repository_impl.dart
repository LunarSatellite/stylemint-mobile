import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final AnalyticsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, CreatorAnalyticsOverview>> getOverview({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getOverview(
        fromUtc: fromUtc,
        toUtc: toUtc,
        topReelsLimit: topReelsLimit,
        topProductsLimit: topProductsLimit,
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, CreatorDashboard>> getDashboard({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getDashboard(
        fromUtc: fromUtc,
        toUtc: toUtc,
        topReelsLimit: topReelsLimit,
        topProductsLimit: topProductsLimit,
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }
}
