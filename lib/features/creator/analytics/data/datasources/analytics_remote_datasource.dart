import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_analytics_overview_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_dashboard_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/full_analytics_report_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_reel_analytics_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/top_reel_summary_dto.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/creator/analytics/overview`
  Future<CreatorAnalyticsOverviewDto> getOverview({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/analytics/overview',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
        'topReelsLimit': topReelsLimit,
        'topProductsLimit': topProductsLimit,
      },
    );
    return CreatorAnalyticsOverviewDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  /// GET `/v1/creator/analytics/dashboard`
  Future<CreatorDashboardDto> getDashboard({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/analytics/dashboard',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
        'topReelsLimit': topReelsLimit,
        'topProductsLimit': topProductsLimit,
      },
    );
    return CreatorDashboardDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/creator/analytics/report`
  Future<FullAnalyticsReportDto> getReport({
    DateTime? fromUtc,
    DateTime? toUtc,
    int contentPerformanceLimit = 12,
    int topProductsLimit = 5,
    int topLocationsLimit = 5,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/analytics/report',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
        'contentPerformanceLimit': contentPerformanceLimit,
        'topProductsLimit': topProductsLimit,
        'topLocationsLimit': topLocationsLimit,
      },
    );
    return FullAnalyticsReportDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/creator/analytics/top-reels`
  Future<List<TopReelSummaryDto>> getTopReels({
    DateTime? fromUtc,
    DateTime? toUtc,
    int sortBy = 1,
    int limit = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/analytics/top-reels',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
        'sortBy': sortBy,
        'limit': limit,
      },
    );
    final list = response as List<dynamic>;
    return list
        .map((e) => TopReelSummaryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET `/v1/creator/analytics/reels/{reelId}`
  Future<CreatorReelAnalyticsDto> getReelAnalytics({
    required String reelId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int topLocationsLimit = 5,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/analytics/reels/$reelId',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
        'topLocationsLimit': topLocationsLimit,
      },
    );
    return CreatorReelAnalyticsDto.fromJson(response as Map<String, dynamic>);
  }
}
