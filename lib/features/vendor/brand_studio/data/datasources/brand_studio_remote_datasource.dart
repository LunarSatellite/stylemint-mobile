import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/data/models/brand_studio_dto.dart';

class BrandStudioRemoteDataSource {
  BrandStudioRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // TODO(swagger): GET /v1/vendor/brand-studio/templates not found. Templates are under admin scope: GET /v1/admin/brand-studio/goal-templates
  Future<List<CampaignTemplateDto>> getTemplates({String? industry}) async {
    final params = <String, dynamic>{};
    if (industry != null && industry.isNotEmpty) params['industry'] = industry;
    final response = await apiClient.get(
      '/v1/vendor/brand-studio/templates',
      queryParameters: params.isEmpty ? null : params,
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => CampaignTemplateDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  // TODO(swagger): GET /v1/vendor/brand-studio/analytics/{campaignId} not found. Use GET /v1/vendor/analytics/overview or GET /v1/vendor/partnerships/{partnershipId}/creator-analytics
  Future<CampaignAnalyticsDto> getCampaignAnalytics(
    String campaignId,
  ) async {
    final response = await apiClient.get(
      '/v1/vendor/brand-studio/analytics/$campaignId',
    );
    return CampaignAnalyticsDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): GET /v1/vendor/brand-studio/insights not found in Swagger
  Future<List<MarketInsightDto>> getMarketInsights() async {
    final response = await apiClient.get('/v1/vendor/brand-studio/insights');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => MarketInsightDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }
}
