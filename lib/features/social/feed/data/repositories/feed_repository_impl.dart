import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/datasources/feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/feed_post_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';
import 'package:uuid/uuid.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final FeedRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<FeedPost>>> getFeed({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getFeed(limit: limit, cursor: cursor);
        final items = (data['items'] as List<dynamic>?)
                ?.map((e) => FeedPostDto.fromJson(e as Map<String, dynamic>).toDomain())
                .toList(growable: false) ??
            const <FeedPost>[];
        return right(
          PagedResult<FeedPost>(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? limit,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
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
  Future<Either<NetworkExceptions, FeedPost>> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.createPost(
          content: content,
          imagePaths: imagePaths,
          taggedProductIds: taggedProductIds,
          idempotencyKey: _uuid.v4(),
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
  Future<Either<NetworkExceptions, Unit>> likePost(String postId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.likePost(postId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> unlikePost(String postId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unlikePost(postId, _uuid.v4());
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
  Future<Either<NetworkExceptions, FeedComment>> commentOnPost(
    String postId,
    String content,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.commentOnPost(
          postId,
          content,
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
  Future<Either<NetworkExceptions, PagedResult<FeedComment>>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getComments(
          postId,
          limit: limit,
          cursor: cursor,
        );
        final items = (data['items'] as List<dynamic>?)
                ?.map((e) => FeedCommentDto.fromJson(e as Map<String, dynamic>).toDomain())
                .toList(growable: false) ??
            const <FeedComment>[];
        return right(
          PagedResult<FeedComment>(
            items: items,
            totalCount: data['totalCount'] as int? ?? items.length,
            pageSize: data['pageSize'] as int? ?? limit,
            nextCursor: data['nextCursor'] as String?,
            previousCursor: data['previousCursor'] as String?,
            hasMore: data['hasMore'] as bool? ?? false,
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
  Future<Either<NetworkExceptions, Unit>> sharePost(String postId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.sharePost(postId, _uuid.v4());
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
}
