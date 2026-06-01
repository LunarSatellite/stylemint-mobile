import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/data/datasources/co_watch_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/entities/co_watch.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/repositories/co_watch_repository.dart';

class CoWatchRepositoryImpl implements CoWatchRepository {
  CoWatchRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final CoWatchRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;
  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, List<CoWatchSession>>> getActiveSessions() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getActiveSessions();
        return right(dtos.map((dto) => dto.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CoWatchSession>> createSession(
    CoWatchContentType contentType,
    String contentId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createSession(
          contentType == CoWatchContentType.product ? 'product' : 'reel',
          contentId,
          _uuid.v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CoWatchSession>> joinSession(String sessionId) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.joinSession(sessionId, _uuid.v4());
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> leaveSession(String sessionId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.leaveSession(sessionId, _uuid.v4());
        return right(unit);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, CoWatchReaction>> sendReaction(
    String sessionId,
    String reaction,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.sendReaction(
          sessionId,
          reaction,
          _uuid.v4(),
        );
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, List<CoWatchReaction>>> getReactions(
    String sessionId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getReactions(sessionId);
        return right(dtos.map((dto) => dto.toDomain()).toList(growable: false));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }
}
