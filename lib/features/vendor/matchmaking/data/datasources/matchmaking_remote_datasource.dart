import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/models/matchmaking_dto.dart';

class MatchmakingRemoteDataSource {
  MatchmakingRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<MatchRecommendationDto>> getRecommendations({
    Map<String, dynamic>? queryParams,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/matches',
      queryParameters: queryParams,
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => MatchRecommendationDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  // TODO(swagger): GET /v1/vendor/matchmaking/compatibility/{creatorId} not found in Swagger
  Future<int> getCompatibilityScore(String creatorId) async {
    final response = await apiClient.get(
      '/v1/vendor/matchmaking/compatibility/$creatorId',
    );
    return (response['score'] as int?) ?? 0;
  }

  // TODO(swagger): POST /v1/vendor/matchmaking/invite not found. Use POST /v1/vendor/matches/{id}/invite
  Future<void> inviteToCampaign({
    required String campaignId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/vendor/matchmaking/invite',
      data: {
        'campaignId': campaignId,
        'creatorId': creatorId,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }
}
