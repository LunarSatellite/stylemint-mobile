import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';

/// GET /api/v1/customer/search?type=all — real backend search across
/// products, brands, reels, and creators in a single round-trip.
class CustomerSearchRemoteDataSource {
  CustomerSearchRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<bool> isVisualSearchAvailable() async {
    try {
      final response = await apiClient.get(
        '/api/v1/customer/search/image/capability',
      );
      return response is Map<String, dynamic> && response['available'] == true;
    } on Object catch (_) {
      return false;
    }
  }

  /// Searches the catalogue using actual image content analyzed by the server.
  Future<CustomerSearchResults> searchByImage(
    String imageDataUri, {
    int limit = 20,
  }) async {
    final response = await apiClient.post(
      '/api/v1/customer/search/image',
      data: {'imageUrl': imageDataUri, 'limit': limit},
    );
    final rows = (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>();
    final products = rows.map(_visualProductFromJson).toList(growable: false);
    return CustomerSearchResults(
      products: products,
      brands: const [],
      reels: const [],
      creators: const [],
      totalHits: products.length,
      queryUnderstanding: 'Products recognized from your photo',
    );
  }

  /// Sends text/voice transcripts and representative visual frames through one
  /// server-side fusion contract. The server owns ranking and de-duplication.
  Future<CustomerSearchResults> searchMultimodal(
    List<String> imageDataUris, {
    String? query,
    int limit = 20,
  }) async {
    final normalizedQuery = query?.trim();
    final response = await apiClient.post(
      '/api/v1/customer/search/multimodal',
      data: {
        if (normalizedQuery?.isNotEmpty ?? false) 'query': normalizedQuery,
        'imageUrls': imageDataUris.take(3).toList(growable: false),
        'limit': limit,
      },
    );
    final data = response is Map<String, dynamic> ? response : null;
    final rows =
        (data?['products'] as List<dynamic>? ??
                (response is List<dynamic> ? response : const <dynamic>[]))
            .whereType<Map<String, dynamic>>();
    final products = rows.map(_visualProductFromJson).toList(growable: false);
    return CustomerSearchResults(
      products: products,
      brands: const [],
      reels: const [],
      creators: const [],
      totalHits: products.length,
      queryUnderstanding:
          _nonBlank(data?['queryUnderstanding']) ??
          (imageDataUris.length > 1
              ? 'Products recognized across your video'
              : 'Products recognized from your photo'),
    );
  }

  Future<CustomerSearchResults> searchByImages(
    List<String> imageDataUris, {
    int limit = 20,
  }) => searchMultimodal(imageDataUris, limit: limit);
  Future<CustomerSearchResults> search(String query, {int limit = 20}) async {
    // Unified search remains the source of truth. AI contributes ordering and
    // explanations, but is optional so local-model outages never break search.
    final unifiedFuture = apiClient.get(
      '/api/v1/customer/search',
      queryParameters: {'q': query, 'type': 'all', 'limit': limit},
    );
    final aiFuture = apiClient
        .authGet(
          '/api/v1/public/search/ai',
          queryParameters: {'q': query, 'limit': limit},
        )
        .catchError((_) => null);

    final response = await unifiedFuture;
    final aiResponse = await aiFuture;
    final data = response as Map<String, dynamic>;
    final aiData = aiResponse is Map<String, dynamic> ? aiResponse : null;
    final aiItems = (aiData?['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final aiRank = <String, int>{};
    final aiReasons = <String, String>{};
    for (var index = 0; index < aiItems.length; index++) {
      final item = aiItems[index];
      final id = item['entityId']?.toString();
      if (id == null || id.isEmpty) continue;
      aiRank[id] = index;
      final reason = _nonBlank(item['reason']);
      if (reason != null) aiReasons[id] = reason;
    }

    final products = (data['products'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (p) => SearchResultProduct(
            productId: p['productId'] as String? ?? '',
            name: p['name'] as String? ?? '',
            heroImageUrl: p['heroImageUrl'] as String? ?? '',
            price: (p['price'] as num?)?.toDouble() ?? 0,
            currency: p['currency'] as String? ?? 'NPR',
            averageRating: (p['averageRating'] as num?)?.toDouble() ?? 0,
            isSponsored: p['isSponsored'] == true || p['isSponsored'] == 'true',
            sponsoredLabel: _nonBlank(p['sponsoredLabel']),
            organicPosition: _position(p['organicPosition']),
            matchReason: aiReasons[p['productId']?.toString()],
          ),
        )
        .toList();
    final organicRank = <String, int>{
      for (var index = 0; index < products.length; index++)
        products[index].productId: index,
    };
    products.sort((a, b) {
      final aiComparison = (aiRank[a.productId] ?? 1 << 30).compareTo(
        aiRank[b.productId] ?? 1 << 30,
      );
      return aiComparison != 0
          ? aiComparison
          : organicRank[a.productId]!.compareTo(organicRank[b.productId]!);
    });

    final brands = (data['brands'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (b) => SearchResultBrand(
            brandId: b['brandId'] as String? ?? '',
            name: b['name'] as String? ?? '',
            logoUrl: b['logoUrl'] as String?,
            averageRating: (b['averageRating'] as num?)?.toDouble() ?? 0,
            productCount: (b['productCount'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);

    final reels = (data['reels'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (r) => SearchResultReel(
            reelId: r['reelId'] as String? ?? '',
            thumbnailUrl: r['thumbnailUrl'] as String? ?? '',
            viewCount: (r['viewCount'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);

    final creators = (data['creators'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (c) => SearchResultCreator(
            creatorProfileId: c['creatorProfileId'] as String? ?? '',
            handle: c['handle'] as String? ?? '',
            displayName: c['displayName'] as String? ?? '',
            avatarUrl: c['avatarUrl'] as String?,
            followerCount: (c['followerCount'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList(growable: false);

    return CustomerSearchResults(
      products: products,
      brands: brands,
      reels: reels,
      creators: creators,
      totalHits: (data['totalHits'] as num?)?.toInt() ?? 0,
      queryUnderstanding: _nonBlank(aiData?['queryUnderstanding']),
    );
  }
}

String? _nonBlank(Object? raw) =>
    raw is String && raw.trim().isNotEmpty ? raw.trim() : null;

/// A 1-based rank; anything else reads as unknown.
int? _position(Object? raw) {
  final value = raw is num
      ? raw.toInt()
      : (raw is String ? int.tryParse(raw.trim()) : null);
  return value != null && value > 0 ? value : null;
}

SearchResultProduct _visualProductFromJson(Map<String, dynamic> product) {
  final variants = (product['variants'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final variant = variants.cast<Map<String, dynamic>?>().firstWhere(
    (item) => item?['isDefault'] == true,
    orElse: () => variants.isEmpty ? null : variants.first,
  );
  final images = (product['images'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final image = images.cast<Map<String, dynamic>?>().firstWhere(
    (item) => item?['isPrimary'] == true,
    orElse: () => images.isEmpty ? null : images.first,
  );
  return SearchResultProduct(
    productId: product['id']?.toString() ?? '',
    name: product['name'] as String? ?? '',
    heroImageUrl: image?['cdnUrl'] as String? ?? '',
    price: (variant?['priceAmount'] as num?)?.toDouble() ?? 0,
    currency: variant?['priceCurrency'] as String? ?? 'NPR',
    averageRating: (product['averageRating'] as num?)?.toDouble() ?? 0,
    matchReason: 'Visually similar',
  );
}
