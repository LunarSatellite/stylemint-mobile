import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

class MatchmakingRemoteDataSource {
  MatchmakingRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<Map<String, dynamic>> getRecommendations({
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/matches',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> invite({
    required String matchId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/matches/$matchId/invite',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return response as Map<String, dynamic>;
  }

  Future<void> dismiss({
    required String matchId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/vendor/matches/$matchId/dismiss',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }
}
