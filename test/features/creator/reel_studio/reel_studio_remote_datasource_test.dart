import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/datasources/reel_studio_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  String? putUri;
  dynamic putData;
  Options? putOptions;

  @override
  Future<dynamic> put(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    putUri = uri;
    putData = data;
    putOptions = options;
    return {
      'id': 'draft-id',
      'caption': 'Updated caption',
      'hashtags': <String>[],
      'taggedProductIds': <String>[],
      'platform': 'tiktok',
      'status': 'draft',
      'createdAt': '2026-09-11T00:00:00Z',
    };
  }
}

void main() {
  test('draft update sends the selected platform', () async {
    final api = _FakeApiClient();

    final draft = await ReelStudioRemoteDataSource(apiClient: api).updateDraft(
      draftId: 'draft-id',
      caption: 'Updated caption',
      hashtags: const [],
      taggedProductIds: const [],
      platform: 'tiktok',
      idempotencyKey: 'update-key',
    );

    expect(api.putUri, '/v1/creator/studio/drafts/draft-id');
    expect(api.putData, {
      'caption': 'Updated caption',
      'hashtags': <String>[],
      'taggedProductIds': <String>[],
      'platform': 'tiktok',
    });
    expect(api.putOptions?.headers?['Idempotency-Key'], 'update-key');
    expect(draft.platform, 'tiktok');
  });
}
