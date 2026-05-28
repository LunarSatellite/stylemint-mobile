import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import '../models/reel_dto.dart';

/// Remote data source for reels
/// Handles all API calls related to reels
abstract class ReelsRemoteDatasource {
  Future<List<ReelDTO>> getReelsFeed({
    required int limit,
    String? cursor,
  });

  Future<ReelDTO> getReelDetail(String reelId);

  Future<bool> likeReel(String reelId, String idempotencyKey);

  Future<bool> unlikeReel(String reelId, String idempotencyKey);

  Future<bool> addToWishlist(String reelId, String idempotencyKey);

  Future<bool> removeFromWishlist(String reelId, String idempotencyKey);

  Future<bool> followCreator(String creatorId, String idempotencyKey);

  Future<bool> unfollowCreator(String creatorId, String idempotencyKey);

  Future<bool> commentOnReel(
    String reelId,
    String commentText,
    String idempotencyKey,
  );

  Future<bool> shareReel(String reelId, String idempotencyKey);
}

/// Implementation of ReelsRemoteDatasource
class ReelsRemoteDatasourceImpl implements ReelsRemoteDatasource {
  const ReelsRemoteDatasourceImpl(this._dioClient);

  final DioClient _dioClient;

  @override
  Future<List<ReelDTO>> getReelsFeed({
    required int limit,
    String? cursor,
  }) async {
    try {
      final response = await _dioClient.get(
        '/v1/reels/feed',
        queryParameters: {
          'limit': limit,
          if (cursor != null) 'cursor': cursor,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final reels = (data['reels'] as List)
          .map((e) => ReelDTO.fromJson(e as Map<String, dynamic>))
          .toList();

      return reels;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<ReelDTO> getReelDetail(String reelId) async {
    try {
      final response = await _dioClient.get('/v1/reels/$reelId');
      return ReelDTO.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> likeReel(String reelId, String idempotencyKey) async {
    try {
      await _dioClient.post(
        '/v1/reels/$reelId/like',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> unlikeReel(String reelId, String idempotencyKey) async {
    try {
      await _dioClient.post(
        '/v1/reels/$reelId/unlike',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> addToWishlist(String reelId, String idempotencyKey) async {
    try {
      await _dioClient.post(
        '/v1/reels/$reelId/wishlist',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> removeFromWishlist(String reelId, String idempotencyKey) async {
    try {
      await _dioClient.delete(
        '/v1/reels/$reelId/wishlist',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> followCreator(String creatorId, String idempotencyKey) async {
    try {
      await _dioClient.post(
        '/v1/creators/$creatorId/follow',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> unfollowCreator(String creatorId, String idempotencyKey) async {
    try {
      await _dioClient.post(
        '/v1/creators/$creatorId/unfollow',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> commentOnReel(
    String reelId,
    String commentText,
    String idempotencyKey,
  ) async {
    try {
      await _dioClient.post(
        '/v1/reels/$reelId/comments',
        data: {'text': commentText},
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<bool> shareReel(String reelId, String idempotencyKey) async {
    try {
      await _dioClient.post(
        '/v1/reels/$reelId/share',
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      return true;
    } on DioException {
      rethrow;
    }
  }
}
