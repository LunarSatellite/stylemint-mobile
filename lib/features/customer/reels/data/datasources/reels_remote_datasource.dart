import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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
  Future<List<Reel>> getReelsFeed({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/api/v1/customer/feed',
      queryParameters: {
        'limit': limit,
        'cursor': ?cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => e['reel'])
        .whereType<Map<String, dynamic>>()
        .map(_cardJsonToReel)
        .toList(growable: false);
  }

  /// Builds a [Reel] domain entity directly from a Discovery feed card.
  /// Bypasses [ReelDto] because the DTO doesn't carry `platform` (which we
  /// need for the player to pick Instagram vs. YouTube vs. TikTok). The
  /// detail endpoint (`getReelDetail`) still uses `ReelDto.fromJson` because
  /// the player falls back to Instagram-only rendering when platform is null.
  Reel _cardJsonToReel(Map<String, dynamic> r) {
    final taggedProducts = (r['taggedProducts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((p) => TaggedProductEntity(
              id: (p['productId'] as String?) ?? '',
              name: (p['name'] as String?) ?? '',
              imageUrl: absoluteMediaUrl(p['imageUrl'] as String?),
              price: Money(
                amount: (p['priceAmount'] as num?)?.toDouble() ?? 0,
                currency: (p['priceCurrency'] as String?) ?? 'NPR',
              ),
              quantity: 1,
            ))
        .toList(growable: false);

    // The Discovery feed sends PascalCase strings ("YouTubeShorts"), not
    // Dart enum names — see SocialPlatform.tryParseWire.
    final platform = SocialPlatform.tryParseWire(r['sourcePlatform']) ??
        SocialPlatform.instagram;

    return Reel(
      id: (r['reelId'] as String?) ?? '',
      sourceUrl: (r['externalUrl'] as String?) ?? '',
      thumbnailUrl: (r['thumbnailUrl'] as String?) ?? '',
      videoUrl: r['videoUrl'] as String?,
      creatorId: (r['creatorProfileId'] as String?) ?? '',
      creatorName: (r['creatorHandle'] as String?) ?? '',
      creatorAvatarUrl: (r['creatorAvatarUrl'] as String?) ?? '',
      caption: (r['caption'] as String?) ?? '',
      createdAt: DateTime.now(),
      platform: platform,
      musicTitle: (r['audioTrackName'] as String?) ?? '',
      musicArtist: (r['audioArtistName'] as String?) ?? '',
      taggedProducts: taggedProducts,
      likeCount: (r['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (r['commentCount'] as num?)?.toInt() ?? 0,
      shareCount: (r['shareCount'] as num?)?.toInt() ?? 0,
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
