import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/models/message_thread_dto.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/models/direct_message_dto.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/models/paged_dto.dart';

/// REST client for `StyleMint.Modules.Messaging` (`/v1/message-threads`).
/// The API is role-agnostic; the JWT `sub` claim identifies the caller
/// on every request so the same client works for vendor and creator.
class MessagingRemoteDataSource {
  MessagingRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<PagedDto<MessageThreadDto>> listThreads({
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/message-threads',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'pageSize': pageSize,
      },
    );
    return PagedDto<MessageThreadDto>.fromJson(
      response as Map<String, dynamic>,
      MessageThreadDto.fromJson,
    );
  }

  Future<PagedDto<DirectMessageDto>> listMessages(
    String threadId, {
    String? cursor,
    int pageSize = 50,
  }) async {
    final response = await apiClient.get(
      '/v1/message-threads/$threadId/messages',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'pageSize': pageSize,
      },
    );
    return PagedDto<DirectMessageDto>.fromJson(
      response as Map<String, dynamic>,
      DirectMessageDto.fromJson,
    );
  }

  Future<MessageThreadDto> openThread({
    required int scope,
    required String otherParticipantAccountId,
    String? contextId,
  }) async {
    final response = await apiClient.post(
      '/v1/message-threads',
      data: <String, dynamic>{
        'scope': scope,
        'otherParticipantId': otherParticipantAccountId,
        if (contextId != null) 'contextId': contextId,
      },
    );
    return MessageThreadDto.fromJson(response as Map<String, dynamic>);
  }

  Future<DirectMessageDto> postMessage({
    required String threadId,
    required String body,
  }) async {
    final response = await apiClient.post(
      '/v1/message-threads/$threadId/messages',
      data: <String, dynamic>{'body': body},
    );
    return DirectMessageDto.fromJson(response as Map<String, dynamic>);
  }
}