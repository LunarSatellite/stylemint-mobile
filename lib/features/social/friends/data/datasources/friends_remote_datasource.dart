import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/data/models/friend_dto.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class FriendsRemoteDataSource {
  FriendsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/connections
  Future<PagedResult<FriendDto>> getFriends({
    String? search,
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/connections',
      queryParameters: {
        'limit': limit,
        if (search != null) 'search': search,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => FriendDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return PagedResult(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
      pageSize: data['pageSize'] as int? ?? limit,
      nextCursor: data['nextCursor'] as String?,
      previousCursor: data['previousCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// GET /v1/connection-requests/inbox
  Future<List<FriendRequestDto>> getFriendRequests() async {
    final response = await apiClient.get('/v1/connection-requests/inbox');

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => FriendRequestDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  /// POST /v1/connection-requests
  Future<void> sendFriendRequest(
    String userId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/connection-requests',
      data: {'userId': userId},
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/connection-requests/{requestId}/accept
  Future<void> acceptRequest(
    String requestId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/connection-requests/$requestId/accept',
      data: {'requestId': requestId},
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/connection-requests/{requestId}/decline
  Future<void> declineRequest(
    String requestId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/connection-requests/$requestId/decline',
      data: {'requestId': requestId},
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE /v1/connections/{otherAccountId}
  Future<void> unfriend(String userId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/connections/$userId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/contact-imports
  Future<List<FriendDto>> importContacts(
    List<String> contacts,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/contact-imports',
      data: {'contacts': contacts},
      options: _idempotent(idempotencyKey),
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => FriendDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
