import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/data/models/vendor_top_product_dto.dart';

class VendorTopProductsRemoteDataSource {
  VendorTopProductsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/vendor/analytics/products` (Vendor §8D). No `sortBy` param
  /// exists on the backend — results come back ordered by revenue desc.
  Future<VendorTopProductsPageDto> getTopProducts({
    DateTime? fromUtc,
    DateTime? toUtc,
    int? limit,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/analytics/products',
      queryParameters: {
        if (fromUtc != null) 'fromUtc': fromUtc.toUtc().toIso8601String(),
        if (toUtc != null) 'toUtc': toUtc.toUtc().toIso8601String(),
        if (limit != null) 'limit': limit,
      },
    );
    return VendorTopProductsPageDto.fromJson(response as Map<String, dynamic>);
  }
}
