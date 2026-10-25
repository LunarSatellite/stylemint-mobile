import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/search_understanding_chips.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

import '../../../orders_test_harness.dart';

/// AI features contract v1.0 §1: the unified search answers with hybrid
/// results itself — `aiApplied`, `matchType`/`matchReason` per tile and an
/// `understanding` block. These pin what the screen draws from them, and
/// that an older server (no `aiApplied` on the unified body) still gets
/// exactly the previous behaviour.
class _SearchApi extends ApiClient {
  _SearchApi({required this.unified, this.ai}) : super(dio: Dio());

  /// The unified body for one `q`.
  final Map<String, dynamic> Function(String q) unified;
  final Map<String, dynamic>? ai;
  final List<String> queries = [];
  int aiCalls = 0;

  @override
  Future<dynamic> get(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
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
    if (uri == CustomerSearchRemoteDataSource.aiSearchPath) {
      aiCalls++;
      if (ai == null) {
        // Not deployed: the server answers 404.
        final request = RequestOptions(path: uri);
        throw DioException(
          requestOptions: request,
          response: Response<dynamic>(
            requestOptions: request,
            statusCode: 404,
          ),
        );
      }
      return ai;
    }
    if (uri == CustomerSearchRemoteDataSource.publicSearchPath) {
      final q = queryParameters?['q'] as String? ?? '';
      queries.add(q);
      return unified(q);
    }
    return null;
  }
}

Map<String, dynamic> _hybrid({
  bool aiApplied = true,
  Map<String, dynamic>? understanding,
  List<Map<String, dynamic>>? products,
  List<Map<String, dynamic>> reels = const [],
}) => {
  'aiApplied': aiApplied,
  'queryUnderstanding': aiApplied ? 'Showing results for cotton scarf' : null,
  'products':
      products ??
      [
        {
          'productId': 'p-kw',
          'name': 'Cotton scarf',
          'price': 900,
          'matchType': 1,
        },
        {
          'productId': 'p-mean',
          'name': 'Woven neck wrap',
          'price': 1100,
          'matchType': 2,
          'matchReason': 'Similar in meaning to "cotton scarf"',
        },
      ],
  'brands': const <dynamic>[],
  'reels': reels,
  'creators': const <dynamic>[],
  'totalHits': 2,
  'understanding': ?understanding,
};

const Map<String, dynamic> _cottonUnderstanding = {
  'searchedText': 'scarf',
  'retrievalMode': 'hybrid',
  'chips': [
    {
      'kind': 'constraint',
      'attributeKey': 'material',
      'label': 'Material',
      'statement': 'Material is cotton',
      'sourceText': 'cotton',
    },
    {
      'kind': 'notApplied',
      'attributeKey': '',
      'label': '',
      'statement': 'budget',
      'sourceText': 'under 500 usd',
    },
    {'kind': 'somethingNew', 'statement': 'x', 'sourceText': 'y'},
  ],
  'setAsideUnverifiable': 3,
  'setAsideConflicting': 1,
  'degradedReason': null,
};

Future<_SearchApi> _pump(
  WidgetTester tester, {
  required Map<String, dynamic> Function(String q) unified,
  Map<String, dynamic>? ai,
  String query = 'cotton scarf under 500 usd',
}) async {
  setPhoneView(tester);
  final api = _SearchApi(unified: unified, ai: ai);
  final router = GoRouter(
    initialLocation:
        '${RouteNames.searchResults}?q=${Uri.encodeComponent(query)}',
    routes: [
      GoRoute(
        path: RouteNames.searchResults,
        builder: (_, state) =>
            SearchResultsScreen(query: state.uri.queryParameters['q'] ?? ''),
      ),
      GoRoute(
        path: RouteNames.productDetail,
        builder: (_, state) => Scaffold(
          body: Text('product:${state.pathParameters['productId']}'),
        ),
      ),
      GoRoute(
        path: RouteNames.reelDetail,
        builder: (_, state) =>
            Scaffold(body: Text('reel:${state.pathParameters['reelId']}')),
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
  group('hybrid products', () {
    testWidgets('a meaning-only hit is listed and wears the chip; a keyword '
        'hit does not', (tester) async {
      await _pump(tester, unified: (_) => _hybrid());

      expect(find.text('Cotton scarf'), findsOneWidget);
      expect(find.text('Woven neck wrap'), findsOneWidget);
      expect(find.byKey(MatchedByMeaningChip.chipKey), findsOneWidget);
      expect(
        find.text('Similar in meaning to "cotton scarf"'),
        findsOneWidget,
      );
      // The server's own sentence is shown as sent, not re-framed.
      expect(find.text('Showing results for cotton scarf'), findsOneWidget);
      expect(find.textContaining('Understood as'), findsNothing);
    });

    testWidgets('server order stands: nothing is re-sorted on the client', (
      tester,
    ) async {
      await _pump(
        tester,
        unified: (_) => _hybrid(
          products: const [
            {'productId': 'p-b', 'name': 'Second by name', 'matchType': 3},
            {'productId': 'p-a', 'name': 'A first by name', 'matchType': 1},
          ],
        ),
      );

      final second = tester.getTopLeft(find.text('Second by name')).dy;
      final first = tester.getTopLeft(find.text('A first by name')).dy;
      expect(second, lessThan(first));
    });

    testWidgets('a hybrid server is not asked the AI endpoint again', (
      tester,
    ) async {
      final api = await _pump(
        tester,
        unified: (_) => _hybrid(understanding: _cottonUnderstanding),
      );
      final before = api.aiCalls;

      await tester.tap(find.byKey(SearchUnderstandingChips.removeKey(0)));
      await tester.pumpAndSettle();

      expect(api.queries, hasLength(2));
      expect(api.aiCalls, before, reason: 'learnt from the first answer');
    });

    testWidgets('aiApplied false: no chip, no reason, no AI line', (
      tester,
    ) async {
      await _pump(
        tester,
        unified: (_) => _hybrid(
          aiApplied: false,
          products: const [
            {
              'productId': 'p-1',
              'name': 'Cotton scarf',
              'matchType': 2,
              'matchReason': 'should not be shown',
            },
          ],
        ),
      );

      expect(find.text('Cotton scarf'), findsOneWidget);
      expect(find.byKey(MatchedByMeaningChip.chipKey), findsNothing);
      expect(find.text('should not be shown'), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });
  });

  group('understanding chips', () {
    testWidgets('constraint and not-applied chips draw; an unknown kind '
        'does not', (tester) async {
      await _pump(
        tester,
        unified: (_) => _hybrid(understanding: _cottonUnderstanding),
      );

      expect(find.text('Material is cotton'), findsOneWidget);
      expect(find.text('Not applied: “under 500 usd”'), findsOneWidget);
      expect(find.text('x'), findsNothing);
      expect(
        find.text(
          '4 results left out: they do not record it, or record something '
          'else',
        ),
        findsOneWidget,
      );
      // Only the constraint can be taken off.
      expect(find.byKey(SearchUnderstandingChips.removeKey(0)), findsOneWidget);
      expect(find.byKey(SearchUnderstandingChips.removeKey(1)), findsNothing);
    });

    testWidgets('removing a chip searches again without its words', (
      tester,
    ) async {
      final api = await _pump(
        tester,
        unified: (q) => q.contains('cotton')
            ? _hybrid(understanding: _cottonUnderstanding)
            : _hybrid(
                products: const [
                  {'productId': 'p-w', 'name': 'Wool scarf', 'matchType': 1},
                ],
              ),
      );

      await tester.tap(find.byKey(SearchUnderstandingChips.removeKey(0)));
      await tester.pumpAndSettle();

      expect(api.queries.last, 'scarf under 500 usd');
      expect(find.text('Wool scarf'), findsOneWidget);
      expect(find.text('Material is cotton'), findsNothing);
      expect(find.textContaining('"scarf under 500 usd"'), findsOneWidget);
    });

    testWidgets('chips show even when aiApplied is false, with no sparkle', (
      tester,
    ) async {
      await _pump(
        tester,
        unified: (_) =>
            _hybrid(aiApplied: false, understanding: _cottonUnderstanding),
      );

      expect(find.text('Material is cotton'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });
  });

  group('reels by meaning', () {
    testWidgets('a meaning-only reel is marked on its thumbnail', (
      tester,
    ) async {
      await _pump(
        tester,
        unified: (_) => _hybrid(
          reels: const [
            {'reelId': 'r-1', 'thumbnailUrl': '', 'matchType': 2},
            {'reelId': 'r-2', 'thumbnailUrl': '', 'matchType': 1},
          ],
        ),
      );
      await tester.tap(find.text('Reels'));
      await tester.pumpAndSettle();

      expect(find.byKey(MatchedByMeaningChip.chipKey), findsOneWidget);
    });
  });

  group('older server (no aiApplied on the unified body)', () {
    testWidgets('falls back to the AI endpoint and the old frame', (
      tester,
    ) async {
      final api = await _pump(
        tester,
        unified: (_) => {
          'products': const [
            {'productId': 'p-1', 'name': 'Red kurta', 'matchType': 2},
            {'productId': 'p-2', 'name': 'Kurta set'},
          ],
          'brands': const <dynamic>[],
          'reels': const <dynamic>[],
          'creators': const <dynamic>[],
          'totalHits': 2,
        },
        ai: const {
          'aiApplied': true,
          'queryUnderstanding': 'a red cotton kurta',
          'items': [
            {'entityId': 'p-2', 'reason': 'Matches red.'},
          ],
        },
        query: 'red kurta',
      );

      expect(api.aiCalls, 1);
      expect(find.text('Understood as: a red cotton kurta'), findsOneWidget);
      expect(find.text('Matches red.'), findsOneWidget);
      // A matchType from a server that never promised one is ignored.
      expect(find.byKey(MatchedByMeaningChip.chipKey), findsNothing);
      // AI order applies on the old path.
      expect(
        tester.getTopLeft(find.text('Kurta set')).dy,
        lessThan(tester.getTopLeft(find.text('Red kurta')).dy),
      );
    });

    testWidgets('a 404 from the AI endpoint leaves plain keyword results', (
      tester,
    ) async {
      await _pump(
        tester,
        unified: (_) => {
          'products': const [
            {'productId': 'p-1', 'name': 'Red kurta'},
          ],
          'totalHits': 1,
        },
        query: 'red kurta',
      );

      expect(find.text('Red kurta'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
      expect(find.byType(SearchUnderstandingChips), findsNothing);
    });
  });

  group('queryWithoutChip', () {
    SearchUnderstandingChip chip(String source) => SearchUnderstandingChip(
      kind: SearchChipKind.constraint,
      statement: 's',
      sourceText: source,
    );

    test('takes out whole words only, case-insensitively', () {
      expect(queryWithoutChip('Cotton scarf', chip('cotton')), 'scarf');
      expect(queryWithoutChip('cottonwood scarf', chip('cotton')), isNull);
      expect(
        queryWithoutChip('scarf not leather', chip('not leather')),
        'scarf',
      );
    });

    test('refuses to leave an empty query', () {
      expect(queryWithoutChip('cotton', chip('cotton')), isNull);
      expect(queryWithoutChip('scarf', chip('')), isNull);
    });
  });

  test('readSearchUnderstanding tolerates junk', () {
    expect(readSearchUnderstanding(null), isNull);
    expect(readSearchUnderstanding('x'), isNull);
    final u = readSearchUnderstanding(const {
      'chips': 'nope',
      'setAsideUnverifiable': -2,
    })!;
    expect(u.chips, isEmpty);
    expect(u.setAsideTotal, 0);
  });
}
