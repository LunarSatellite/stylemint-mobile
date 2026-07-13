import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/models/creator_performance_dto.dart';

class CreatorPerformanceRemoteDataSource {
  CreatorPerformanceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/vendor/analytics/creators` (Vendor §8B). `windowDays` is
  /// translated to an explicit `fromUtc`/`toUtc` range client-side; omitting
  /// it lets the backend apply its own default (trailing 30 days). There is
  /// no server-side sort parameter — the backend returns items ordered by
  /// revenue desc; callers re-sort client-side for other metrics.
  Future<CreatorPerformancePageDto> getCreatorPerformance({
    int? windowDays,
    int limit = 50,
  }) async {
    DateTime? toUtc;
    DateTime? fromUtc;
    if (windowDays != null) {
      toUtc = DateTime.now().toUtc();
      fromUtc = toUtc.subtract(Duration(days: windowDays));
    }
    final response = await apiClient.get(
      '/v1/vendor/analytics/creators',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toIso8601String(),
        'limit': limit,
      },
    );
    return CreatorPerformancePageDto.fromJson(response as Map<String, dynamic>);
  }
}
