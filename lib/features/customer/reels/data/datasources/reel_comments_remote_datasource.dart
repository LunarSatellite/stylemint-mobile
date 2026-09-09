import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_comment_dto.dart';
import 'package:uuid/uuid.dart';

/// Comments on a reel — `/v1/customer/reels/{reelId}/comments`.
class ReelCommentsRemoteDataSource {
  ReelCommentsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET list (first page). PagedResult — items live under `items`.
  Future<List<ReelCommentDto>> list(String reelId, {int pageSize = 50}) async {
    final response = await apiClient.get(
      '/v1/customer/reels/$reelId/comments',
      queryParameters: {'pageSize': pageSize},
    );
    final map = response as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map(ReelCommentDto.fromJson)
        .toList(growable: false);
  }

  /// POST a new comment; returns the created comment.
  Future<ReelCommentDto> post(String reelId, String body) async {
    final response = await apiClient.post(
      '/v1/customer/reels/$reelId/comments',
      data: {'body': body},
    );
    return ReelCommentDto.fromJson(response as Map<String, dynamic>);
  }

  /// Persists an idempotent like on a Style Mint comment.
  Future<void> like(String reelId, String commentId) => apiClient.post(
    '/v1/customer/reels/$reelId/comments/$commentId/like',
    options: _idempotent(),
  );

  /// Removes the caller's like. The server treats repeated unlikes as a no-op.
  Future<void> unlike(String reelId, String commentId) => apiClient.authDelete(
    '/v1/customer/reels/$reelId/comments/$commentId/like',
    options: _idempotent(),
  );

  Options _idempotent() => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': const Uuid().v4(),
    },
  );
}
