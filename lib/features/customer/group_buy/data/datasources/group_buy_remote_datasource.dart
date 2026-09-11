import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

class GroupBuyRemoteDataSource {
  GroupBuyRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `api/v1/group-buys` — global active list, no product filter
  /// server-side. Callers filter by productId client-side.
  Future<Map<String, dynamic>> listActive({String? cursor, int pageSize = 50}) async {
    final response = await apiClient.get(
      '/api/v1/group-buys',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listMine({String? cursor, int pageSize = 25}) async {
    final response = await apiClient.get(
      '/api/v1/group-buys/mine',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> start({
    required String productId,
    required int targetBuyerCount,
    required double discountPercent,
    required DateTime expiresUtc,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/api/v1/group-buys/start',
      data: {
        'productId': productId,
        'targetBuyerCount': targetBuyerCount,
        'discountPercent': discountPercent,
        'expiresUtc': expiresUtc.toUtc().toIso8601String(),
      },
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> join(
    String groupBuyId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/api/v1/group-buys/$groupBuyId/join',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
