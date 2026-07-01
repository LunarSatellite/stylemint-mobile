import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/full_analytics_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_reel_analytics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reels_sort.dart';
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

  @override
  Future<Either<NetworkExceptions, FullAnalyticsReport>> getReport({
    DateTime? fromUtc,
    DateTime? toUtc,
    int contentPerformanceLimit = 12,
    int topProductsLimit = 5,
    int topLocationsLimit = 5,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getReport(
        fromUtc: fromUtc,
        toUtc: toUtc,
        contentPerformanceLimit: contentPerformanceLimit,
        topProductsLimit: topProductsLimit,
        topLocationsLimit: topLocationsLimit,
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
  Future<Either<NetworkExceptions, List<TopReelSummary>>> getTopReels({
    DateTime? fromUtc,
    DateTime? toUtc,
    TopReelsSort sortBy = TopReelsSort.highestEarnings,
    int limit = 25,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dtos = await remoteDataSource.getTopReels(
        fromUtc: fromUtc,
        toUtc: toUtc,
        sortBy: sortBy.value,
        limit: limit,
      );
      return right(dtos.map((dto) => dto.toDomain()).toList());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message ?? 'Server error'));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Exception {
      return left(const NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, CreatorReelAnalytics>> getReelAnalytics({
    required String reelId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int topLocationsLimit = 5,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    try {
      final dto = await remoteDataSource.getReelAnalytics(
        reelId: reelId,
        fromUtc: fromUtc,
        toUtc: toUtc,
        topLocationsLimit: topLocationsLimit,
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
