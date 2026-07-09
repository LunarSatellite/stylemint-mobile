import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/data/models/brand_studio_dto.dart';

class BrandStudioRemoteDataSource {
  BrandStudioRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/vendor/dashboard — the Brand Studio Intelligence Dashboard.
  Future<BrandStudioInsightsDto> getInsights({int? windowDays}) async {
    final response = await apiClient.get(
      '/v1/vendor/dashboard',
      queryParameters: windowDays == null ? null : {'windowDays': windowDays},
    );
    return BrandStudioInsightsDto.fromJson(response as Map<String, dynamic>);
  }
}
