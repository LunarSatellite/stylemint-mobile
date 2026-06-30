import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_analytics_overview_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/creator_dashboard_dto.dart';

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
}
