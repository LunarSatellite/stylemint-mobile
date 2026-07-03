import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

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

  // No PUT /status endpoint exists on the backend — the only real
  // state-changing action is archive (Active|OutOfStock -> Archived,
  // terminal soft-delete). The lone caller only ever passes
  // VendorProductStatus.discontinued (the "Deactivate" action), which maps
  // directly onto it.
  Future<void> updateProductStatus(
    String productId,
    String status,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/products/$productId/archive',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  // No DELETE endpoint exists on the backend — archive is the real soft-delete.
  Future<void> deleteProduct(
    String productId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/vendor/products/$productId/archive',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }
}
