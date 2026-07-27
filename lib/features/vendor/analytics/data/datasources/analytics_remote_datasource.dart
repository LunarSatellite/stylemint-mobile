import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/data/models/analytics_dto.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Single round-trip -- `revenueTrend`, `topProducts`, `topCreators` and
  /// `trafficSources` are all embedded fields on this one response, not
  /// separate endpoints. Windowing uses `fromUtc`/`toUtc` (matches the
  /// earnings/dashboard pattern in this package) -- omitted, the backend
  /// defaults to the trailing 30 days. `window` is still accepted for
  /// legacy callers and translated into a concrete range below.
  Future<VendorAnalyticsSummaryDto> getSummary({
    String? window,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    final now = DateTime.now().toUtc();
    final effectiveFrom =
        fromUtc ?? (window != null ? _windowToFrom(window, now) : null);
    final effectiveTo = toUtc ?? (window != null ? now : null);
    final response = await apiClient.get(
      '/v1/vendor/analytics/overview',
      queryParameters: {
        if (window != null) 'window': window,
        if (effectiveFrom != null) 'fromUtc': effectiveFrom.toIso8601String(),
        if (effectiveTo != null) 'toUtc': effectiveTo.toIso8601String(),
      },
    );
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

  static DateTime _windowToFrom(String window, DateTime toUtc) {
    final lowered = window.toLowerCase();
    if (lowered == '24h' || lowered == '1d') {
      return toUtc.subtract(const Duration(hours: 24));
    }
    if (lowered == '7d') {
      return toUtc.subtract(const Duration(days: 7));
    }
    if (lowered == '90d') {
      return toUtc.subtract(const Duration(days: 90));
    }
    return toUtc.subtract(const Duration(days: 30));
  }
}
