import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/entities/creator_search_result.dart';

/// GET /api/v1/customer/search?type=brands|products|creators — the same
/// real Discovery search endpoint every account type uses (a creator is
/// still a Customer role-profile on the same Account per the multi-role
/// model), just scoped to what a creator actually searches for: brands to
/// pitch/partner with, products to make content about, or other creators.
class CreatorSearchRemoteDataSource {
  CreatorSearchRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _typeNames = {
    CreatorSearchType.brands: 'brands',
    CreatorSearchType.products: 'products',
    CreatorSearchType.creators: 'creators',
  };

  Future<List<SearchBrandResult>> searchBrands(String query) async {
    final m = await _search(query, CreatorSearchType.brands);
    final raw = m['brands'] as List<dynamic>? ?? const <dynamic>[];
    return raw.map((e) {
      final b = e as Map<String, dynamic>;
      return SearchBrandResult(
        brandId: b['brandId'] as String? ?? '',
        name: b['name'] as String? ?? '',
        logoUrl: b['logoUrl'] as String?,
        averageRating: (b['averageRating'] as num?)?.toDouble() ?? 0.0,
        productCount: (b['productCount'] as num?)?.toInt() ?? 0,
        commissionRange: b['commissionRange'] as String? ?? '',
      );
    }).toList(growable: false);
  }

  Future<List<SearchProductResult>> searchProducts(String query) async {
    final m = await _search(query, CreatorSearchType.products);
    final raw = m['products'] as List<dynamic>? ?? const <dynamic>[];
    return raw.map((e) {
      final p = e as Map<String, dynamic>;
      return SearchProductResult(
        productId: p['productId'] as String? ?? '',
        name: p['name'] as String? ?? '',
        heroImageUrl: p['heroImageUrl'] as String? ?? '',
        price: (p['price'] as num?)?.toDouble() ?? 0.0,
        currency: p['currency'] as String? ?? 'NPR',
        brandId: p['brandId'] as String? ?? '',
        brandName: p['brandName'] as String? ?? '',
      );
    }).toList(growable: false);
  }

  Future<List<SearchCreatorResult>> searchCreators(String query) async {
    final m = await _search(query, CreatorSearchType.creators);
    final raw = m['creators'] as List<dynamic>? ?? const <dynamic>[];
    return raw.map((e) {
      final c = e as Map<String, dynamic>;
      return SearchCreatorResult(
        creatorProfileId: c['creatorProfileId'] as String? ?? '',
        handle: c['handle'] as String? ?? '',
        displayName: c['displayName'] as String? ?? '',
        avatarUrl: c['avatarUrl'] as String?,
        followerCount: (c['followerCount'] as num?)?.toInt() ?? 0,
        reelCount: (c['reelCount'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);
  }

  Future<Map<String, dynamic>> _search(String query, CreatorSearchType type) async {
    final response = await apiClient.get(
      '/api/v1/customer/search',
      queryParameters: {
        'q': query,
        'type': _typeNames[type],
        'limit': 20,
      },
    );
    return response as Map<String, dynamic>;
  }
}
