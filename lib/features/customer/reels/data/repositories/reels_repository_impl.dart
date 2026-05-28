import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import '../../domain/entities/reel.dart';
import '../../domain/repositories/reels_repository.dart';
import '../datasources/reels_remote_datasource.dart';

/// Implementation of ReelsRepository
/// Handles error mapping and DTO to entity conversion
class ReelsRepositoryImpl implements ReelsRepository {
  const ReelsRepositoryImpl(this._datasource);

  final ReelsRemoteDatasource _datasource;

  @override
  Future<Either<Failure, List<Reel>>> getReelsFeed({
    required int limit,
    String? cursor,
  }) async {
    try {
      final dtos = await _datasource.getReelsFeed(
        limit: limit,
        cursor: cursor,
      );
      return right(dtos.map((dto) => dto.toDomain()).toList());
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, Reel>> getReelDetail(String reelId) async {
    try {
      final dto = await _datasource.getReelDetail(reelId);
      return right(dto.toDomain());
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> likeReel(String reelId) async {
    try {
      final result = await _datasource.likeReel(
        reelId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> unlikeReel(String reelId) async {
    try {
      final result = await _datasource.unlikeReel(
        reelId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> addToWishlist(String reelId) async {
    try {
      final result = await _datasource.addToWishlist(
        reelId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> removeFromWishlist(String reelId) async {
    try {
      final result = await _datasource.removeFromWishlist(
        reelId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> followCreator(String creatorId) async {
    try {
      final result = await _datasource.followCreator(
        creatorId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> unfollowCreator(String creatorId) async {
    try {
      final result = await _datasource.unfollowCreator(
        creatorId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> commentOnReel(
    String reelId,
    String commentText,
  ) async {
    try {
      final result = await _datasource.commentOnReel(
        reelId,
        commentText,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> shareReel(String reelId) async {
    try {
      final result = await _datasource.shareReel(
        reelId,
        _generateIdempotencyKey(),
      );
      return right(result);
    } on DioException catch (e) {
      return left(_mapError(e));
    }
  }

  /// Maps DioException to Failure
  Failure _mapError(DioException e) {
    final status = e.response?.statusCode;
    final code = e.response?.data?['errorCode'] as String?;

    if (status == 401) {
      return const AuthFailure();
    } else if (status == 403) {
      return const PermissionFailure();
    } else if (status == 404) {
      return const NotFoundFailure();
    } else if (status == 409 && code == 'concurrency.conflict') {
      return const ConflictFailure();
    } else if (status != null && status >= 500) {
      return const ServerFailure();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown) {
      return const NetworkFailure();
    }

    return const UnknownFailure();
  }

  /// Generates idempotency key for mutations
  String _generateIdempotencyKey() {
    // TODO: Use uuid package to generate v4 UUID
    // For now, use timestamp-based key
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

/// Additional failure types
class PermissionFailure extends Failure {
  const PermissionFailure();
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

class ConflictFailure extends Failure {
  const ConflictFailure();
}

class UnknownFailure extends Failure {
  const UnknownFailure();
}
