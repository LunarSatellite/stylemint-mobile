import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/image_recognition_outcome.dart';

/// Real backend search across products, brands, reels and creators in a
/// single round-trip: `GET /api/v1/customer/search` signed in (personalised),
/// `GET /api/v1/public/search` signed out — the same response shape.
class CustomerSearchRemoteDataSource {
  CustomerSearchRemoteDataSource({
    required this.apiClient,
    bool Function()? isSignedIn,
  }) : _isSignedIn = isSignedIn ?? _assumeSignedIn;

  final ApiClient apiClient;

  /// Asked on every text search, so a sign-in or sign-out mid-session picks
  /// the right endpoint without rebuilding the data source.
  final bool Function() _isSignedIn;

  static bool _assumeSignedIn() => true;

  static const customerSearchPath = '/api/v1/customer/search';
  static const publicSearchPath = '/api/v1/public/search';
  static const aiSearchPath = '/api/v1/public/search/ai';

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
  ///
  /// The endpoint returns `{products, outcome, recognizedFeatures}`. It used
  /// to return a bare array, and when vision read features that the catalogue
  /// did not stock it filled that array with top-rated products by category —
  /// a no-match that looked exactly like a match. That contract is gone and
  /// is deliberately *not* tolerated here: a response that is not the object
  /// shape yields no products rather than an unexplained list, because the
  /// only thing a bare array could be now is the fabrication this replaced.
  Future<CustomerSearchResults> searchByImage(
    String imageDataUri, {
    int limit = 20,
  }) async {
    final response = await apiClient.post(
      '/api/v1/customer/search/image',
      data: {'imageUrl': imageDataUri, 'limit': limit},
    );
    final data = response is Map<String, dynamic> ? response : null;
    final outcome =
        ImageRecognitionOutcome.maybeFrom(data?['outcome']) ??
        ImageRecognitionOutcome.unknown;
    final rows = (data?['products'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>();
    // Defence in depth against a server regression: the backend's own type
    // invariant already forbids products on a no-match, so if any arrive
    // anyway they are dropped here rather than shown as recognitions.
    final products = outcome.isNoMatch
        ? const <SearchResultProduct>[]
        : rows.map(_visualProductFromJson).toList(growable: false);
    return CustomerSearchResults(
      products: products,
      brands: const [],
      reels: const [],
      creators: const [],
      totalHits: products.length,
      queryUnderstanding: products.isEmpty
          ? null
          : 'Products recognized from your photo',
      // Vision read the photo: that is the AI the screen may credit.
      aiApplied: products.isNotEmpty,
      imageRecognition: outcome,
      recognizedFeatures: _featureList(data?['recognizedFeatures']),
    );
  }

  static List<String> _featureList(Object? raw) => switch (raw) {
    final List<dynamic> rows =>
      rows
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
    _ => const <String>[],
  };

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
    // `imageRecognition` is absent when the request carried no image, and
    // when it is present and not `matched` every product here came from the
    // text query alone. Either way the caller decides what may be claimed;
    // the products themselves are real catalogue rows and are not dropped.
    final imageRecognition = ImageRecognitionOutcome.maybeFrom(
      data?['imageRecognition'],
    );
    final recognisedFromImage = imageRecognition?.isRecognisedMatch ?? false;
    final understanding =
        _nonBlank(data?['queryUnderstanding']) ??
        (imageRecognition != null && !recognisedFromImage
            // Nothing was recognised, so no phrase may say it was.
            ? null
            : (imageDataUris.length > 1
                  ? 'Products recognized across your video'
                  : 'Products recognized from your photo'));
    return CustomerSearchResults(
      products: products,
      brands: const [],
      reels: const [],
      creators: const [],
      totalHits: products.length,
      queryUnderstanding: understanding,
      aiApplied: understanding != null,
      imageRecognition: imageRecognition,
      recognizedFeatures: _featureList(data?['recognizedFeatures']),
    );
  }

  Future<CustomerSearchResults> searchByImages(
    List<String> imageDataUris, {
    int limit = 20,
  }) => searchMultimodal(imageDataUris, limit: limit);

  /// The unified search: signed in it is the personalised customer search,
  /// signed out the public one (same groups, same item shapes).
  Future<dynamic> _unifiedSearch(String query, int limit) async {
    final params = {'q': query, 'type': 'all', 'limit': limit};
    if (!_isSignedIn()) {
      return apiClient.authGet(publicSearchPath, queryParameters: params);
    }
    try {
      return await apiClient.get(customerSearchPath, queryParameters: params);
    } on DioException catch (e) {
      // A session that expired and could not be refreshed: the guest search
      // still answers, which beats an error page for a search box.
      if (e.response?.statusCode != 401) rethrow;
      return apiClient.authGet(publicSearchPath, queryParameters: params);
    }
  }

  Future<CustomerSearchResults> search(String query, {int limit = 20}) async {
    // Unified search remains the source of truth. AI contributes ordering and
    // explanations, but is optional so local-model outages never break search.
    final unifiedFuture = _unifiedSearch(query, limit);
    final aiFuture = apiClient
        .authGet(aiSearchPath, queryParameters: {'q': query, 'limit': limit})
        .catchError((_) => null);

    final response = await unifiedFuture;
    final aiResponse = await aiFuture;
    // A body that is not the grouped object (an older or broken server)
    // reads as no hits rather than a crash.
    final data = response is Map<String, dynamic>
        ? response
        : const <String, dynamic>{};
    final aiData = aiResponse is Map<String, dynamic> ? aiResponse : null;
    // Only an answer that says AI really contributed may reorder the hits or
    // explain them; a missing `aiApplied` (older server) counts as false, so
    // a plain keyword fallback never wears AI wording.
    final aiApplied = aiData?['aiApplied'] == true;
    final aiItems = !aiApplied
        ? const <Map<String, dynamic>>[]
        : (aiData?['items'] as List<dynamic>? ?? const <dynamic>[])
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
            // The storefront route takes the vendor ACCOUNT id. Prefer the
            // explicit field; `brandId` is that id too once the server
            // follows the search contract.
            brandId:
                _nonBlank(b['vendorAccountId']) ??
                _nonBlank(b['brandId']) ??
                '',
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
            followerCount: (c['followerCount'] as num?)?.toInt(),
          ),
        )
        .toList(growable: false);

    return CustomerSearchResults(
      products: products,
      brands: brands,
      reels: reels,
      creators: creators,
      totalHits: (data['totalHits'] as num?)?.toInt() ?? 0,
      queryUnderstanding: aiApplied
          ? _nonBlank(aiData?['queryUnderstanding'])
          : null,
      aiApplied: aiApplied,
      productTotal: switch (data['productTotal']) {
        final num total when total >= 0 => total.toInt(),
        _ => null,
      },
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
