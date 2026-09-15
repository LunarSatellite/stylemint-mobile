import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

class ReelsRepositoryImpl implements ReelsRepository {
  ReelsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReelsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final page = await remoteDataSource.getReelsFeed(
          limit: limit,
          cursor: cursor,
        );
        return right(page);
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          // Was `NetworkExceptions.unexpectedError()` (no detail) — any
          // non-Dio exception here (e.g. a bad-cast while mapping the feed
          // response into ReelDto) was completely silent to the UI/logs.
          return left(NetworkExceptions.server('$e'));
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async {
    if (await networkInfo.isConnected) {
      try {
        return right(await remoteDataSource.getReelDetail(reelId));
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 404) {
            return left(const NetworkExceptions.notFound());
          }
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
  Future<Either<NetworkExceptions, ReelLikeResult>> likeReel(
    String reelId,
  ) => _like(() => remoteDataSource.likeReel(reelId, _uuid.v4()));

  @override
  Future<Either<NetworkExceptions, ReelLikeResult>> unlikeReel(
    String reelId,
  ) => _like(() => remoteDataSource.unlikeReel(reelId, _uuid.v4()));

  /// One Idempotency-Key per call: the notifier calls once per tap and never
  /// retries, so a key is never reused across attempts.
  Future<Either<NetworkExceptions, ReelLikeResult>> _like(
    Future<ReelLikeResult> Function() request,
  ) async {
    if (!await networkInfo.isConnected) {
      return left(NetworkExceptions.noInternetConnection());
    }
    try {
      return right(await request());
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return left(const NetworkExceptions.auth());
      }
      return left(NetworkExceptions.server(e.message.toString()));
    } on NetworkExceptions catch (e) {
      return left(e);
    } on Object {
      return left(NetworkExceptions.unexpectedError());
    }
  }

  @override
  Future<Either<NetworkExceptions, Unit>> addToWishlist(String reelId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addToWishlist(reelId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> removeFromWishlist(String reelId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removeFromWishlist(reelId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> followCreator(String creatorId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.followCreator(creatorId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> unfollowCreator(String creatorId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.unfollowCreator(creatorId, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> commentOnReel(
    String reelId,
    String commentText,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.commentOnReel(reelId, commentText, _uuid.v4());
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
  Future<Either<NetworkExceptions, Unit>> shareReel(String reelId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.shareReel(reelId, _uuid.v4());
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
