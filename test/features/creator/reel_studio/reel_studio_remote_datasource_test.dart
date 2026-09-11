import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/datasources/reel_studio_remote_datasource.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  String? putUri;
  dynamic putData;
  Options? putOptions;
  String? postUri;
  dynamic postData;

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

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUri = uri;
    postData = data;
    return {
      'hookScore': 0.8,
      'body': {
        'captionVariants': [
          {
            'text': 'Lead with the result.',
            'engagementScoreEstimate': 0.7,
            'tone': 'hook',
          },
        ],
        'hashtagsReach': ['#style'],
        'hashtagsNiche': ['#nepalstyle'],
      },
      'explanationByKey': {'hook': 'The opening is immediately clear.'},
      'computedUtc': '2026-09-11T00:00:00Z',
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
  test('coaching request parses the briefing response', () async {
    final api = _FakeApiClient();

    final briefing = await ReelStudioRemoteDataSource(
      apiClient: api,
    ).requestCoaching('draft-id', 'analyze-key');
    final feedback = briefing.toDomain();

    expect(api.postUri, '/v1/creator/studio/analyze');
    expect(api.postData, {'reelDraftId': 'draft-id'});
    expect(feedback.overallScore, 0.8);
    expect(feedback.areas.map((area) => area.label), ['Hook', 'Captions']);
    expect(feedback.suggestions, contains('The opening is immediately clear.'));
    expect(feedback.suggestions, contains('Hook: Lead with the result.'));
    expect(
      feedback.suggestions,
      contains('Suggested hashtags: #style #nepalstyle'),
    );
  });
}
