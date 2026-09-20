import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/datasources/reel_import_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class _ContentApiClient extends ApiClient {
  _ContentApiClient(this.body) : super(dio: Dio());

  final Object? body;
  String? uri;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    query = queryParameters;
    return body;
  }
}

Map<String, dynamic> _item(String id, {int duration = 15}) => {
  'externalId': id,
  'permalink': 'https://www.instagram.com/reel/$id/',
  'caption': 'caption $id',
  'thumbnailUrl': 'https://cdn.example/$id.jpg',
  'videoUrl': null,
  'mediaType': 'VIDEO',
  'publishedUtc': '2026-09-10T08:00:00Z',
  'durationSeconds': duration,
  'likeCount': 5,
  'viewCount': 50,
  'commentCount': 1,
  'shareCount': 2,
  'bookmarkCount': 3,
};

Future<ImportableReelsPage> _parse(
  Object? body, {
  SocialPlatform platform = SocialPlatform.instagram,
}) => ReelImportRemoteDataSource(
  apiClient: _ContentApiClient(body),
).getImportableReels(platform);

void main() {
  group('content page parsing', () {
    test('old JSON without freshness fields parses as a live page', () async {
      final page = await _parse({
        'items': [_item('a')],
        'nextCursor': 'provider-cursor',
      });

      final reel = page.reels.single;
      expect(reel.platformPostId, 'a');
      expect(reel.sourceUrl, 'https://www.instagram.com/reel/a/');
      expect(reel.videoDuration, 15);
      expect(reel.bookmarkCount, 3);
      expect(page.nextCursor, 'provider-cursor');
      expect(page.servedFromCache, isFalse);
      expect(page.fetchedUtc, isNull);
      expect(page.staleSinceUtc, isNull);
      expect(page.providerStatus, isNull);
      expect(page.toFreshness(), const ContentFreshness());
    });

    test(
      'new JSON carries saved-posts freshness and provider status',
      () async {
        final page = await _parse({
          'items': [_item('a'), _item('b')],
          'nextCursor': 'sm1.eyJwIjoiMjAyNi0wOS0xMCJ9',
          'servedFromCache': true,
          'fetchedUtc': '2026-09-14T15:10:00Z',
          'staleSinceUtc': '2026-09-14T15:25:00Z',
          'providerStatus': {
            'code': 'RATE_LIMITED',
            'message': 'Instagram is limiting requests right now.',
            'retryAfterUtc': '2026-09-14T15:40:00Z',
          },
        });

        expect(page.reels, hasLength(2));
        expect(page.nextCursor, 'sm1.eyJwIjoiMjAyNi0wOS0xMCJ9');

        final freshness = page.toFreshness();
        expect(freshness.servedFromCache, isTrue);
        expect(freshness.fetchedUtc, DateTime.utc(2026, 9, 14, 15, 10));
        expect(freshness.staleSinceUtc, DateTime.utc(2026, 9, 14, 15, 25));
        final status = freshness.providerStatus!;
        expect(status.code, 'RATE_LIMITED');
        expect(status.message, 'Instagram is limiting requests right now.');
        expect(status.retryAfterUtc, DateTime.utc(2026, 9, 14, 15, 40));
        expect(status.issue, ContentProviderIssue.rateLimited);
      },
    );

    test('a reconnect status has no retry time', () async {
      final page = await _parse({
        'items': <dynamic>[],
        'nextCursor': null,
        'servedFromCache': true,
        'fetchedUtc': null,
        'staleSinceUtc': null,
        'providerStatus': {
          'code': 'TOKEN_EXPIRED',
          'message': 'Reconnect your Instagram account.',
          'retryAfterUtc': null,
        },
      });

      expect(page.fetchedUtc, isNull);
      expect(page.providerStatus!.retryAfterUtc, isNull);
      expect(
        page.toFreshness().providerStatus!.issue,
        ContentProviderIssue.reconnect,
      );
    });

    test(
      'malformed freshness fields are ignored instead of throwing',
      () async {
        final page = await _parse({
          'items': [_item('a')],
          'nextCursor': '',
          'servedFromCache': 'yes',
          'fetchedUtc': 'not a date',
          'staleSinceUtc': 42,
          'providerStatus': {'message': 'no code'},
        });

        expect(page.reels, hasLength(1));
        expect(page.nextCursor, isNull);
        expect(page.servedFromCache, isFalse);
        expect(page.fetchedUtc, isNull);
        expect(page.staleSinceUtc, isNull);
        expect(page.providerStatus, isNull);
      },
    );

    test('a non-object providerStatus is ignored', () async {
      final page = await _parse({
        'items': <dynamic>[],
        'providerStatus': 'RATE_LIMITED',
      });

      expect(page.providerStatus, isNull);
    });
  });

  group('content request', () {
    test('first page sends only the limit', () async {
      final api = _ContentApiClient({'items': <dynamic>[]});

      await ReelImportRemoteDataSource(
        apiClient: api,
      ).getImportableReels(SocialPlatform.tiktok);

      expect(api.uri, '/v1/social/accounts/tiktok/content');
      expect(api.query, {'limit': 25});
    });

    test('passes a saved-posts cursor through and asks for refresh', () async {
      final api = _ContentApiClient({'items': <dynamic>[]});

      await ReelImportRemoteDataSource(apiClient: api).getImportableReels(
        SocialPlatform.youtube,
        cursor: 'sm1.abc',
        refresh: true,
      );

      expect(api.uri, '/v1/social/accounts/youtube/content');
      expect(api.query, {'limit': 25, 'cursor': 'sm1.abc', 'refresh': true});
    });
  });
}
