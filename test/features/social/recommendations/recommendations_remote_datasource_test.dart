import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/data/datasources/recommendations_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.response}) : super(dio: Dio());

  final dynamic response;
  String? uri;
  dynamic data;
  Map<String, dynamic>? query;
  Options? options;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    query = queryParameters;
    this.options = options;
    return response;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    this.data = data;
    query = queryParameters;
    this.options = options;
    return response;
  }
}

Map<String, dynamic> requestJson() => <String, dynamic>{
  'id': 'request-id',
  'askerAccountId': 'asker-id',
  'title': 'What should I wear?',
  'body': 'Outdoor wedding',
  'openedUtc': '2026-09-11T00:00:00Z',
  'expiresUtc': '2026-10-11T00:00:00Z',
  'replyCount': 2,
};

Map<String, dynamic> replyJson() => <String, dynamic>{
  'id': 'reply-id',
  'requestId': 'request-id',
  'replierAccountId': 'replier-id',
  'body': 'Try a linen suit.',
  'upvoteCount': 3,
  'createdUtc': '2026-09-11T01:00:00Z',
};

void main() {
  test('creates a public request using the backend contract', () async {
    final api = _FakeApiClient(response: requestJson());
    final datasource = RecommendationsRemoteDataSource(apiClient: api);

    final request = await datasource.createRequest(
      question: 'What should I wear?',
      context: 'Outdoor wedding',
      categories: const ['Formal'],
      idempotencyKey: 'idempotency-key',
    );

    expect(api.uri, '/v1/recommendation-requests');
    expect(api.data, <String, dynamic>{
      'title': 'What should I wear?',
      'body': 'Outdoor wedding\n\nTopic: Formal',
      'visibility': 3,
      'urgency': 1,
    });
    expect(api.options?.headers?['Idempotency-Key'], 'idempotency-key');
    expect(request.question, 'What should I wear?');
    expect(request.userId, 'asker-id');
  });

  test('lists requests and replies from backend paged results', () async {
    final requestApi = _FakeApiClient(
      response: <String, dynamic>{
        'items': <dynamic>[requestJson()],
        'totalCount': 1,
        'pageSize': 20,
        'hasNext': false,
      },
    );
    final requestDatasource = RecommendationsRemoteDataSource(
      apiClient: requestApi,
    );

    final requests = await requestDatasource.getRequests(limit: 20);

    expect(requestApi.query, <String, dynamic>{'take': 20, 'skip': 0});
    expect(requests.items.single.question, 'What should I wear?');

    final replyApi = _FakeApiClient(
      response: <String, dynamic>{
        'items': <dynamic>[replyJson()],
        'totalCount': 1,
        'pageSize': 100,
        'hasNext': false,
      },
    );
    final replyDatasource = RecommendationsRemoteDataSource(
      apiClient: replyApi,
    );

    final replies = await replyDatasource.getThread('request-id');

    expect(replyApi.uri, '/v1/recommendation-requests/request-id/replies');
    expect(replyApi.query, <String, dynamic>{'take': 100});
    expect(replies.single.content, 'Try a linen suit.');
    expect(replies.single.likeCount, 3);
  });

  test('creates replies and preserves non-URL product suggestions', () async {
    final api = _FakeApiClient(response: replyJson());
    final datasource = RecommendationsRemoteDataSource(apiClient: api);

    await datasource.replyToRequest(
      requestId: 'request-id',
      content: 'Try this option.',
      suggestedProduct: 'Linen suit',
      idempotencyKey: 'idempotency-key',
    );

    expect(api.uri, '/v1/recommendation-replies');
    expect(api.data, <String, dynamic>{
      'requestId': 'request-id',
      'body': 'Try this option.\n\nSuggested product: Linen suit',
    });
  });

  test('casts an upvote using the required vote type', () async {
    final api = _FakeApiClient();
    final datasource = RecommendationsRemoteDataSource(apiClient: api);

    await datasource.likeReply('reply-id', 'idempotency-key');

    expect(api.uri, '/v1/recommendation-votes');
    expect(api.data, <String, dynamic>{'replyId': 'reply-id', 'type': 1});
  });
}
