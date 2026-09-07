import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/direct_message.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

/// One repository for both vendor and creator sides. The backend
/// `MessageThread` API is role-agnostic; the JWT `sub` claim identifies
/// the caller.
abstract class MessagingRepository {
  /// `GET /v1/message-threads` - paginated threads the caller participates in.
  Future<Either<NetworkExceptions, PagedResult<MessageThread>>> listMyThreads({
    String? cursor,
    int pageSize = 25,
  });

  /// `GET /v1/message-threads/{threadId}/messages` - paginated history.
  Future<Either<NetworkExceptions, PagedResult<DirectMessage>>> listMessages(
    String threadId, {
    String? cursor,
    int pageSize = 50,
  });

  /// `POST /v1/message-threads` - open (or fetch existing) thread with
  /// the given counterpart.
  Future<Either<NetworkExceptions, MessageThread>> openThread({
    required MessageThreadScope scope,
    required String otherParticipantAccountId,
    String? contextId,
  });

  /// `POST /v1/message-threads/{threadId}/messages` - send a text message.
  Future<Either<NetworkExceptions, DirectMessage>> postMessage({
    required String threadId,
    required String body,
  });
}
