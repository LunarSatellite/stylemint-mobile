import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/services/place_search_service.dart';

/// Cover for the geocoder added for SM-006 (22 Sep TestFlight QA): the
/// shipping form had no way to search for a location at all.
void main() {
  /// A Dio whose every GET answers with [body] / [status], so the parsing can
  /// be exercised without touching the network.
  Dio stubDio(Object? body, {int status = 200}) {
    final dio = Dio(BaseOptions(validateStatus: (_) => true));
    dio.httpClientAdapter = _StubAdapter(body, status);
    return dio;
  }

  Map<String, dynamic> feature({
    required double lon,
    required double lat,
    Map<String, dynamic> properties = const {},
  }) => {
    'geometry': {
      'type': 'Point',
      'coordinates': [lon, lat],
    },
    'properties': properties,
  };

  test('does not call out for a query below the minimum length', () async {
    // A stub that would throw if it were ever asked for anything.
    final service = PhotonPlaceSearchService(dio: stubDio(null, status: 500));
    expect(await service.search('ab'), isEmpty);
  });

  test('reads GeoJSON coordinates as [longitude, latitude]', () async {
    // The single most costly thing to get wrong here: swapping these puts the
    // pin in the wrong hemisphere and nothing visibly fails.
    final service = PhotonPlaceSearchService(
      dio: stubDio({
        'features': [
          feature(lon: 85.3240, lat: 27.7172, properties: {'name': 'Thamel'}),
        ],
      }),
    );

    final results = await service.search('thamel');

    expect(results, hasLength(1));
    expect(results.single.latitude, closeTo(27.7172, 1e-9));
    expect(results.single.longitude, closeTo(85.3240, 1e-9));
    expect(results.single.label, 'Thamel');
  });

  test('builds a street line from house number and street', () async {
    final service = PhotonPlaceSearchService(
      dio: stubDio({
        'features': [
          feature(
            lon: 85.0,
            lat: 27.0,
            properties: {
              'housenumber': '12',
              'street': 'Durbar Marg',
              'city': 'Kathmandu',
              'country': 'Nepal',
            },
          ),
        ],
      }),
    );

    final result = (await service.search('durbar')).single;

    expect(result.label, '12 Durbar Marg');
    expect(result.detail, 'Kathmandu, Nepal');
  });

  test('skips features with no usable point instead of inventing one', () async {
    final service = PhotonPlaceSearchService(
      dio: stubDio({
        'features': [
          {'properties': {'name': 'No geometry'}},
          {
            'geometry': {'coordinates': []},
            'properties': {'name': 'Empty coordinates'},
          },
          feature(lon: 85.0, lat: 27.0, properties: {'name': 'Good one'}),
        ],
      }),
    );

    final results = await service.search('anything');

    expect(results.map((r) => r.label), ['Good one']);
  });

  test('a non-200 raises PlaceSearchException', () async {
    final service = PhotonPlaceSearchService(
      dio: stubDio({'features': []}, status: 503),
    );
    expect(
      () => service.search('kathmandu'),
      throwsA(isA<PlaceSearchException>()),
    );
  });

  test('an unusable body raises PlaceSearchException', () async {
    final service = PhotonPlaceSearchService(dio: stubDio('not json at all'));
    expect(
      () => service.search('kathmandu'),
      throwsA(isA<PlaceSearchException>()),
    );
  });

  test('a body without a features array is simply no matches', () async {
    final service = PhotonPlaceSearchService(dio: stubDio(<String, dynamic>{}));
    expect(await service.search('kathmandu'), isEmpty);
  });
}

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, this.status);

  final Object? body;
  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body is String ? body as String : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
