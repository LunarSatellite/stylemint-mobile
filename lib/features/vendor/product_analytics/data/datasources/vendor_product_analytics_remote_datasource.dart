import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/data/models/vendor_product_analytics_dto.dart';

class VendorProductAnalyticsRemoteDataSource {
  VendorProductAnalyticsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/vendor/products/{productId}/analytics` (Vendor §9H).
  Future<VendorProductAnalyticsDto> getProductAnalytics({
    required String productId,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/products/$productId/analytics',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
      },
    );
    return VendorProductAnalyticsDto.fromJson(response as Map<String, dynamic>);
  }
}
