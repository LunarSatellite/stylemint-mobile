import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/datasources/feed_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.postResponse, this.getResponse}) : super(dio: Dio());

  final dynamic postResponse;
  final dynamic getResponse;
  String? postUri;
  dynamic postData;
  Options? postOptions;
  String? getUri;
  Map<String, dynamic>? getQuery;

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
    postOptions = options;
    return postResponse;
  }
}

void main() {
  test('creates a status post using the backend contract', () async {
    final api = _FakeApiClient(
      postResponse: <String, dynamic>{
        'id': 'post-id',
        'authorAccountId': 'account-id',
        'body': 'A product find',
        'createdUtc': '2026-09-11T00:00:00Z',
        'reactionCount': 0,
        'commentCount': 0,
        'shareCount': 0,
      },
    );
    final datasource = FeedRemoteDataSource(apiClient: api);

    final post = await datasource.createPost(
      content: 'A product find',
      taggedProductIds: const ['product-id'],
      idempotencyKey: 'idempotency-key',
    );

    expect(api.postUri, '/v1/posts');
    expect(api.postData, <String, dynamic>{
      'type': 1,
      'visibility': 1,
      'body': 'A product find',
      'attachments': <Map<String, dynamic>>[
        <String, dynamic>{
          'kind': 1,
          'referenceId': 'product-id',
          'displayOrder': 0,
        },
      ],
    });
    expect(api.postOptions?.headers?['Idempotency-Key'], 'idempotency-key');
    expect(post.id, 'post-id');
    expect(post.userId, 'account-id');
    expect(post.content, 'A product find');
  });

  test('posts and lists comments using the backend contract', () async {
    final response = <String, dynamic>{
      'id': 'comment-id',
      'authorAccountId': 'account-id',
      'body': 'Useful tip',
      'createdUtc': '2026-09-11T00:00:00Z',
    };
    final postApi = _FakeApiClient(postResponse: response);
    final datasource = FeedRemoteDataSource(apiClient: postApi);

    final comment = await datasource.commentOnPost(
      'post-id',
      'Useful tip',
      'idempotency-key',
    );

    expect(postApi.postUri, '/v1/posts/post-id/comments');
    expect(postApi.postData, <String, dynamic>{'body': 'Useful tip'});
    expect(comment.content, 'Useful tip');

    final getApi = _FakeApiClient(getResponse: <dynamic>[response]);
    final getDatasource = FeedRemoteDataSource(apiClient: getApi);
    final page = await getDatasource.getComments('post-id', limit: 20);

    expect(getApi.getUri, '/v1/posts/post-id/comments');
    expect(getApi.getQuery, <String, dynamic>{'take': 20});
    expect(page['items'], hasLength(1));
    expect(page['hasMore'], isFalse);
  });
}
