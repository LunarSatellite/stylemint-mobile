import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/data/models/analytics_dto.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Single round-trip — `revenueTrend`, `topProducts`, `topCreators` and
  /// `trafficSources` are all embedded fields on this one response, not
  /// separate endpoints. The backend has no `window` query param; it
  /// defaults to the trailing 30 days (use `fromUtc`/`toUtc` to override).
  Future<VendorAnalyticsSummaryDto> getSummary({String? window}) async {
    final response = await apiClient.get('/v1/vendor/analytics/overview');
    return VendorAnalyticsSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  /// `GET /v1/vendor/partnerships/{partnershipId}/creator-analytics`.
  Future<CreatorAnalyticsDeepDiveDto> getCreatorAnalytics(
    String partnershipId,
  ) async {
    final response = await apiClient.get(
      '/v1/vendor/partnerships/$partnershipId/creator-analytics',
    );
    return CreatorAnalyticsDeepDiveDto.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
