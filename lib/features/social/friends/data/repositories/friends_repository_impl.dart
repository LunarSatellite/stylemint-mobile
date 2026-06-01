import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/data/datasources/friends_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/repositories/friends_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  FriendsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final FriendsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<Friend>>> getFriends({
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getFriends(
          search: search,
          limit: limit,
          cursor: cursor,
        );
        return right(
          PagedResult(
            items: dto.items.map((d) => d.toDomain()).toList(growable: false),
            totalCount: dto.totalCount,
            pageSize: dto.pageSize,
            nextCursor: dto.nextCursor,
            previousCursor: dto.previousCursor,
            hasMore: dto.hasMore,
          ),
        );
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
  Future<Either<NetworkExceptions, List<FriendRequest>>> getFriendRequests() async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.getFriendRequests();
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
  Future<Either<NetworkExceptions, Unit>> sendFriendRequest(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sendFriendRequest(userId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> acceptRequest(String requestId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.acceptRequest(requestId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> declineRequest(String requestId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.declineRequest(requestId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> unfriend(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unfriend(userId, _uuid.v4());
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
  Future<Either<NetworkExceptions, List<Friend>>> importContacts(
    List<String> contacts,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dtos = await remoteDataSource.importContacts(contacts, _uuid.v4());
        return right(dtos.map((d) => d.toDomain()).toList(growable: false));
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
