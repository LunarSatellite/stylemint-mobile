import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

import '../../../orders_test_harness.dart';

/// Serves the search endpoints from canned bodies and records what was
/// asked with a token (`get`) and without (`authGet`).
class _SearchApi extends ApiClient {
  _SearchApi({required this.unified, this.ai}) : super(dio: Dio());

  final Map<String, dynamic> unified;
  final Map<String, dynamic>? ai;
  final List<String> tokenGets = [];
  final List<String> anonymousGets = [];

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    tokenGets.add(uri);
    // The customer search refuses a guest, as the server does.
    final request = RequestOptions(path: uri);
    throw DioException(
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 401),
    );
  }

  @override
  Future<dynamic> authGet(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? data,
  }) async {
    anonymousGets.add(uri);
    if (uri == CustomerSearchRemoteDataSource.aiSearchPath) return ai;
    if (uri == CustomerSearchRemoteDataSource.publicSearchPath) return unified;
    return null;
  }
}

Map<String, dynamic> _body({
  List<Map<String, dynamic>> products = const [
    {'productId': 'p-1', 'name': 'Red kurta', 'price': 1200},
    {'productId': 'p-2', 'name': 'Kurta set', 'price': 2400},
  ],
  List<Map<String, dynamic>> brands = const [],
  int? productTotal,
}) => {
  'products': products,
  'brands': brands,
  'reels': const <dynamic>[],
  'creators': const <dynamic>[],
  'totalHits': products.length + brands.length,
  'productTotal': ?productTotal,
};

Map<String, dynamic> _ai({bool? aiApplied}) => {
  'aiApplied': ?aiApplied,
  'queryUnderstanding': 'a red cotton kurta',
  'items': const [
    {'entityId': 'p-1', 'entityType': 'product', 'reason': 'Matches red.'},
  ],
};

/// Pumps `/search-results?q=red kurta` signed out, through the real
/// providers and data source, with stub pages for where a tap can go.
Future<_SearchApi> _pumpGuest(
  WidgetTester tester, {
  Map<String, dynamic>? unified,
  Map<String, dynamic>? ai,
}) async {
  setPhoneView(tester);
  final api = _SearchApi(unified: unified ?? _body(), ai: ai);
  GoRoute stub(String path, String Function(GoRouterState state) label) =>
      GoRoute(
        path: path,
        builder: (_, state) =>
            Scaffold(body: Center(child: Text(label(state)))),
      );
  final router = GoRouter(
    initialLocation:
        '${RouteNames.searchResults}?q=${Uri.encodeComponent('red kurta')}',
    routes: [
      GoRoute(
        path: RouteNames.searchResults,
        builder: (_, state) =>
            SearchResultsScreen(query: state.uri.queryParameters['q'] ?? ''),
      ),
      stub(
        RouteNames.brandStorefront,
        (s) => 'brand:${s.pathParameters['vendorAccountId']}',
      ),
      stub(RouteNames.productListing, (s) => 'listing:${s.uri.query}'),
      stub(
        RouteNames.productDetail,
        (s) => 'product:${s.pathParameters['productId']}',
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        searchViewerSignedInProvider.overrideWithValue(false),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('a guest gets results from the public search, not an error', (
    tester,
  ) async {
    final api = await _pumpGuest(tester);

    expect(find.text("We couldn't run that search"), findsNothing);
    expect(find.text('Red kurta'), findsOneWidget);
    expect(find.text('Kurta set'), findsOneWidget);
    expect(api.tokenGets, isEmpty);
    expect(
      api.anonymousGets,
      contains(CustomerSearchRemoteDataSource.publicSearchPath),
    );
  });

  group('brand results open the brand', () {
    Future<void> tapBrand(WidgetTester tester) async {
      await tester.tap(find.text('Brands'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kathmandu Atelier'));
      await tester.pumpAndSettle();
    }

    testWidgets('by vendorAccountId when sent', (tester) async {
      await _pumpGuest(
        tester,
        unified: _body(
          brands: const [
            {
              'brandId': 'profile-9',
              'vendorAccountId': 'account-9',
              'name': 'Kathmandu Atelier',
            },
          ],
        ),
      );
      await tapBrand(tester);

      expect(find.text('brand:account-9'), findsOneWidget);
    });

    testWidgets('by brandId otherwise', (tester) async {
      await _pumpGuest(
        tester,
        unified: _body(
          brands: const [
            {'brandId': 'account-7', 'name': 'Kathmandu Atelier'},
          ],
        ),
      );
      await tapBrand(tester);

      expect(find.text('brand:account-7'), findsOneWidget);
    });
  });

  group('AI wording', () {
    for (final (label, applied) in const [
      ('missing', null),
      ('false', false),
    ]) {
      testWidgets('is hidden when aiApplied is $label', (tester) async {
        await _pumpGuest(tester, ai: _ai(aiApplied: applied));

        expect(find.textContaining('Understood as'), findsNothing);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
        expect(find.text('Matches red.'), findsNothing);
        // The keyword order stands.
        expect(
          tester.getTopLeft(find.text('Red kurta')).dy,
          lessThan(tester.getTopLeft(find.text('Kurta set')).dy),
        );
      });
    }

    testWidgets('is shown when aiApplied is true', (tester) async {
      await _pumpGuest(tester, ai: _ai(aiApplied: true));

      expect(
        find.text('Understood as: a red cotton kurta'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.auto_awesome_rounded), findsWidgets);
      expect(find.text('Matches red.'), findsOneWidget);
    });
  });

  group('See all', () {
    testWidgets('names the total and opens the listing for the query', (
      tester,
    ) async {
      await _pumpGuest(tester, unified: _body(productTotal: 137));

      expect(find.text('See all 137 products'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('search-see-all-products')));
      await tester.pumpAndSettle();

      expect(find.text('listing:q=red+kurta'), findsOneWidget);
    });

    testWidgets('has no number when the server sends no total', (
      tester,
    ) async {
      await _pumpGuest(tester);

      expect(find.text('See all products'), findsOneWidget);
    });

    test('builds /products?q=…', () {
      expect(
        Uri.parse(searchSeeAllProductsLocation('  red kurta ')!),
        Uri(path: '/products', queryParameters: {'q': 'red kurta'}),
      );
      expect(searchSeeAllProductsLocation('   '), isNull);
      expect(searchSeeAllProductsLabel(null), 'See all products');
      expect(searchSeeAllProductsLabel(1), 'See all 1 product');
      expect(searchSeeAllProductsLabel(42), 'See all 42 products');
    });
  });
}
