import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/datasources/stories_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response) : super(dio: Dio());

  final dynamic response;
  String? getUri;
  Map<String, dynamic>? queryParameters;

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
}

void main() {
  test('groups the canonical cursor-paged story response by author', () async {
    final api = _FakeApiClient({
      'items': [
        {
          'id': 'story-1',
          'authorAccountId': 'author-1',
          'mediaType': 1,
          'mediaUrl': 'https://example.test/story.jpg',
          'expiresUtc': '2026-09-12T00:00:00Z',
          'viewCount': 4,
          'hasWatched': false,
        },
        {
          'id': 'story-2',
          'authorAccountId': 'author-1',
          'mediaType': 2,
          'mediaUrl': 'https://example.test/story.mp4',
          'expiresUtc': '2026-09-12T01:00:00Z',
          'viewCount': 2,
          'hasWatched': true,
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
    expect(groups.single.stories.first.mediaType, 'image');
    expect(groups.single.stories.last.mediaType, 'video');
  });
}
