import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_list_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/brand_partnership_record_dto.dart';

/// Creator §7A "Browse all Brands" catalog + §7B/C/D brand detail
/// hydration (Creator Brand Partnerships screen).
///
/// Endpoints:
///   GET /v1/brands                       — paginated approved-vendor list
///   GET /v1/brands/recommended           — recommended-vendor list
///   GET /v1/brands/{vendorAccountId}     — single brand detail (real DB)
///   GET /v1/creator/brands/{vendorProfileId}/partnership-record
///                                        — the brand's recorded partnership
///                                          conduct (counts + measured rates)
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

  /// What StyleMint has recorded about a brand's partnership conduct:
  /// counts, plus two rates that each carry their own denominator and
  /// window. Replaces `GET /v1/creator/brands/{vendorId}/trust`, whose
  /// blended 0–100 score was built from constants and served as `0` to
  /// every caller.
  ///
  /// Keyed by the vendor **profile** id — the id partnerships are stored
  /// against, and the one `GET /v1/brands/{vendorAccountId}` returns as its
  /// `id`. The retired endpoint documented an account id and created a row
  /// for whatever it was given, which is how the drift went unnoticed.
  ///
  /// There is no 404 path: a brand with no partnership rows is a successful
  /// response with zero counts and null rates, which is what the record
  /// says about it.
  Future<BrandPartnershipRecordDto> getBrandPartnershipRecord(
    String vendorProfileId,
  ) async {
    final response = await apiClient.get(
      '/v1/creator/brands/$vendorProfileId/partnership-record',
    );
    return BrandPartnershipRecordDto.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
