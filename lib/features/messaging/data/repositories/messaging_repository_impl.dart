import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/direct_message.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  MessagingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final MessagingRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  @override
  Future<Either<NetworkExceptions, PagedResult<MessageThread>>> listMyThreads({
    String? cursor,
    int pageSize = 25,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final page = await remoteDataSource.listThreads(
        cursor: cursor,
        pageSize: pageSize,
      );
      return right(PagedResult<MessageThread>(
        items: page.items.map((d) => d.toDomain()).toList(growable: false),
        totalCount: page.totalCount,
        pageSize: page.pageSize == 0 ? pageSize : page.pageSize,
        nextCursor: page.nextCursor,
        previousCursor: null,
        hasMore: page.nextCursor != null,
      ));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, PagedResult<DirectMessage>>> listMessages(
    String threadId, {
    String? cursor,
    int pageSize = 50,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      final page = await remoteDataSource.listMessages(
        threadId,
        cursor: cursor,
        pageSize: pageSize,
      );
      return right(PagedResult<DirectMessage>(
        items: page.items.map((d) => d.toDomain()).toList(growable: false),
        totalCount: page.totalCount,
        pageSize: page.pageSize == 0 ? pageSize : page.pageSize,
        nextCursor: page.nextCursor,
        previousCursor: null,
        hasMore: page.nextCursor != null,
      ));
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, MessageThread>> openThread({
    required MessageThreadScope scope,
    required String otherParticipantAccountId,
    String? contextId,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    if (otherParticipantAccountId.isEmpty) {
      return left(NetworkExceptions.unexpectedError());
    }
    try {
      final dto = await remoteDataSource.openThread(
        scope: scope.toInt(),
        otherParticipantAccountId: otherParticipantAccountId,
        contextId: contextId,
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, DirectMessage>> postMessage({
    required String threadId,
    required String body,
  }) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    if (body.trim().isEmpty) {
      return left(NetworkExceptions.unexpectedError());
    }
    try {
      final dto = await remoteDataSource.postMessage(
        threadId: threadId,
        body: body.trim(),
      );
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } catch (_) {
      return left(NetworkExceptions.unexpectedError());
    }
  }
}