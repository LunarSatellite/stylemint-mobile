import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/discover_data_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/product_detail_dto.dart';

class DiscoveryRemoteDataSource {
  DiscoveryRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<DiscoverDataDto> getDiscoverData() async {
    final response = await apiClient.get('/v1/feed/explore');
    return DiscoverDataDto.fromJson(response as Map<String, dynamic>);
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

  // TODO: No related-products endpoint in Swagger — consider `/v1/public/categories/{slug}/products` or recommendations
  Future<List<RelatedProductDto>> getRelatedProducts(String productId) async {
    final response = await apiClient.get(
      '/v1/public/categories/$productId/products',
    );
    final data = response as List<dynamic>;
    return data
        .map((e) => RelatedProductDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
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
        'qty': qty,
        if (variantId != null) 'variantId': variantId,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  // TODO: No toggle-save endpoint in Swagger — use `/v1/cart/saved-for-later` to save, `/v1/cart/saved-for-later/{savedItemId}` to remove
  Future<bool> toggleSaved(String productId, String idempotencyKey) async {
    final response = await apiClient.post(
      '/v1/cart/saved-for-later',
      data: {'productId': productId},
      options: _idempotent(idempotencyKey),
    );
    final data = response as Map<String, dynamic>;
    return data['isSaved'] as bool? ?? false;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
