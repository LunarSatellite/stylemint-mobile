import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/data/models/analytics_dto.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<VendorAnalyticsSummaryDto> getSummary({String? window}) async {
    final qp = <String, dynamic>{'window': ?window};

    final results = await Future.wait([
      apiClient.get(
        '/v1/vendor/analytics/overview',
        queryParameters: qp,
      ),
      apiClient.get(
        '/v1/vendor/analytics/earnings',
        queryParameters: qp,
      ),
      apiClient.get(
        '/v1/vendor/analytics/top-products',
        queryParameters: qp,
      ),
      apiClient.get(
        '/v1/vendor/analytics/top-creators',
        queryParameters: qp,
      ),
      apiClient.get(
        '/v1/vendor/analytics/traffic-sources',
        queryParameters: qp,
      ),
    ]);

    return VendorAnalyticsSummaryDto(
      overview: AnalyticsOverviewDto.fromJson(
        results[0] as Map<String, dynamic>,
      ),
      earningsPoints: (results[1] as List)
          .map(
            (e) => EarningsPointDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      topProducts: (results[2] as List)
          .map(
            (e) => AnalyticsTopProductDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      topCreators: (results[3] as List)
          .map(
            (e) => AnalyticsTopCreatorDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      trafficSources: (results[4] as List)
          .map(
            (e) =>
                AnalyticsTrafficSourceDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
