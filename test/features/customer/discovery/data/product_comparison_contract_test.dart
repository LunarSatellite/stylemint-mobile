import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';

/// `GET /v1/public/products/{id}/compare` used to emit filler — "A popular
/// choice in its category." — for listings the platform knew nothing about.
/// Those sentences are deleted, so the endpoint now answers `204 No Content`
/// when it has nothing grounded to say, and the three text fields are
/// nullable and omitted when absent.
class _GetApiClient extends ApiClient {
  _GetApiClient(this.body) : super(dio: Dio());
  final Object? body;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => body;
}

class _AlwaysOnline implements NetworkInfoConnectivity {
  @override
  Future<bool> get isConnected async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Only isConnected is used here.');
}

DiscoveryRepositoryImpl _repo(Object? body) => DiscoveryRepositoryImpl(
  remoteDataSource: DiscoveryRemoteDataSource(apiClient: _GetApiClient(body)),
  networkInfo: _AlwaysOnline(),
);

void main() {
  group('204 No Content', () {
    // Dio hands back null or an empty string for a bodyless 204 depending on
    // the transformer, so both are exercised. Neither may raise: the old
    // `response as Map<String, dynamic>` threw and landed in a generic catch,
    // which hid the card for the right reason but logged a spurious error.
    for (final body in <Object?>[null, '']) {
      test(
        'an empty body is a success with no comparison (${body.runtimeType})',
        () async {
          final result = await _repo(body).getProductComparison('p1');

          expect(result.isRight(), isTrue, reason: 'a 204 is not an error');
          expect(result.getOrElse((_) => throw StateError('left')), isNull);
        },
      );
    }
  });

  group('nullable fields', () {
    test(
      'all three absent still parses, with nulls not empty strings',
      () async {
        final result = await _repo({
          'alternatives': [
            {'productId': 'p2', 'productName': 'Alternative'},
          ],
        }).getProductComparison('p1');

        final comparison = result.getOrElse((_) => throw StateError('left'))!;
        expect(comparison.bestForTag, isNull);
        expect(comparison.recommendation, isNull);
        expect(comparison.alternatives.single.howItDiffers, isNull);
        // The alternative is still a fact worth showing: only the manufactured
        // sentence is gone.
        expect(comparison.alternatives.single.productName, 'Alternative');
        expect(comparison.hasContent, isTrue);
      },
    );

    test('a blank string is read as absent, never as a value', () async {
      final result = await _repo({
        'bestForTag': '   ',
        'recommendation': '',
        'alternatives': [
          {
            'productId': 'p2',
            'productName': 'Alternative',
            'howItDiffers': ' ',
          },
        ],
      }).getProductComparison('p1');

      final comparison = result.getOrElse((_) => throw StateError('left'))!;
      expect(comparison.bestForTag, isNull);
      expect(comparison.recommendation, isNull);
      expect(comparison.alternatives.single.howItDiffers, isNull);
    });

    test('present values are kept and trimmed', () async {
      final result = await _repo({
        'bestForTag': ' everyday carry ',
        'recommendation': 'Pick the wider one if you cycle.',
        'alternatives': [
          {
            'productId': 'p2',
            'productName': 'Alternative',
            'howItDiffers': 'Holds 4L more.',
          },
        ],
      }).getProductComparison('p1');

      final comparison = result.getOrElse((_) => throw StateError('left'))!;
      expect(comparison.bestForTag, 'everyday carry');
      expect(comparison.recommendation, 'Pick the wider one if you cycle.');
      expect(comparison.alternatives.single.howItDiffers, 'Holds 4L more.');
    });

    test('an entirely empty summary has no content to show', () async {
      final result = await _repo(
        <String, dynamic>{},
      ).getProductComparison('p1');

      final comparison = result.getOrElse((_) => throw StateError('left'))!;
      // Nothing true to say and nothing to list: the card does not appear,
      // and no placeholder stands in for the missing sentences.
      expect(comparison.hasContent, isFalse);
    });
  });
}
