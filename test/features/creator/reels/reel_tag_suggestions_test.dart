import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/reel_tag_suggestions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/repositories/reel_tag_suggestions_repository.dart';

// Shape of backend ReelTagSuggestionDetectionDto / ReelTagSuggestionCandidateDto
// (lead360 feat/ml-suggestions-api), serialized camelCase.
final _payload = [
  {
    'mediaIndex': 0,
    'frameIndex': 12,
    'frameTimeSeconds': 2.5,
    'label': 'dress',
    'detectorConfidence': 0.91,
    'boxX': 0.1,
    'boxY': 0.2,
    'boxWidth': 0.3,
    'boxHeight': 0.4,
    'framesSeen': 7,
    'candidates': [
      {
        'suggestionId': 's1',
        'productId': 'p1',
        'rank': 1,
        'similarity': 0.87,
        'embeddingModel': 'clip-vit-b32',
        'productName': 'Red dress',
        'primaryImageUrl': 'https://x/img.jpg',
        'priceAmount': 1200.5,
        'priceCurrency': 'NPR',
        'vendorDisplayName': 'Kathmandu Couture',
      },
      {
        'suggestionId': 's2',
        'productId': 'p2',
        'rank': 2,
        'similarity': 0.61,
        'embeddingModel': 'clip-vit-b32',
        'productName': null,
        'primaryImageUrl': null,
        'priceAmount': null,
        'priceCurrency': null,
        'vendorDisplayName': null,
      },
    ],
  },
];

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.postError}) : super(dio: Dio());

  final DioException? postError;
  final List<String> postUris = [];
  final List<Options?> postOptions = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    expect(uri, '/v1/creator/reels/r1/tag-suggestions');
    return _payload;
  }

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    postUris.add(uri);
    postOptions.add(options);
    if (postError != null) throw postError!;
    return <String, dynamic>{};
  }
}

class _Online extends NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;
}

ReelTagSuggestionsRepository _repo(_FakeApiClient api, List<String> keys) {
  var n = 0;
  return ReelTagSuggestionsRepository(
    remoteDataSource: ReelTagSuggestionsRemoteDataSource(apiClient: api),
    networkInfo: _Online(),
    newIdempotencyKey: () => keys[n++],
  );
}

void main() {
  test('parses detections and candidates, nulls stay null', () async {
    final api = _FakeApiClient();
    final result = await _repo(api, const []).listSuggestions('r1');
    final detections = result.getOrElse((_) => fail('expected data'));
    expect(detections, hasLength(1));
    final d = detections.single;
    expect(d.label, 'dress');
    expect(d.frameIndex, 12);
    expect(d.frameTimeSeconds, 2.5);
    expect(d.boxWidth, 0.3);
    expect(d.framesSeen, 7);
    expect(d.candidates.map((c) => c.suggestionId), ['s1', 's2']);
    final top = d.candidates.first;
    expect(top.productName, 'Red dress');
    expect(top.vendorDisplayName, 'Kathmandu Couture');
    expect(top.priceLabel, 'NPR 1200.50');
    expect(top.similarity, 0.87);
    final bare = d.candidates.last;
    expect(bare.productName, isNull);
    expect(bare.priceAmount, isNull);
    expect(bare.priceLabel, isNull);
  });

  test('accept and dismiss POST with a fresh Idempotency-Key each', () async {
    final api = _FakeApiClient();
    final repo = _repo(api, const ['key-a', 'key-b']);

    expect((await repo.acceptSuggestion('r1', 's1')).isRight(), isTrue);
    expect((await repo.dismissSuggestion('r1', 's2')).isRight(), isTrue);

    expect(api.postUris, [
      '/v1/creator/reels/r1/tag-suggestions/s1/accept',
      '/v1/creator/reels/r1/tag-suggestions/s2/dismiss',
    ]);
    expect(api.postOptions[0]!.headers!['Idempotency-Key'], 'key-a');
    expect(api.postOptions[1]!.headers!['Idempotency-Key'], 'key-b');
    expect(api.postOptions[0]!.headers!['requiresToken'], isTrue);
  });

  test('accept surfaces the server message on refusal', () async {
    final options = RequestOptions(
      path: '/v1/creator/reels/r1/tag-suggestions/s1/accept',
    );
    final api = _FakeApiClient(
      postError: DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 400,
          data: {
            'title': 'Validation error',
            'detail': 'This product is not part of a campaign.',
          },
        ),
      ),
    );
    final result = await _repo(api, const ['k']).acceptSuggestion('r1', 's1');
    final message = result.fold(
      NetworkExceptions.getMessage,
      (_) => fail('expected failure'),
    );
    expect(message, contains('not part of a campaign'));
  });
}
