import 'package:dio/dio.dart' show Options;
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/discover_data_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';

class DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _uuid = Uuid();

  Future<DiscoverDataDto> getDiscoverData() async {
    final response = await apiClient.get('/v1/feed/explore');
    // The explore feed returns a JSON array (`[]` when there is nothing to
    // show). Only an object payload carries the curated discover sections, so
    // anything that isn't a Map maps to an empty (default) DiscoverDataDto.
    if (response is Map<String, dynamic>) {
      return DiscoverDataDto.fromJson(response);
    }
    return const DiscoverDataDto();
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
    final images =
        (json['images'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
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
    final cartView = await apiClient.post(
      '/v1/cart/lines',
      data: {
        'productId': productId,
        'productVariantId': variantId,
        'quantity': 1,
      },
      options: _idempotent(idempotencyKey),
    ) as Map<String, dynamic>;
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
