import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/datasources/stories_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response) : super(dio: Dio());

  final dynamic response;
  String? getUri;
  Map<String, dynamic>? queryParameters;
  final List<({String uri, dynamic data, Options? options})> posts = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    this.queryParameters = queryParameters;
    return response;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    posts.add((uri: uri, data: data, options: options));
    if (uri == '/v1/customer/me/avatar') {
      return {'url': 'https://cdn.example.test/story.jpg'};
    }
    // The backend answers the create with an un-hydrated StoryDto.
    return {
      'id': 'story-9',
      'authorAccountId': 'me',
      'authorDisplayName': null,
      'authorAvatarUrl': null,
      'mediaType': 1,
      'mediaUrl': (data as Map<String, dynamic>)['mediaUrl'],
      'caption': data['caption'],
      'postedUtc': '2026-10-07T10:00:00+00:00',
      'expiresUtc': '2026-10-08T10:00:00+00:00',
      'viewCount': 0,
      'hasWatched': true,
    };
  }
}

void main() {
  test('groups the canonical cursor-paged story response by author', () async {
    final api = _FakeApiClient({
      'items': [
        {
          'id': 'story-2',
          'authorAccountId': 'author-1',
          'mediaType': 2,
          'mediaUrl': 'https://example.test/story.mp4',
          'expiresUtc': '2026-09-12T01:00:00Z',
          'viewCount': 2,
          'hasWatched': true,
        },
        {
          'id': 'story-1',
          'authorAccountId': 'author-1',
          'mediaType': 1,
          'mediaUrl': 'https://example.test/story.jpg',
          'expiresUtc': '2026-09-12T00:00:00Z',
          'viewCount': 4,
          'hasWatched': false,
        },
      ],
      'totalCount': 2,
      'nextCursor': null,
      'pageSize': 100,
    });
    final datasource = StoriesRemoteDataSource(apiClient: api);

    final groups = await datasource.getStoryGroups();

    expect(api.getUri, '/v1/stories');
    expect(api.queryParameters, const {'pageSize': 100});
    expect(groups, hasLength(1));
    expect(groups.single.userId, 'author-1');
    expect(groups.single.userName, 'StyleMint user');
    expect(groups.single.hasUnwatched, isTrue);
    expect(groups.single.stories, hasLength(2));
    // The page is newest first; a person's stories play oldest first.
    expect(groups.single.stories.first.id, 'story-1');
    expect(groups.single.stories.first.mediaType, 'image');
    expect(groups.single.stories.last.mediaType, 'video');
  });

  group('createStory', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('stories_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('stages the photo, then creates the story from its URL', () async {
      final photo = File('${dir.path}/picked.jpg')
        ..writeAsBytesSync(List<int>.filled(64, 1));
      final api = _FakeApiClient(null);
      final datasource = StoriesRemoteDataSource(apiClient: api);

      final story = await datasource.createStory(
        mediaFile: photo.path,
        caption: '  Hello  ',
        idempotencyKey: 'key-1',
      );

      expect(api.posts.map((p) => p.uri), [
        '/v1/customer/me/avatar',
        '/v1/stories',
      ]);
      final upload = api.posts.first.data as FormData;
      expect(upload.files.single.key, 'file');
      expect(
        upload.files.single.value.contentType?.mimeType,
        'image/jpeg',
      );
      expect(api.posts.last.data, {
        'mediaType': 1,
        'mediaUrl': 'https://cdn.example.test/story.jpg',
        'caption': 'Hello',
      });
      expect(api.posts.last.options?.headers?['Idempotency-Key'], 'key-1');
      expect(story.id, 'story-9');
      expect(story.userId, 'me');
      expect(story.mediaUrl, 'https://cdn.example.test/story.jpg');
    });

    test('a video is refused before anything is sent', () async {
      final api = _FakeApiClient(null);
      final datasource = StoriesRemoteDataSource(apiClient: api);

      await expectLater(
        datasource.createStory(
          mediaFile: '${dir.path}/clip.mp4',
          idempotencyKey: 'key-2',
        ),
        throwsA(isA<NetworkExceptions>()),
      );
      expect(api.posts, isEmpty);
    });

    test('a photo that has gone from the device is refused', () async {
      final api = _FakeApiClient(null);
      final datasource = StoriesRemoteDataSource(apiClient: api);

      await expectLater(
        datasource.createStory(
          mediaFile: '${dir.path}/missing.jpg',
          idempotencyKey: 'key-3',
        ),
        throwsA(isA<NetworkExceptions>()),
      );
      expect(api.posts, isEmpty);
    });
  });
}
