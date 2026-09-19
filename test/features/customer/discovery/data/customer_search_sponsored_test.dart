import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';

class _GetApiClient extends ApiClient {
  _GetApiClient(this.body, {this.aiBody}) : super(dio: Dio());

  final Object? body;
  final Object? aiBody;
  String? getUri;
  Map<String, dynamic>? query;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    getUri = uri;
    query = queryParameters;
    return body;
  }

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) async => aiBody;
}

Future<List<SearchResultProduct>> _searchProducts(
  List<Map<String, dynamic>> products,
) async {
  final api = _GetApiClient(<String, dynamic>{
    'products': products,
    'totalHits': products.length,
  });
  final results = await CustomerSearchRemoteDataSource(
    apiClient: api,
  ).search('linen');
  expect(api.getUri, '/api/v1/customer/search');
  expect(api.query, {'q': 'linen', 'type': 'all', 'limit': 20});
  return results.products;
}

void main() {
  group('CustomerSearchRemoteDataSource sponsored product fields', () {
    test('maps a sponsored tile', () async {
      final product = (await _searchProducts([
        {
          'productId': 'p-1',
          'name': 'Linen shirt',
          'heroImageUrl': 'https://example.test/linen.jpg',
          'price': 1200,
          'currency': 'NPR',
          'averageRating': 4.5,
          'isSponsored': true,
          'sponsoredLabel': 'Sponsored',
          'organicPosition': 7,
        },
      ])).single;

      expect(product.productId, 'p-1');
      expect(product.name, 'Linen shirt');
      expect(product.isSponsored, isTrue);
      expect(product.sponsoredLabel, 'Sponsored');
      expect(product.organicPosition, 7);
      expect(product.sponsoredDisclosure, 'Sponsored');
    });

    test('a tile without the new fields reads as organic', () async {
      final product = (await _searchProducts([
        {'productId': 'p-2', 'name': 'Cotton shirt', 'price': 900},
      ])).single;

      expect(product.isSponsored, isFalse);
      expect(product.sponsoredLabel, isNull);
      expect(product.organicPosition, isNull);
      expect(product.sponsoredDisclosure, isNull);
    });

    test('tolerates loosely typed values', () async {
      final products = await _searchProducts([
        {
          'productId': 'p-3',
          'isSponsored': 'true',
          'sponsoredLabel': '  ',
          'organicPosition': '4',
        },
        {
          'productId': 'p-4',
          'isSponsored': false,
          'sponsoredLabel': 'Sponsored',
          'organicPosition': 0,
        },
      ]);

      final looselySponsored = products.first;
      expect(looselySponsored.isSponsored, isTrue);
      expect(looselySponsored.sponsoredLabel, isNull);
      expect(looselySponsored.organicPosition, 4);
      // A paid slot is always disclosed, even without a label.
      expect(looselySponsored.sponsoredDisclosure, 'Sponsored');

      final organic = products.last;
      expect(organic.isSponsored, isFalse);
      expect(organic.organicPosition, isNull);
      expect(organic.sponsoredDisclosure, isNull);
    });

    test('AI ranking reorders matches and retains its explanation', () async {
      final api = _GetApiClient(
        <String, dynamic>{
          'products': [
            {'productId': 'p-1', 'name': 'First organic'},
            {'productId': 'p-2', 'name': 'Best intent match'},
          ],
          'totalHits': 2,
        },
        aiBody: <String, dynamic>{
          'queryUnderstanding': 'breathable natural-fibre shirt',
          'items': [
            {
              'entityId': 'p-2',
              'entityType': 'product',
              'reason': 'The linen fabric directly matches your request.',
            },
          ],
        },
      );

      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
      ).search('linen');

      expect(results.products.map((p) => p.productId), ['p-2', 'p-1']);
      expect(
        results.products.first.matchReason,
        'The linen fabric directly matches your request.',
      );
      expect(
        results.queryUnderstanding,
        'breathable natural-fibre shirt',
      );
    });
  });
}
