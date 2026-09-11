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
    if (uri.endsWith('/recipes')) {
      return {
        'fromTheBrand': [
          {
            'recipeId': 'brand-recipe',
            'recipeVersion': 3,
            'title': 'Brand launch sequence',
            'songTitle': 'Launch Beat',
            'songArtist': 'QA Artist',
            'intendedDurationSeconds': 45,
            'thumbnailUrl': null,
            'fromBrand': true,
          },
        ],
        'generic': [
          {
            'recipeId': 'generic-recipe',
            'recipeVersion': 1,
            'title': 'Three-scene try-on',
            'songTitle': 'Everyday Edit',
            'songArtist': 'QA Artist',
            'intendedDurationSeconds': 30,
            'thumbnailUrl': 'https://example.com/recipe.jpg',
            'fromBrand': false,
          },
        ],
      };
    }
    return {
      'journey': {
        'currentPhase': 'Growing',
        'totalReelsPublished': 12,
        'totalRevenue': 3450.5,
        'totalFollowers': 900,
        'totalPartnerships': 2,
        'nextMilestoneProgress': {'reels_25': 48.0},
      },
      'milestones': [
        {
          'key': 'reels_25',
          'name': 'Publish 25 reels',
          'description': 'Keep building your catalog.',
          'completionPercent': 48.0,
          'isCompleted': false,
        },
      ],
      'lessons': [
        {
          'id': 'lesson-id',
          'title': 'Make a stronger hook',
          'category': 'Production',
          'content': 'Start with the result.',
          'readingTimeMinutes': 4,
          'difficultyLevel': 1,
          'unlockPhase': 'Growing',
        },
      ],
      'forecast': {
        'projectedMonthlyEarnings': 5000,
        'projectedMonthLabel': 'October 2026',
        'growthRatePercent': 12.5,
        'projectedReels': 8,
        'projectedFollowers': 1100,
        'recommendation': 'Publish twice a week.',
      },
    };
  }

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
        'audioSuggestions': [
          {
            'trackTitle': 'Reference Track',
            'artist': 'QA Artist',
            'externalListenUrl': 'https://example.com/listen',
            'score': 0.91,
            'rationale': 'Matches the reel pace.',
          },
        ],
        'postTimeRecommendations': [
          {
            'suggestedAtUtc': '2026-09-12T10:00:00Z',
            'timeZone': 'Asia/Kathmandu',
            'audienceActivityScore': 0.88,
            'rationale': 'Your audience is most active then.',
          },
        ],
        'predictedAudience': {
          'primaryAgeBucket': '18–24',
          'primaryRegions': ['Kathmandu'],
          'primaryGenderTilt': 'balanced',
          'interestThemes': ['streetwear'],
          'estimatedReachLow': 1000,
          'estimatedReachHigh': 2200,
        },
        'shelfLifePeakHours': 6,
        'shelfLifeTailHours': 48,
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
    expect(feedback.audioSuggestions.single.trackTitle, 'Reference Track');
    expect(
      feedback.audioSuggestions.single.externalListenUrl,
      'https://example.com/listen',
    );
    expect(feedback.captionVariants.single.tone, 'hook');
    expect(feedback.postTimeRecommendations.single.timeZone, 'Asia/Kathmandu');
    expect(feedback.predictedAudience.primaryRegions, ['Kathmandu']);
    expect(feedback.shelfLifeTailHours, 48);
  });

  test('recipes parse brand and generic groups in server order', () async {
    final api = _FakeApiClient();

    final recipes = await ReelStudioRemoteDataSource(
      apiClient: api,
    ).getRecipes(limit: 10);

    expect(api.getUri, '/v1/creator/studio/recipes');
    expect(api.getQuery, {'max': 10});
    expect(recipes.map((item) => item.recipeId), [
      'brand-recipe',
      'generic-recipe',
    ]);
    expect(recipes.first.fromBrand, isTrue);
    expect(recipes.last.intendedDurationSeconds, 30);
  });

  test('launchpad parses the nested live backend response', () async {
    final api = _FakeApiClient();

    final launchpad = await ReelStudioRemoteDataSource(
      apiClient: api,
    ).getLaunchpad();

    expect(api.getUri, '/v1/creator/studio/launchpad');
    expect(launchpad.journey.currentPhase, 'Growing');
    expect(launchpad.journey.totalRevenue, 3450.5);
    expect(launchpad.milestones.single.completionPercent, 48);
    expect(launchpad.lessons.single.readingTimeMinutes, 4);
    expect(launchpad.forecast?.projectedMonthlyEarnings, 5000);
  });
}
