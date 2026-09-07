import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/data/models/co_watch_dto.dart';

class CoWatchRemoteDataSource {
  CoWatchRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<CoWatchSessionDto>> getActiveSessions() async {
    final response = await apiClient.get('/v1/co-watch');
    final items = (response as List<dynamic>?)
        ?.map((e) => CoWatchSessionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items ?? const [];
  }

  Future<CoWatchSessionDto> getSession(String sessionId) async {
    final response = await apiClient.get('/v1/co-watch/$sessionId');
    return CoWatchSessionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CoWatchSessionDto> createSession(
    String reelId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/co-watch',
      data: {'reelId': reelId},
      options: _idempotent(idempotencyKey),
    );
    return CoWatchSessionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<CoWatchSessionDto> joinSession(
    String sessionId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/co-watch/join',
      data: {'sessionId': sessionId},
      options: _idempotent(idempotencyKey),
    );
    return CoWatchSessionDto.fromJson(response as Map<String, dynamic>);
  }

  // Co-watch is 2 people; "leave" ends the session for both.
  Future<void> leaveSession(
    String sessionId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/co-watch/$sessionId/end',
      options: _idempotent(idempotencyKey),
    );
  }

  Future<CoWatchReactionDto> sendReaction(
    String sessionId,
    String reaction,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/co-watch/$sessionId/reactions',
      data: {'reaction': reaction},
      options: _idempotent(idempotencyKey),
    );
    return CoWatchReactionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CoWatchReactionDto>> getReactions(String sessionId) async {
    final response =
        await apiClient.get('/v1/co-watch/$sessionId/reactions');
    final items = (response as List<dynamic>?)
        ?.map((e) => CoWatchReactionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items ?? const [];
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}