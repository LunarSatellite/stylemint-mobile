import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/models/vendor_product_dto.dart';

class VendorProductsRemoteDataSource {
  VendorProductsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> getProducts({
    required int limit,
    String? cursor,
    String? status,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/products',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'status': status,
      },
    );
    return response as Map<String, dynamic>;
  }

  // TODO(swagger): GET /v1/vendor/products/{productId} not found. Use GET /v1/vendor/products with query filter
  Future<VendorProductDto> getProduct(String productId) async {
    final response = await apiClient.get('/v1/vendor/products/$productId');
    return VendorProductDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): PUT /v1/vendor/products/{productId}/status not found. Use PATCH /v1/vendor/products/{productId}/stock or POST /v1/vendor/products/{productId}/archive
  Future<VendorProductDto> updateProductStatus(
    String productId,
    String status,
    String idempotencyKey,
  ) async {
    final response = await apiClient.put(
      '/v1/vendor/products/$productId/status',
      data: {'status': status},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return VendorProductDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): DELETE /v1/vendor/products/{productId} not found. Use POST /v1/vendor/products/{productId}/archive instead
  Future<void> deleteProduct(
    String productId,
    String idempotencyKey,
  ) async {
    await apiClient.authDelete(
      '/v1/vendor/products/$productId',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }
}
