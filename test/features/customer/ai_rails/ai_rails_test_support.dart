import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';

import '../../../shared/presentation/mall/mall_harness.dart';

/// Answers each GET with the body registered for its path (query ignored),
/// and every other path with a 404 — the "not deployed yet" server.
class RailsApi extends ApiClient {
  RailsApi(this.bodies) : super(dio: Dio());

  final Map<String, Object?> bodies;
  final List<String> gets = [];

  static DioException notFound(String path) {
    final request = RequestOptions(path: path);
    return DioException(
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 404),
    );
  }

  Future<dynamic> _answer(String uri) async {
    gets.add(uri);
    if (!bodies.containsKey(uri)) throw notFound(uri);
    return bodies[uri];
  }

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _answer(uri);

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) => _answer(uri);

  @override
  Future<dynamic> post(
    String uri, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async => throw notFound(uri);
}

/// A public `ProductDto` card as `/related` and the §3 rails return it.
Map<String, dynamic> productCard(String id, String name) => {
  'id': id,
  'name': name,
  'images': const <dynamic>[],
  'variants': const [
    {'priceAmount': 1200, 'priceCurrency': 'NPR', 'isDefault': true},
  ],
};

/// A `ReelDto` as the public reel reads return it.
Map<String, dynamic> reelCard(String id, {String caption = ''}) => {
  'id': id,
  'caption': caption,
  'creatorHandle': 'mira',
  'thumbnailCdnUrl': '',
};

/// Pumps [child] in the Mall harness with [api] behind every provider.
Future<void> pumpWithApi(
  WidgetTester tester,
  RailsApi api,
  Widget child,
) async {
  await pumpMall(
    tester,
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api)],
      child: child,
    ),
  );
  await tester.pumpAndSettle();
}
