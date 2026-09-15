import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

class _CapturingApiClient extends ApiClient {
  _CapturingApiClient() : super(dio: Dio());

  String? postUri;
  String? deleteUri;
  Object? postData;
  Options? postOptions;
  Options? deleteOptions;
  Object? postResponse = <String, dynamic>{};
  Object? deleteResponse;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    postOptions = options;
    return postResponse;
  }

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    deleteUri = uri;
    deleteOptions = options;
    return deleteResponse;
  }
}

class _FeedApiClient extends ApiClient {
  _FeedApiClient(this.body) : super(dio: Dio());

  final Map<String, dynamic> body;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => body;
}

Map<String, dynamic> _card({
  required String reelId,
  required Object? sourcePlatform,
  String? externalId,
  String externalUrl = '',
  String creatorAvatarUrl = '',
  List<Object?>? creatorAvatarUrls,
  Map<String, Object?> extra = const {},
}) => {
  'kind': 'Reel',
  'reel': {
    'reelId': reelId,
    'sourcePlatform': sourcePlatform,
    'externalId': externalId,
    'externalUrl': externalUrl,
    'thumbnailUrl': '',
    'videoUrl': null,
    'creatorProfileId': 'creator-1',
    'creatorHandle': 'miko',
    'creatorAvatarUrl': creatorAvatarUrl,
    'creatorAvatarUrls': ?creatorAvatarUrls,
    'caption': 'hi',
    'taggedProducts': <dynamic>[],
    ...extra,
  },
};

void main() {
  group('feed card mapping', () {
    Future<List<Reel>> mapCards(List<Map<String, dynamic>> cards) async {
      final datasource = ReelsRemoteDataSource(
        apiClient: _FeedApiClient({'items': cards, 'nextCursor': null}),
      );
      return (await datasource.getReelsFeed(limit: 10)).reels;
    }

    test('parses the PascalCase YouTubeShorts wire value and keeps externalId',
        () async {
      final reels = await mapCards([
        _card(
          reelId: 'r1',
          sourcePlatform: 'YouTubeShorts',
          externalId: '39bix0Z0NOQ',
          externalUrl: 'https://youtube.com/shorts/39bix0Z0NOQ?feature=shared',
        ),
      ]);

      expect(reels.single.platform, SocialPlatform.youtube);
      expect(reels.single.externalId, '39bix0Z0NOQ');
      expect(reels.single.platformVideoId, '39bix0Z0NOQ');
    });

    test('uses externalId as the video id for non-YouTube platforms', () async {
      final reels = await mapCards([
        _card(
          reelId: 'r2',
          sourcePlatform: 'TikTok',
          externalId: '6718335390845095173',
          externalUrl: 'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        ),
      ]);

      expect(reels.single.platform, SocialPlatform.tiktok);
      expect(reels.single.platformVideoId, '6718335390845095173');
    });

    test('falls back to URL parsing when the backend omits externalId',
        () async {
      final reels = await mapCards([
        _card(
          reelId: 'r3',
          sourcePlatform: 3,
          externalId: '',
          externalUrl: 'https://www.youtube.com/watch?v=I1bYtU4F2AQ',
        ),
      ]);

      expect(reels.single.platform, SocialPlatform.youtube);
      expect(reels.single.externalId, isNull);
      expect(reels.single.platformVideoId, 'I1bYtU4F2AQ');
    });

    test('defaults an unrecognised platform to Instagram', () async {
      final reels = await mapCards([
        _card(reelId: 'r4', sourcePlatform: 'Snapchat'),
      ]);

      expect(reels.single.platform, SocialPlatform.instagram);
    });

    test('maps creatorAvatarUrls in order and keeps creatorAvatarUrl',
        () async {
      final reels = await mapCards([
        _card(
          reelId: 'r5',
          sourcePlatform: 'Instagram',
          creatorAvatarUrl: 'https://tt.example/avatar.jpg',
          creatorAvatarUrls: [
            'https://ig.example/avatar.jpg',
            '',
            null,
            'https://tt.example/avatar.jpg',
          ],
        ),
      ]);

      expect(reels.single.creatorAvatarUrl, 'https://tt.example/avatar.jpg');
      expect(reels.single.creatorAvatarUrls, [
        'https://ig.example/avatar.jpg',
        'https://tt.example/avatar.jpg',
      ]);
    });

    test('a card without creatorAvatarUrls maps to an empty list', () async {
      final reels = await mapCards([
        _card(reelId: 'r6', sourcePlatform: 'TikTok'),
      ]);

      expect(reels.single.creatorAvatarUrls, isEmpty);
    });

    test('maps isLikedByMe and the combined likeCount', () async {
      final reels = await mapCards([
        _card(
          reelId: 'r7',
          sourcePlatform: 'TikTok',
          extra: {'isLikedByMe': true, 'likeCount': 129},
        ),
        _card(
          reelId: 'r8',
          sourcePlatform: 'TikTok',
          extra: {'isLikedByMe': null, 'likeCount': 4},
        ),
      ]);

      expect(reels.first.isLikedByMe, isTrue);
      expect(reels.first.likeCount, 129);
      // Guests get null.
      expect(reels.last.isLikedByMe, isNull);
    });
  });

  group('reel detail mapping', () {
    Future<Reel> mapDetail(Map<String, dynamic> body) =>
        ReelsRemoteDataSource(
          apiClient: _FeedApiClient(body),
        ).getReelDetail('requested-id');

    test('reads the public ReelDto shape', () async {
      final reel = await mapDetail({
        'id': 'r9',
        'sourcePlatform': 3,
        'externalId': '39bix0Z0NOQ',
        'sourceUrl': 'https://youtube.com/shorts/39bix0Z0NOQ',
        'thumbnailCdnUrl': 'https://cdn.example/thumb.jpg',
        'caption': 'Three ways to style a tote',
        'likesSnapshot': 12,
        'commentsSnapshot': 3,
        'isLikedByMe': false,
        'creatorHandle': 'miko',
        'taggedProducts': [
          {
            'id': 'tag-1',
            'productId': 'prod-1',
            'productName': 'Tote',
            'productPriceSnapshotAmount': 1800,
            'productPriceSnapshotCurrency': 'NPR',
          },
        ],
      });

      expect(reel.id, 'r9');
      expect(reel.platform, SocialPlatform.youtube);
      expect(reel.platformVideoId, '39bix0Z0NOQ');
      expect(reel.thumbnailUrl, 'https://cdn.example/thumb.jpg');
      expect(reel.likeCount, 12);
      expect(reel.commentCount, 3);
      expect(reel.isLikedByMe, isFalse);
      expect(reel.creatorName, 'miko');
      expect(reel.taggedProducts.single.taggedProductId, 'tag-1');
      expect(reel.taggedProducts.single.price.amount, 1800);
    });

    test('prefers the combined likeCount and falls back to the requested id',
        () async {
      final reel = await mapDetail({
        'sourcePlatform': 'TikTok',
        'likeCount': 20,
        'likesSnapshot': 12,
      });

      expect(reel.id, 'requested-id');
      expect(reel.likeCount, 20);
      expect(reel.isLikedByMe, isNull);
    });
  });

  group('StyleMint reel likes', () {
    test('like and unlike hit the customer like endpoint with an '
        'Idempotency-Key', () async {
      final api = _CapturingApiClient()
        ..postResponse = {'reelId': 'reel-1', 'liked': true, 'likeCount': 129}
        ..deleteResponse = {
          'reelId': 'reel-1',
          'liked': false,
          'likeCount': 128,
        };
      final datasource = ReelsRemoteDataSource(apiClient: api);

      final liked = await datasource.likeReel('reel-1', 'key-1');
      final unliked = await datasource.unlikeReel('reel-1', 'key-2');

      expect(api.postUri, '/v1/customer/reels/reel-1/like');
      expect(api.postData, isNull);
      expect(api.postOptions?.headers?['Idempotency-Key'], 'key-1');
      expect(liked.liked, isTrue);
      expect(liked.likeCount, 129);
      expect(api.deleteUri, '/v1/customer/reels/reel-1/like');
      expect(api.deleteOptions?.headers?['Idempotency-Key'], 'key-2');
      expect(unliked.liked, isFalse);
      expect(unliked.likeCount, 128);
    });

    test('reads like responses tolerantly', () async {
      final api = _CapturingApiClient()
        ..postResponse = null
        ..deleteResponse = {'liked': 'no', 'likeCount': '5'};
      final datasource = ReelsRemoteDataSource(apiClient: api);

      final liked = await datasource.likeReel('reel-1', 'key-1');
      final unliked = await datasource.unlikeReel('reel-1', 'key-2');

      expect(liked.liked, isTrue);
      expect(liked.likeCount, isNull);
      expect(unliked.liked, isFalse);
      expect(unliked.likeCount, isNull);
    });
  });

  test('uses the one-way follow API for reel creators', () async {
    final api = _CapturingApiClient();
    final datasource = ReelsRemoteDataSource(apiClient: api);

    await datasource.followCreator('creator-account', 'key-1');
    await datasource.unfollowCreator('creator-account', 'key-2');

    expect(api.postUri, '/v1/follows/creator-account');
    expect(api.postData, isNull);
    expect(api.deleteUri, '/v1/follows/creator-account');
  });
}
