import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_dto.dart';

/// Remote datasource for the reels feature.
/// Talks to the backend reels endpoints via [ApiClient]; throws on failure
/// (exceptions are mapped to a Failure in the repository layer).
class ReelsRemoteDataSource {
  ReelsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/feed` — cursor-paginated reels feed.
  /// GET `/api/v1/customer/feed` — the customer "For You" reel feed
  /// (Discovery). Returns `{ items: [{ kind, reel: {...}, ... }], nextCursor }`;
  /// we keep the reel-bearing items and map each card to [ReelDto]. Caption +
  /// tagged products aren't on the card — they're hydrated lazily via
  /// [getReelDetail].
  Future<List<ReelDto>> getReelsFeed({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/api/v1/customer/feed',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => e['reel'])
        .whereType<Map<String, dynamic>>()
        .map(_reelCardToDto)
        .toList(growable: false);
  }

  /// Maps a Discovery feed `ReelCardDto` (the card shape) onto the reels
  /// feature's [ReelDto]. `creatorProfileId` is the creator's account id
  /// (the follow target). Caption/createdAt/tagged-products aren't on the card.
  ReelDto _reelCardToDto(Map<String, dynamic> r) {
    return ReelDto(
      id: (r['reelId'] as String?) ?? '',
      sourceUrl: (r['externalUrl'] as String?) ?? '',
      thumbnailUrl: (r['thumbnailUrl'] as String?) ?? '',
      creatorId: (r['creatorProfileId'] as String?) ?? '',
      creatorName: (r['creatorHandle'] as String?) ?? '',
      creatorAvatarUrl: (r['creatorAvatarUrl'] as String?) ?? '',
      caption: '',
      createdAt: DateTime.now(),
      musicTitle: (r['audioTrackName'] as String?) ?? '',
      musicArtist: (r['audioArtistName'] as String?) ?? '',
      likeCount: (r['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (r['commentCount'] as num?)?.toInt() ?? 0,
      isCreatorFollowed: r['isCreatorFollowed'] as bool?,
    );
  }

  /// GET `/v1/public/reels/{id}` — single reel detail.
  Future<ReelDto> getReelDetail(String reelId) async {
    final response = await apiClient.get('/v1/public/reels/$reelId');
    return ReelDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/reactions/posts/{postId}` — like a reel (reels are posts).
  Future<void> likeReel(String reelId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/reactions/posts/$reelId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE `/v1/reactions/posts/{postId}` — unlike a reel (reels are posts).
  Future<void> unlikeReel(String reelId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/reactions/posts/$reelId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/cart/saved-for-later` — add to saved-for-later (wishlist).
  Future<void> addToWishlist(String reelId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/cart/saved-for-later',
      data: {'productId': reelId},
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE `/v1/cart/saved-for-later/{savedItemId}` — remove from wishlist.
  Future<void> removeFromWishlist(String reelId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/cart/saved-for-later/$reelId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/connection-requests` — follow a creator.
  Future<void> followCreator(String creatorId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/connection-requests',
      data: {'targetAccountId': creatorId},
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE `/v1/connections/{otherAccountId}` — unfollow a creator.
  Future<void> unfollowCreator(String creatorId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/connections/$creatorId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/customer/reels/{reelId}/comments`
  Future<void> commentOnReel(
    String reelId,
    String text,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/customer/reels/$reelId/comments',
      data: {'text': text},
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/reels/{reelId}/views` — share/view tracking.
  Future<void> shareReel(String reelId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/reels/$reelId/views',
      options: _idempotent(idempotencyKey),
    );
  }

  /// Builds request options carrying the caller-supplied Idempotency-Key.
  /// `requiresToken: true` keeps the auth interceptor behaviour from
  /// [ApiClient.post]/[ApiClient.authDelete].
  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
