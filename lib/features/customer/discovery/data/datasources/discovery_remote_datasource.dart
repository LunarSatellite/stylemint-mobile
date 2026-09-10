import 'package:dio/dio.dart' show Options;
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/discover_data_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';

class DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _uuid = Uuid();

  /// Assembles the Discover landing page from the four curated endpoints
  /// that actually back it — there is no single `/v1/discover` payload.
  /// (Previously this called `/v1/feed/explore`, which returns a bare array
  /// of raw feed posts with none of these fields; the landing page was
  /// permanently blank as a result.)
  Future<DiscoverDataDto> getDiscoverData() async {
    final results = await Future.wait([
      apiClient.get('/v1/public/categories'),
      apiClient.get('/v1/public/popular-searches'),
      apiClient.get('/api/v1/customer/discover/trending', queryParameters: {
        'window': '7d',
        'limit': 20,
      }),
      apiClient.get('/api/v1/customer/discover/top-creators'),
    ]);

    final categories = (results[0] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((c) => DiscoverCategoryDto(
              id: c['id'] as String? ?? '',
              label: c['nameEn'] as String? ?? '',
            ))
        .where((c) => c.id.isNotEmpty)
        .toList(growable: false);

    final popularSearches = (results[1] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((s) => s['label'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    final trendingPage = results[2] as Map<String, dynamic>? ?? const {};
    final trending = (trendingPage['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((item) => item['product'] as Map<String, dynamic>?)
        .whereType<Map<String, dynamic>>()
        .map((p) => TrendingProductDto(
              id: p['productId'] as String? ?? '',
              name: p['name'] as String? ?? '',
              amount: (p['price'] as num?)?.toDouble() ?? 0,
              currency: p['currency'] as String? ?? 'NPR',
              imageUrl: p['heroImageUrl'] as String? ?? '',
              rating: (p['averageRating'] as num?)?.toDouble() ?? 0,
            ))
        .toList(growable: false);

    final topCreators = (results[3] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((c) => DiscoverCreatorDto(
              id: c['accountId'] as String? ?? '',
              name: c['displayName'] as String? ?? '',
              handle: c['handle'] as String? ?? '',
              avatarUrl: c['avatarUrl'] as String? ?? '',
              followers: (c['followerCount'] as num?)?.toInt() ?? 0,
            ))
        .where((c) => c.id.isNotEmpty)
        .toList(growable: false);

    return DiscoverDataDto(
      popularSearches: popularSearches,
      categories: categories,
      trending: trending,
      topCreators: topCreators,
    );
  }

  /// Category landing is keyed by the category GUID supplied by Explore.
  /// The discovery surface provides featured product cards rather than a
  /// synthetic catalog, so retain only fields that API actually returns.
  Future<List<TrendingProductDto>> getCategoryProducts(
    String categoryId,
  ) async {
    final response = await apiClient.get(
      '/api/v1/customer/discover/categories/$categoryId',
    );
    final data = response as Map<String, dynamic>;
    return (data['featuredProducts'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(
          (product) => TrendingProductDto(
            id: product['productId'] as String? ?? '',
            name: product['name'] as String? ?? '',
            amount: (product['price'] as num?)?.toDouble() ?? 0,
            currency: product['currency'] as String? ?? 'NPR',
            imageUrl: product['heroImageUrl'] as String? ?? '',
            rating: (product['averageRating'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<ProductDetailDto> getProductDetail(String productId) async {
    final response = await apiClient.get('/v1/public/products/$productId');
    return ProductDetailDto.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getProductReviews(
    String productId, {
    int limit = 10,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/products/$productId/reviews',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<List<RelatedProductDto>> getRelatedProducts(String productId) async {
    final response = await apiClient.get(
      '/v1/public/products/$productId/related',
    );
    final data = response as List<dynamic>;
    return data
        .map((e) => _relatedProductFromApi(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // The backend returns the full nested ProductDto (variants + images),
  // not a flat card shape — pick the primary image and default variant.
  RelatedProductDto _relatedProductFromApi(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final primaryImage = images.isEmpty
        ? null
        : images.firstWhere(
            (i) => i['isPrimary'] == true,
            orElse: () => images.first,
          );
    final variants = (json['variants'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final defaultVariant = variants.isEmpty
        ? null
        : variants.firstWhere(
            (v) => v['isDefault'] == true,
            orElse: () => variants.first,
          );
    return RelatedProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: primaryImage?['cdnUrl'] as String? ?? '',
      amount: (defaultVariant?['priceAmount'] as num?)?.toDouble() ?? 0,
      currency: defaultVariant?['priceCurrency'] as String? ?? 'NPR',
      rating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> addToCart({
    required String productId,
    required int qty,
    String? variantId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/cart/lines',
      data: {
        'productId': productId,
        'quantity': qty,
        if (variantId != null) 'productVariantId': variantId,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  // "Save for later" only exists as "promote an existing cart line" on the
  // backend — there's no direct wishlist-a-product endpoint. So saving from
  // the PDP heart icon silently adds qty 1 to cart, then promotes that line.
  Future<bool> toggleSaved(
    String productId,
    String? variantId,
    String idempotencyKey,
  ) async {
    final savedItems =
        await apiClient.get('/v1/cart/saved-for-later') as List<dynamic>;
    final existing = savedItems.cast<Map<String, dynamic>>().where(
      (item) => item['productId'] == productId,
    );
    if (existing.isNotEmpty) {
      await apiClient.authDelete(
        '/v1/cart/saved-for-later/${existing.first['id']}',
      );
      return false;
    }

    if (variantId == null) {
      throw Exception('Select a variant before saving this item.');
    }
    final cartView =
        await apiClient.post(
              '/v1/cart/lines',
              data: {
                'productId': productId,
                'productVariantId': variantId,
                'quantity': 1,
              },
              options: _idempotent(idempotencyKey),
            )
            as Map<String, dynamic>;
    final lines = (cartView['lines'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final line = lines.firstWhere(
      (l) => l['productId'] == productId && l['productVariantId'] == variantId,
    );
    await apiClient.post(
      '/v1/cart/saved-for-later/from-cart/${line['lineId']}',
      options: _idempotent(_uuid.v4()),
    );
    return true;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
