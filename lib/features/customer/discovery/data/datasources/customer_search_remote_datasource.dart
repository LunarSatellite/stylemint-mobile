import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';

/// GET /api/v1/customer/search?type=all — real backend search across
/// products, brands, reels, and creators in a single round-trip.
class CustomerSearchRemoteDataSource {
  CustomerSearchRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CustomerSearchResults> search(String query, {int limit = 20}) async {
    final response = await apiClient.get(
      '/api/v1/customer/search',
      queryParameters: {'q': query, 'type': 'all', 'limit': limit},
    );
    final data = response as Map<String, dynamic>;

    final products = (data['products'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((p) => SearchResultProduct(
              productId: p['productId'] as String? ?? '',
              name: p['name'] as String? ?? '',
              heroImageUrl: p['heroImageUrl'] as String? ?? '',
              price: (p['price'] as num?)?.toDouble() ?? 0,
              currency: p['currency'] as String? ?? 'NPR',
              averageRating: (p['averageRating'] as num?)?.toDouble() ?? 0,
            ))
        .toList(growable: false);

    final brands = (data['brands'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((b) => SearchResultBrand(
              brandId: b['brandId'] as String? ?? '',
              name: b['name'] as String? ?? '',
              logoUrl: b['logoUrl'] as String?,
              averageRating: (b['averageRating'] as num?)?.toDouble() ?? 0,
              productCount: (b['productCount'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    final reels = (data['reels'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((r) => SearchResultReel(
              reelId: r['reelId'] as String? ?? '',
              thumbnailUrl: r['thumbnailUrl'] as String? ?? '',
              viewCount: (r['viewCount'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    final creators = (data['creators'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((c) => SearchResultCreator(
              creatorProfileId: c['creatorProfileId'] as String? ?? '',
              handle: c['handle'] as String? ?? '',
              displayName: c['displayName'] as String? ?? '',
              avatarUrl: c['avatarUrl'] as String?,
              followerCount: (c['followerCount'] as num?)?.toInt() ?? 0,
            ))
        .toList(growable: false);

    return CustomerSearchResults(
      products: products,
      brands: brands,
      reels: reels,
      creators: creators,
      totalHits: (data['totalHits'] as num?)?.toInt() ?? 0,
    );
  }
}
