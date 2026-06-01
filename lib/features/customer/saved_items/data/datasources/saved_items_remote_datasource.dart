import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

class SavedItemsRemoteDataSource {
  SavedItemsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/cart/saved-for-later`
  Future<Map<String, dynamic>> getSavedItems({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/cart/saved-for-later',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// POST `/v1/cart/saved-for-later`
  Future<void> saveItem(String productId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/cart/saved-for-later',
      data: {'productId': productId},
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE `/v1/cart/saved-for-later/{savedItemId}`
  Future<void> removeItem(String savedItemId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/cart/saved-for-later/$savedItemId',
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
