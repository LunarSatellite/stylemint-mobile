import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_list_dto.dart';

/// Creator §7A "Browse all Brands" catalog + §7B/C/D brand detail
/// hydration (Creator Brand Partnerships screen).
///
/// Endpoints:
///   GET /v1/brands                       — paginated approved-vendor list
///   GET /v1/brands/recommended           — recommended-vendor list
///   GET /v1/brands/{vendorAccountId}     — single brand detail (real DB)
///   GET /v1/creator/brands/{id}/trust    — trust score for the detail header
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

  /// Single brand detail — real DB-backed VendorProfileDto via the
  /// authenticated brand-catalog endpoint. Replaces the placeholder
  /// values `brands_screen.dart._toBrandInfoData` used to fabricate.
  Future<BrandDetailDto> getBrand(String vendorAccountId) async {
    final response = await apiClient.get('/v1/brands/$vendorAccountId');
    return BrandDetailDto.fromJson(response as Map<String, dynamic>);
  }

  /// Brand trust score — 0–100 overall score plus component sub-scores
  /// the brand detail screen renders as the "rating" and "success rate"
  /// tiles. May 404 for vendors without a trust row yet; the caller
  /// treats that as "no rating yet" and skips the tile.
  Future<BrandTrustDto> getBrandTrust(String vendorAccountId) async {
    final response =
        await apiClient.get('/v1/creator/brands/$vendorAccountId/trust');
    return BrandTrustDto.fromJson(response as Map<String, dynamic>);
  }
}
