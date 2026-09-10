import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/data/datasources/co_watch_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.getResponse, this.postResponse}) : super(dio: Dio());

  final dynamic getResponse;
  final dynamic postResponse;
  String? getUri;
  String? postUri;
  Map<String, dynamic>? getQuery;
  dynamic postData;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    getQuery = queryParameters;
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    return postResponse;
  }
}

Map<String, dynamic> _sessionJson() => {
  'id': 'a4a0f36d-f7f4-4aae-95ef-185a73132f0b',
  'reelId': '5f98c893-ce9a-4a9d-bd3a-07ce74bdad8d',
  'hostAccountId': '89c0dd62-3048-49ce-b30a-d462d0559dde',
  'guestAccountId': null,
  'joinCode': 'JOIN42',
  'state': 1,
  'expiresUtc': '2026-09-11T06:00:00Z',
  'createdUtc': '2026-09-11T05:00:00Z',
  'updatedUtc': '2026-09-11T05:00:00Z',
};

void main() {
  test('parses the cursor-paged Co-Watch session contract', () async {
    final api = _FakeApiClient(
      getResponse: {
        'items': [_sessionJson()],
        'totalCount': 1,
        'nextCursor': null,
        'pageSize': 20,
      },
    );
    final datasource = CoWatchRemoteDataSource(apiClient: api);

    final sessions = await datasource.getActiveSessions();

    expect(api.getUri, '/v1/co-watch');
    expect(api.getQuery, const {'pageSize': 20});
    expect(sessions, hasLength(1));
    expect(
      sessions.single.contentId,
      '5f98c893-ce9a-4a9d-bd3a-07ce74bdad8d',
    );
    expect(sessions.single.status, 'waiting');
    expect(sessions.single.participants, hasLength(1));
    expect(sessions.single.thumbnailUrl, isEmpty);
  });

  test('joins by joinCode and accepts a 204 reaction response', () async {
    final joinApi = _FakeApiClient(postResponse: _sessionJson());
    final datasource = CoWatchRemoteDataSource(apiClient: joinApi);

    await datasource.joinSession('JOIN42', 'join-key');

    expect(joinApi.postUri, '/v1/co-watch/join');
    expect(joinApi.postData, {'joinCode': 'JOIN42'});

    final reactionApi = _FakeApiClient(postResponse: null);
    await CoWatchRemoteDataSource(
      apiClient: reactionApi,
    ).sendReaction('session-id', '🔥', 'reaction-key');

    expect(reactionApi.postUri, '/v1/co-watch/session-id/reactions');
    expect(reactionApi.postData, {'reaction': '🔥'});
  });
}
