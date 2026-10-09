import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';

/// Answers each GET by path and records which paths were asked, and whether
/// each went with the token (`get`) or without (`authGet`).
class _RoutedApiClient extends ApiClient {
  _RoutedApiClient(this.bodies, {this.customerStatus}) : super(dio: Dio());

  final Map<String, Object?> bodies;

  /// When set, `customer/search` fails with this HTTP status.
  final int? customerStatus;

  final List<String> tokenGets = [];
  final List<String> anonymousGets = [];
  final Map<String, Map<String, dynamic>?> queries = {};

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    tokenGets.add(uri);
    queries[uri] = queryParameters;
    if (customerStatus case final status?) {
      final request = RequestOptions(path: uri);
      throw DioException(
        requestOptions: request,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: status,
        ),
      );
    }
    return bodies[uri];
  }

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) async {
    anonymousGets.add(uri);
    queries[uri] = queryParameters;
    return bodies[uri];
  }
}

const String _customer = CustomerSearchRemoteDataSource.customerSearchPath;
const String _public = CustomerSearchRemoteDataSource.publicSearchPath;
const String _ai = CustomerSearchRemoteDataSource.aiSearchPath;

Map<String, dynamic> _unified({
  List<Map<String, dynamic>> products = const [],
  List<Map<String, dynamic>> brands = const [],
  Object? productTotal,
}) => {
  'products': products,
  'brands': brands,
  'reels': const <dynamic>[],
  'creators': const <dynamic>[],
  'totalHits': products.length + brands.length,
  'productTotal': ?productTotal,
};

const List<Map<String, dynamic>> _twoProducts = [
  {'productId': 'p-1', 'name': 'Red kurta', 'price': 1200},
  {'productId': 'p-2', 'name': 'Kurta set', 'price': 2400},
];

Map<String, dynamic> _aiBody({Object? aiApplied}) => {
  'aiApplied': ?aiApplied,
  'queryUnderstanding': 'a red cotton kurta',
  'items': const [
    {'entityId': 'p-2', 'entityType': 'product', 'reason': 'Matches red.'},
  ],
};

void main() {
  group('endpoint by sign-in state', () {
    test(
      'signed out searches the public endpoint, never the customer one',
      () async {
        final api = _RoutedApiClient({
          _public: _unified(products: _twoProducts),
        });

        final results = await CustomerSearchRemoteDataSource(
          apiClient: api,
          isSignedIn: () => false,
        ).search('kurta');

        expect(api.tokenGets, isEmpty);
        expect(api.anonymousGets, containsAll([_public, _ai]));
        expect(api.queries[_public], {
          'q': 'kurta',
          'type': 'all',
          'limit': 20,
        });
        expect(results.products.map((p) => p.productId), ['p-1', 'p-2']);
      },
    );

    test('signed in searches the personalised customer endpoint', () async {
      final api = _RoutedApiClient({
        _customer: _unified(products: _twoProducts),
      });

      await CustomerSearchRemoteDataSource(
        apiClient: api,
        isSignedIn: () => true,
      ).search('kurta');

      expect(api.tokenGets, [_customer]);
      expect(api.anonymousGets, isNot(contains(_public)));
    });

    test('the sign-in state is asked on every search', () async {
      var signedIn = true;
      final api = _RoutedApiClient({
        _customer: _unified(),
        _public: _unified(),
      });
      final source = CustomerSearchRemoteDataSource(
        apiClient: api,
        isSignedIn: () => signedIn,
      );

      await source.search('a');
      signedIn = false;
      await source.search('b');

      expect(api.tokenGets, [_customer]);
      expect(api.anonymousGets, contains(_public));
    });

    test('an expired session that cannot refresh falls back to the guest '
        'search', () async {
      final api = _RoutedApiClient(
        {_public: _unified(products: _twoProducts)},
        customerStatus: 401,
      );

      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
        isSignedIn: () => true,
      ).search('kurta');

      expect(api.tokenGets, [_customer]);
      expect(api.anonymousGets, contains(_public));
      expect(results.products, hasLength(2));
    });

    test('other customer-search failures still surface', () async {
      final api = _RoutedApiClient({}, customerStatus: 500);

      await expectLater(
        CustomerSearchRemoteDataSource(
          apiClient: api,
          isSignedIn: () => true,
        ).search('kurta'),
        throwsA(isA<DioException>()),
      );
    });

    test('a body that is not the grouped object reads as no hits', () async {
      final api = _RoutedApiClient({_public: const <dynamic>[]});

      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
        isSignedIn: () => false,
      ).search('kurta');

      expect(results.products, isEmpty);
      expect(results.brands, isEmpty);
      expect(results.productTotal, isNull);
    });
  });

  group('brand ids', () {
    Future<List<String>> brandIds(List<Map<String, dynamic>> brands) async {
      final api = _RoutedApiClient({_public: _unified(brands: brands)});
      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
        isSignedIn: () => false,
      ).search('atelier');
      return results.brands.map((b) => b.brandId).toList();
    }

    test('vendorAccountId wins over brandId', () async {
      expect(
        await brandIds(const [
          {'brandId': 'profile-1', 'vendorAccountId': 'account-1', 'name': 'A'},
        ]),
        ['account-1'],
      );
    });

    test('brandId is used when no vendorAccountId is sent', () async {
      expect(
        await brandIds(const [
          {'brandId': 'account-2', 'name': 'B'},
          {'brandId': 'account-3', 'vendorAccountId': '  ', 'name': 'C'},
        ]),
        ['account-2', 'account-3'],
      );
    });
  });

  group('aiApplied', () {
    Future<_Outcome> search(Map<String, dynamic>? ai) async {
      final api = _RoutedApiClient({
        _customer: _unified(products: _twoProducts),
        _ai: ai,
      });
      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
      ).search('red kurta');
      return (
        order: results.products.map((p) => p.productId).toList(),
        reasons: results.products.map((p) => p.matchReason).toList(),
        understanding: results.queryUnderstanding,
        aiApplied: results.aiApplied,
      );
    }

    test('missing means AI did not contribute: no reasons, no reorder, '
        'no "Understood as"', () async {
      final outcome = await search(_aiBody());
      expect(outcome.aiApplied, isFalse);
      expect(outcome.order, ['p-1', 'p-2']);
      expect(outcome.reasons, [null, null]);
      expect(outcome.understanding, isNull);
    });

    test('false is the same as missing', () async {
      final outcome = await search(_aiBody(aiApplied: false));
      expect(outcome.aiApplied, isFalse);
      expect(outcome.order, ['p-1', 'p-2']);
      expect(outcome.reasons, [null, null]);
      expect(outcome.understanding, isNull);
    });

    test('true reorders, explains and summarises', () async {
      final outcome = await search(_aiBody(aiApplied: true));
      expect(outcome.aiApplied, isTrue);
      expect(outcome.order, ['p-2', 'p-1']);
      expect(outcome.reasons, ['Matches red.', null]);
      expect(outcome.understanding, 'a red cotton kurta');
    });

    test('an AI outage is not AI applied', () async {
      final outcome = await search(null);
      expect(outcome.aiApplied, isFalse);
      expect(outcome.understanding, isNull);
    });
  });

  group('productTotal', () {
    Future<int?> total(Object? raw) async {
      final api = _RoutedApiClient({
        _public: _unified(products: _twoProducts, productTotal: raw),
      });
      final results = await CustomerSearchRemoteDataSource(
        apiClient: api,
        isSignedIn: () => false,
      ).search('kurta');
      return results.productTotal;
    }

    test('is read when sent', () async => expect(await total(137), 137));
    test('is null when missing', () async => expect(await total(null), isNull));
    test('ignores nonsense', () async => expect(await total('many'), isNull));
  });
}

typedef _Outcome = ({
  List<String> order,
  List<String?> reasons,
  String? understanding,
  bool aiApplied,
});
