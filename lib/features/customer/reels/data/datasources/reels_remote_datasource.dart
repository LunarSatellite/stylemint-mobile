import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/models/reel_like_response_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Remote datasource for the reels feature.
/// Talks to the backend reels endpoints via [ApiClient]; throws on failure
/// (exceptions are mapped to a Failure in the repository layer).
class ReelsRemoteDataSource {
  ReelsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/api/v1/customer/feed` — the customer "For You" reel feed
  /// (Discovery). Returns `{ items: [{ kind, reel: {...}, ... }], nextCursor }`;
  /// we keep the reel-bearing items and map each card to a [Reel].
  /// `nextCursor` is surfaced so the feed screen can page in more reels as the
  /// user nears the end instead of dead-ending at [limit].
  Future<ReelsFeedPage> getReelsFeed({
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
    final reels = items
        .whereType<Map<String, dynamic>>()
        .map((e) => e['reel'])
        .whereType<Map<String, dynamic>>()
        .map(_cardJsonToReel)
        .toList(growable: false);
    return ReelsFeedPage(reels: reels, nextCursor: data['nextCursor'] as String?);
  }

  /// Builds a [Reel] domain entity directly from a Discovery feed card.
  Reel _cardJsonToReel(Map<String, dynamic> r) {
    final taggedProducts = (r['taggedProducts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (p) => TaggedProductEntity(
            id: (p['productId'] as String?) ?? '',
            taggedProductId: p['taggedProductId'] as String?,
            name: (p['name'] as String?) ?? '',
            imageUrl: absoluteMediaUrl(p['imageUrl'] as String?),
            price: Money(
              amount: (p['priceAmount'] as num?)?.toDouble() ?? 0,
              currency: (p['priceCurrency'] as String?) ?? 'NPR',
            ),
            quantity: 1,
          ),
        )
        .toList(growable: false);

    final platform =
        SocialPlatform.tryParseWire(r['sourcePlatform']) ??
        SocialPlatform.instagram;
    final externalId = r['externalId'] as String?;

    return Reel(
      id: (r['reelId'] as String?) ?? '',
      externalId: (externalId == null || externalId.isEmpty) ? null : externalId,
      sourceUrl: (r['externalUrl'] as String?) ?? '',
      thumbnailUrl: (r['thumbnailUrl'] as String?) ?? '',
      videoUrl: r['videoUrl'] as String?,
      creatorId: (r['creatorProfileId'] as String?) ?? '',
      creatorName: (r['creatorHandle'] as String?) ?? '',
      creatorAvatarUrl: (r['creatorAvatarUrl'] as String?) ?? '',
      creatorAvatarUrls: _stringList(r['creatorAvatarUrls']),
      caption: (r['caption'] as String?) ?? '',
      createdAt: DateTime.now(),
      platform: platform,
      musicTitle: (r['audioTrackName'] as String?) ?? '',
      musicArtist: (r['audioArtistName'] as String?) ?? '',
      taggedProducts: taggedProducts,
      likeCount: _int(r['likeCount']),
      commentCount: _int(r['commentCount']),
      shareCount: _int(r['shareCount']),
      isLikedByMe: _bool(r['isLikedByMe']),
      isCreatorFollowed: _bool(r['isCreatorFollowed']),
    );
  }

  /// GET `/v1/public/reels/{id}` — single reel detail (backend `ReelDto`).
  ///
  /// Read tolerantly: the detail projection names fields differently from the
  /// feed card (`id`/`sourceUrl`/`thumbnailCdnUrl`/`likesSnapshot` vs.
  /// `reelId`/`externalUrl`/`thumbnailUrl`/`likeCount`), so both spellings are
  /// accepted and the card's wins where both exist.
  Future<Reel> getReelDetail(String reelId) async {
    final response = await apiClient.get('/v1/public/reels/$reelId');
    return _detailJsonToReel(response as Map<String, dynamic>, reelId);
  }

  /// GET `/v1/public/reels/{id}/related` — reels to keep watching after a
  /// shared reel: the creator's other reels, then reels sharing a tagged
  /// product, then the latest reels (backend `PagedResult<ReelDto>`). Items
  /// use the detail projection, so they map like [getReelDetail].
  Future<ReelsFeedPage> getRelatedReels(
    String reelId, {
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/reels/$reelId/related',
      queryParameters: {
        'pageSize': limit,
        'cursor': ?cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    final reels = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((r) => _detailJsonToReel(r, ''))
        .where((reel) => reel.id.isNotEmpty)
        .toList(growable: false);
    return ReelsFeedPage(
      reels: reels,
      nextCursor: data['nextCursor'] as String?,
    );
  }

  Reel _detailJsonToReel(Map<String, dynamic> r, String requestedId) {
    String str(List<String> keys) {
      for (final key in keys) {
        final value = r[key];
        if (value is String && value.isNotEmpty) return value;
      }
      return '';
    }

    final taggedProducts = (r['taggedProducts'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((p) {
          final amount = p['priceAmount'] ?? p['productPriceSnapshotAmount'];
          final currency =
              p['priceCurrency'] ?? p['productPriceSnapshotCurrency'];
          final tagId = p['taggedProductId'] ?? p['id'];
          return TaggedProductEntity(
            id: (p['productId'] as String?) ?? '',
            taggedProductId: tagId is String ? tagId : null,
            name: (p['name'] ?? p['productName']) as String? ?? '',
            imageUrl: absoluteMediaUrl(
              (p['imageUrl'] ?? p['productPrimaryImageUrl']) as String?,
            ),
            price: Money(
              amount: amount is num ? amount.toDouble() : 0,
              currency: currency is String ? currency : 'NPR',
            ),
            quantity: 1,
          );
        })
        .toList(growable: false);

    final id = str(['reelId', 'id']);
    final externalId = str(['externalId']);
    final videoUrl = str(['videoUrl', 'videoCdnUrl']);
    final avatarUrls = _stringList(r['creatorAvatarUrls']);
    return Reel(
      id: id.isEmpty ? requestedId : id,
      externalId: externalId.isEmpty ? null : externalId,
      sourceUrl: str(['externalUrl', 'sourceUrl']),
      thumbnailUrl: str(['thumbnailUrl', 'thumbnailCdnUrl']),
      videoUrl: videoUrl.isEmpty ? null : videoUrl,
      creatorId: str([
        'creatorProfileId',
        'creatorId',
        'creatorAccountId',
        'accountId',
      ]),
      creatorName: str(['creatorHandle', 'creatorDisplayName', 'handle']),
      creatorAvatarUrl: str(['creatorAvatarUrl', 'avatarUrl']),
      creatorAvatarUrls: avatarUrls,
      caption: str(['caption']),
      createdAt:
          DateTime.tryParse(str(['publishedAtUtc', 'createdAtUtc'])) ??
          DateTime.now(),
      platform:
          SocialPlatform.tryParseWire(r['sourcePlatform']) ??
          SocialPlatform.instagram,
      musicTitle: str(['audioTrackName', 'musicTrackTitle']),
      musicArtist: str(['audioArtistName', 'musicArtistName']),
      taggedProducts: taggedProducts,
      likeCount: _int(r['likeCount'] ?? r['likesSnapshot']),
      commentCount: _int(r['commentCount'] ?? r['commentsSnapshot']),
      shareCount: _int(r['shareCount'] ?? r['sharesSnapshot']),
      isLikedByMe: _bool(r['isLikedByMe']),
      isCreatorFollowed: _bool(r['isCreatorFollowed']),
    );
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static bool? _bool(Object? value) => value is bool ? value : null;

  static List<String> _stringList(Object? value) =>
      (value is List ? value : const <Object?>[])
          .whereType<String>()
          .where((url) => url.isNotEmpty)
          .toList(growable: false);

  /// POST `/v1/customer/reels/{reelId}/like` — the viewer likes the reel on
  /// StyleMint. Idempotent server-side; answers
  /// `{ reelId, liked, likeCount }`.
  Future<ReelLikeResult> likeReel(String reelId, String idempotencyKey) async {
    final response = await apiClient.post(
      '/v1/customer/reels/$reelId/like',
      options: _idempotent(idempotencyKey),
    );
    return ReelLikeResponseDto.fromJson(
      response,
      requestedLiked: true,
    ).toDomain();
  }

  /// DELETE `/v1/customer/reels/{reelId}/like` — removes the viewer's
  /// StyleMint like. Repeated unlikes are a no-op server-side.
  Future<ReelLikeResult> unlikeReel(String reelId, String idempotencyKey) async {
    final response = await apiClient.authDelete(
      '/v1/customer/reels/$reelId/like',
      options: _idempotent(idempotencyKey),
    );
    return ReelLikeResponseDto.fromJson(
      response,
      requestedLiked: false,
    ).toDomain();
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

  /// POST `/v1/follows/{accountId}` — one-way creator follow.
  ///
  /// The feed's legacy `creatorProfileId` field is populated with the
  /// creator account id by the Discovery bridge. It must not be sent to the
  /// Networking connection-request API: friendships are mutual and are a
  /// separate feature from following a creator.
  Future<void> followCreator(String creatorId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/follows/$creatorId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE `/v1/follows/{accountId}` — one-way creator unfollow.
  Future<void> unfollowCreator(String creatorId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/follows/$creatorId',
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
