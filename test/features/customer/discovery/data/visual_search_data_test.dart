import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/image_recognition_outcome.dart';

class _PostApiClient extends ApiClient {
  _PostApiClient(this.body) : super(dio: Dio());
  final Object? body;
  String? uri;
  Object? posted;

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    posted = data;
    return body;
  }
}

class _CapabilityApiClient extends ApiClient {
  _CapabilityApiClient(this.body) : super(dio: Dio());
  final Object? body;
  String? uri;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    this.uri = uri;
    return body;
  }
}

void main() {
  test('visual capability is true only for explicit server true', () async {
    final enabled = _CapabilityApiClient({'available': true});
    final disabled = _CapabilityApiClient({'available': false});

    expect(
      await CustomerSearchRemoteDataSource(
        apiClient: enabled,
      ).isVisualSearchAvailable(),
      isTrue,
    );
    expect(enabled.uri, '/api/v1/customer/search/image/capability');
    expect(
      await CustomerSearchRemoteDataSource(
        apiClient: disabled,
      ).isVisualSearchAvailable(),
      isFalse,
    );
  });
  test('visual search posts image data and maps full product DTO', () async {
    final api = _PostApiClient({
      'outcome': 0,
      'recognizedFeatures': ['navy', 'oxford shirt'],
      'products': [
        {
          'id': 'product-1',
          'name': 'Navy Oxford Shirt',
          'averageRating': 4.7,
          'images': [
            {'cdnUrl': 'https://cdn.test/secondary.jpg', 'isPrimary': false},
            {'cdnUrl': 'https://cdn.test/hero.jpg', 'isPrimary': true},
          ],
          'variants': [
            {'priceAmount': 2100, 'priceCurrency': 'NPR', 'isDefault': false},
            {'priceAmount': 2400, 'priceCurrency': 'NPR', 'isDefault': true},
          ],
        },
      ],
    });

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/jpeg;base64,YQ==', limit: 12);

    expect(api.uri, '/api/v1/customer/search/image');
    expect(api.posted, {
      'imageUrl': 'data:image/jpeg;base64,YQ==',
      'limit': 12,
    });
    expect(results.totalHits, 1);
    expect(results.products.single.productId, 'product-1');
    expect(results.products.single.heroImageUrl, 'https://cdn.test/hero.jpg');
    expect(results.products.single.price, 2400);
    expect(results.products.single.currency, 'NPR');
    expect(results.products.single.matchReason, 'Visually similar');
    expect(results.imageRecognition, ImageRecognitionOutcome.matched);
    expect(results.recognizedFeatures, ['navy', 'oxford shirt']);
  });

  test('video frame search merges duplicate products across frames', () async {
    final api = _PostApiClient([
      {'id': 'product-video', 'name': 'Recognized jacket'},
    ]);

    final results =
        await CustomerSearchRemoteDataSource(
          apiClient: api,
        ).searchByImages([
          'data:image/jpeg;base64,YQ==',
          'data:image/jpeg;base64,Yg==',
          'data:image/jpeg;base64,Yw==',
        ]);

    expect(api.uri, '/api/v1/customer/search/multimodal');
    expect(api.posted, {
      'imageUrls': [
        'data:image/jpeg;base64,YQ==',
        'data:image/jpeg;base64,Yg==',
        'data:image/jpeg;base64,Yw==',
      ],
      'limit': 20,
    });
    expect(results.products, hasLength(1));
    expect(results.products.single.productId, 'product-video');
    expect(results.queryUnderstanding, 'Products recognized across your video');
  });
  test('visual search safely maps empty variants and images', () async {
    final api = _PostApiClient({
      'outcome': 0,
      'products': [
        {'id': 'product-2', 'name': 'Unknown item'},
      ],
    });

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/png;base64,Yg==');

    expect(results.products.single.price, 0);
    expect(results.products.single.heroImageUrl, isEmpty);
    expect(results.products.single.currency, 'NPR');
  });

  // ── The three outcomes ────────────────────────────────────────────────────
  //
  // The endpoint used to return a bare array, and on a recognised-but-unstocked
  // image it filled that array with top-rated products by category. These
  // tests exist to keep the three endings apart and to keep products out of
  // the two that are not matches.

  test('RecognizedNoMatch carries the features and never products', () async {
    final api = _PostApiClient({
      'outcome': 2,
      'recognizedFeatures': ['leather satchel', 'tan'],
      // A server regression that leaked products must still not reach a
      // customer as a recognition. The client drops them.
      'products': [
        {'id': 'leaked', 'name': 'Top rated bag'},
      ],
    });

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/png;base64,Yg==');

    expect(results.imageRecognition, ImageRecognitionOutcome.recognizedNoMatch);
    expect(results.products, isEmpty);
    expect(results.recognizedFeatures, ['leather satchel', 'tan']);
    // Nothing was recognised into a match, so no phrase claims it was.
    expect(results.queryUnderstanding, isNull);
  });

  test('NotRecognized reports no products and no features', () async {
    final api = _PostApiClient({'outcome': 1, 'products': <dynamic>[]});

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/png;base64,Yg==');

    expect(results.imageRecognition, ImageRecognitionOutcome.notRecognized);
    expect(results.products, isEmpty);
    expect(results.recognizedFeatures, isEmpty);
    expect(results.queryUnderstanding, isNull);
  });

  test('outcome is read from the enum name as well as the ordinal', () async {
    // The server emits the ordinal today. It would emit names the moment a
    // JsonStringEnumConverter is added, and that must not break the client.
    for (final wire in ['RecognizedNoMatch', 'recognizednomatch']) {
      final results = await CustomerSearchRemoteDataSource(
        apiClient: _PostApiClient({'outcome': wire}),
      ).searchByImage('data:image/png;base64,Yg==');
      expect(
        results.imageRecognition,
        ImageRecognitionOutcome.recognizedNoMatch,
        reason: 'wire value $wire',
      );
    }
  });

  test('an unknown future outcome degrades without claiming a match', () async {
    final api = _PostApiClient({'outcome': 99, 'products': <dynamic>[]});

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/png;base64,Yg==');

    expect(results.imageRecognition, ImageRecognitionOutcome.unknown);
    expect(results.imageRecognition!.isRecognisedMatch, isFalse);
    expect(results.products, isEmpty);
  });

  test('the deleted bare-array contract yields no products', () async {
    // A bare array can only be the old shape, whose empty-match case was the
    // fabrication this change removed. It is not re-admitted here, and it
    // does not throw either — the cast used to crash on the new object.
    final api = _PostApiClient([
      {'id': 'legacy', 'name': 'Top rated in category'},
    ]);

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchByImage('data:image/png;base64,Yg==');

    expect(results.products, isEmpty);
    expect(results.imageRecognition, ImageRecognitionOutcome.unknown);
  });

  test('multimodal reports the image arm without dropping text hits', () async {
    final api = _PostApiClient({
      'imageRecognition': 1,
      'queryUnderstanding': 'Matched on your words',
      'products': [
        {'id': 'from-text', 'name': 'Found by typing'},
      ],
    });

    final results = await CustomerSearchRemoteDataSource(
      apiClient: api,
    ).searchMultimodal(['data:image/png;base64,Yg=='], query: 'red shoes');

    // The rows are real catalogue hits from the text arm and are kept, but
    // the outcome says plainly that the image recognised nothing.
    expect(results.products, hasLength(1));
    expect(results.imageRecognition, ImageRecognitionOutcome.notRecognized);
    expect(results.queryUnderstanding, 'Matched on your words');
  });

  test(
    'multimodal never says "recognized from your photo" unmatched',
    () async {
      final api = _PostApiClient({
        'imageRecognition': 2,
        'products': <dynamic>[],
      });

      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
      ).searchMultimodal(['data:image/png;base64,Yg==']);

      expect(results.queryUnderstanding, isNull);
    },
  );
}
