import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/data/models/group_dto.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class GroupsRemoteDataSource {
  GroupsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/groups/discover/browse
  Future<List<StyleGroupDto>> getGroups({
    String? category,
    String? search,
  }) async {
    final response = await apiClient.get(
      '/v1/groups/discover/browse',
      queryParameters: {
        if (category != null) 'category': category,
        if (search != null) 'search': search,
      },
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => StyleGroupDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  /// GET /v1/groups/{groupId}
  Future<StyleGroupDto> getGroupDetail(String groupId) async {
    final response = await apiClient.get('/v1/groups/$groupId');
    return StyleGroupDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/groups/{groupId}/members/join
  Future<void> joinGroup(String groupId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/groups/$groupId/members/join',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST /v1/groups/{groupId}/members/leave
  Future<void> leaveGroup(String groupId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/groups/$groupId/members/leave',
      options: _idempotent(idempotencyKey),
    );
  }

  /// GET /v1/groups/{groupId}/posts
  Future<PagedResult<GroupPostDto>> getGroupFeed(
    String groupId, {
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/groups/$groupId/posts',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => GroupPostDto.fromJson(e as Map<String, dynamic>))
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

  /// POST /v1/groups/{groupId}/posts
  Future<GroupPostDto> createGroupPost({
    required String groupId,
    required String content,
    List<String>? images,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/groups/$groupId/posts',
      data: {
        'content': content,
        if (images != null) 'images': images,
      },
      options: _idempotent(idempotencyKey),
    );
    return GroupPostDto.fromJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
