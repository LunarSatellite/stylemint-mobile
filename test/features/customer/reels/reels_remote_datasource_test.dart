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

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> authDelete(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    deleteUri = uri;
    return null;
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
    'creatorAvatarUrl': '',
    'caption': 'hi',
    'taggedProducts': <dynamic>[],
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
