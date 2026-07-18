import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_list_dto.dart';

/// GET /v1/brands, /v1/brands/recommended — real approved-vendor brand
/// catalog (Creator §7A "Browse all Brands" / "Recommended Brands for You").
class BrandsRemoteDataSource {
  BrandsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<BrandListItemDto>> listBrands({int pageSize = 25}) async {
    final response = await apiClient.get(
      '/v1/brands',
      queryParameters: {'pageSize': pageSize},
    );
    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(BrandListItemDto.fromJson)
        .toList(growable: false);
  }

  Future<List<BrandListItemDto>> listRecommendedBrands({int limit = 5}) async {
    final response = await apiClient.get(
      '/v1/brands/recommended',
      queryParameters: {'limit': limit},
    );
    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(BrandListItemDto.fromJson)
        .toList(growable: false);
  }
}
