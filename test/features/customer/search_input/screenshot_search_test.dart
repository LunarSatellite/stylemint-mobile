import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/image_recognition_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_image.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/screenshot_search_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';

import 'search_input_test_support.dart';

/// A datasource that answers with whatever the test wants, and records the
/// request so "exactly one image, exactly once" can be asserted.
class _StubSearchDataSource implements CustomerSearchRemoteDataSource {
  _StubSearchDataSource({this.results, this.error});

  final CustomerSearchResults? results;
  final Object? error;
  final List<List<String>> requests = [];
  final List<String?> queries = [];

  @override
  Future<CustomerSearchResults> searchMultimodal(
    List<String> imageDataUris, {
    String? query,
    int limit = 20,
  }) async {
    requests.add(imageDataUris);
    queries.add(query);
    final failure = error;
    // `NetworkExceptions` is a freezed union rather than an `Exception`
    // subtype, so it is rethrown rather than thrown.
    if (failure != null) Error.throwWithStackTrace(failure, StackTrace.current);
    return results!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Only searchMultimodal is used here.');
}

/// Re-stamps a fixture with an image-recognition outcome, so a test can set
/// up "rows came back, but the image arm recognised nothing".
CustomerSearchResults _withRecognition(
  CustomerSearchResults results,
  ImageRecognitionOutcome outcome, {
  List<String> features = const [],
}) => CustomerSearchResults(
  products: results.products,
  brands: results.brands,
  reels: results.reels,
  creators: results.creators,
  totalHits: results.totalHits,
  queryUnderstanding: results.queryUnderstanding,
  imageRecognition: outcome,
  recognizedFeatures: features,
);

ScreenshotImage _screenshot() => ScreenshotImage(
  bytes: Uint8List.fromList(const [1, 2, 3, 4]),
  width: 12,
  height: 20,
);

void main() {
  group('ScreenshotSearch', () {
    test('an empty catalogue answer is a no-match, never an empty result '
        'screen', () async {
      final source = _StubSearchDataSource(
        results: CustomerSearchResults.empty,
      );
      final outcome = await ScreenshotSearch(
        searchDataSource: source,
      ).run(_screenshot());

      // The whole point. Zero products has exactly one meaning here and it
      // is not "show something anyway".
      expect(outcome, isA<ScreenshotNoMatch>());
    });

    test('RecognizedNoMatch keeps the features the server reported', () async {
      final source = _StubSearchDataSource(
        results: const CustomerSearchResults(
          products: [],
          brands: [],
          reels: [],
          creators: [],
          totalHits: 0,
          imageRecognition: ImageRecognitionOutcome.recognizedNoMatch,
          recognizedFeatures: ['tan', 'leather satchel'],
        ),
      );

      final outcome = await ScreenshotSearch(
        searchDataSource: source,
      ).run(_screenshot());

      expect(outcome, isA<ScreenshotNoMatch>());
      expect(
        (outcome as ScreenshotNoMatch).recognizedFeatures,
        ['tan', 'leather satchel'],
      );
    });

    test('NotRecognized is a different ending from a no-match', () async {
      final source = _StubSearchDataSource(
        results: const CustomerSearchResults(
          products: [],
          brands: [],
          reels: [],
          creators: [],
          totalHits: 0,
          imageRecognition: ImageRecognitionOutcome.notRecognized,
        ),
      );

      final outcome = await ScreenshotSearch(
        searchDataSource: source,
      ).run(_screenshot());

      expect(outcome, isA<ScreenshotNotRecognized>());
      expect(outcome, isNot(isA<ScreenshotNoMatch>()));
    });

    test('a non-match never becomes a results screen, even with rows that '
        'came from the typed words', () async {
      // The multimodal endpoint can return text hits alongside an image arm
      // that recognised nothing. This entry point promises "found in your
      // screenshot", so those rows must not be shown as such.
      final source = _StubSearchDataSource(
        results: _withRecognition(
          fakeResults(['Unrelated text hit']),
          ImageRecognitionOutcome.recognizedNoMatch,
        ),
      );

      final outcome = await ScreenshotSearch(
        searchDataSource: source,
      ).run(_screenshot(), query: 'satchel');

      expect(outcome, isA<ScreenshotNoMatch>());
    });

    test('an unknown future outcome falls back to the safe old rule', () async {
      final matched = _StubSearchDataSource(
        results: _withRecognition(
          fakeResults(['Green tote']),
          ImageRecognitionOutcome.unknown,
        ),
      );
      final empty = _StubSearchDataSource(
        results: const CustomerSearchResults(
          products: [],
          brands: [],
          reels: [],
          creators: [],
          totalHits: 0,
          imageRecognition: ImageRecognitionOutcome.unknown,
        ),
      );

      // Real catalogue rows are still shown; their absence is still a
      // no-match. Nothing is invented and nothing throws.
      expect(
        await ScreenshotSearch(searchDataSource: matched).run(_screenshot()),
        isA<ScreenshotMatches>(),
      );
      expect(
        await ScreenshotSearch(searchDataSource: empty).run(_screenshot()),
        isA<ScreenshotNoMatch>(),
      );
    });

    test('a Matched outcome with no products is still a no-match', () async {
      // The server's type forbids this. If it is ever broken, the client
      // must not render an empty results screen.
      final source = _StubSearchDataSource(
        results: const CustomerSearchResults(
          products: [],
          brands: [],
          reels: [],
          creators: [],
          totalHits: 0,
          imageRecognition: ImageRecognitionOutcome.matched,
        ),
      );

      expect(
        await ScreenshotSearch(searchDataSource: source).run(_screenshot()),
        isA<ScreenshotNoMatch>(),
      );
    });

    test('recognised products come back as matches', () async {
      final source = _StubSearchDataSource(
        results: fakeResults(['Green tote']),
      );
      final outcome = await ScreenshotSearch(
        searchDataSource: source,
      ).run(_screenshot(), query: 'tote');

      expect(outcome, isA<ScreenshotMatches>());
      expect(
        (outcome as ScreenshotMatches).results.products.single.name,
        'Green tote',
      );
      expect(source.queries.single, 'tote');
    });

    test('one image leaves the device, once, as a data URI', () async {
      final source = _StubSearchDataSource(
        results: fakeResults(['Green tote']),
      );
      await ScreenshotSearch(searchDataSource: source).run(_screenshot());

      expect(source.requests, hasLength(1));
      expect(source.requests.single, hasLength(1));
      expect(
        source.requests.single.single,
        startsWith('data:image/png;base64,'),
      );
    });

    test('a failed request is unavailable, and says so in the buyer’s '
        'words', () async {
      for (final failure in [
        const NetworkExceptions.serverUnavailable(),
        const NetworkExceptions.noInternetConnection(),
        const NetworkExceptions.notFound(),
        const NetworkExceptions.auth(),
        const NetworkExceptions.validation(code: 'validation.too_large'),
      ]) {
        final outcome = await ScreenshotSearch(
          searchDataSource: _StubSearchDataSource(error: failure),
        ).run(_screenshot());

        expect(
          outcome,
          isA<ScreenshotSearchUnavailable>(),
          reason: '$failure should not be mistaken for a result',
        );
        final message = (outcome as ScreenshotSearchUnavailable).message;
        expect(message, isNotEmpty);
        // No exception text, no stack, no class names leaking to a buyer.
        expect(message, isNot(contains('Exception')));
        expect(message, isNot(contains('NetworkExceptions')));
      }
    });

    test(
      'an unexpected throw is still unavailable rather than a crash',
      () async {
        final outcome = await ScreenshotSearch(
          searchDataSource: _StubSearchDataSource(error: StateError('boom')),
        ).run(_screenshot());

        expect(outcome, isA<ScreenshotSearchUnavailable>());
      },
    );
  });

  test('ScreenshotMatches cannot be built with nothing in it', () {
    // The type system carries the rule, so a future caller cannot quietly
    // route an empty answer into the results screen.
    expect(
      () => ScreenshotMatches(CustomerSearchResults.empty),
      throwsA(isA<AssertionError>()),
    );
  });

  group('probeVisualSearch', () {
    test(
      'available:true is ready, available:false hides the entry point',
      () async {
        expect(
          await probeVisualSearch(_StubApiClient({'available': true})),
          SearchInputStatus.ready,
        );
        expect(
          await probeVisualSearch(_StubApiClient({'available': false})),
          SearchInputStatus.unsupported,
        );
      },
    );

    test('a probe that cannot complete is not an answer', () async {
      // Offline must not permanently hide a feature the server does have.
      expect(
        await probeVisualSearch(_StubApiClient.throwing()),
        SearchInputStatus.unprobed,
      );
      expect(
        await probeVisualSearch(_StubApiClient('not a map')),
        SearchInputStatus.unprobed,
      );
    });
  });
}

class _StubApiClient implements ApiClient {
  _StubApiClient(this.response) : shouldThrow = false;
  _StubApiClient.throwing() : response = null, shouldThrow = true;

  final Object? response;
  final bool shouldThrow;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (shouldThrow) {
      Error.throwWithStackTrace(
        const NetworkExceptions.noInternetConnection(),
        StackTrace.current,
      );
    }
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Only get is used here.');
}
