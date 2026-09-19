import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/sponsored_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _MockSearchDataSource extends Mock
    implements CustomerSearchRemoteDataSource {}

const _sponsored = SearchResultProduct(
  productId: 'p-sponsored',
  name: 'Linen shirt',
  heroImageUrl: '',
  price: 1200,
  currency: 'NPR',
  averageRating: 4.5,
  isSponsored: true,
  sponsoredLabel: 'Sponsored',
  organicPosition: 7,
);

const _organic = SearchResultProduct(
  productId: 'p-organic',
  name: 'Cotton shirt',
  heroImageUrl: '',
  price: 900,
  currency: 'NPR',
  averageRating: 0,
);

const _explanation =
    "This is a paid placement. It's shown because it matches your search "
    'and is in stock.';

void main() {
  late _MockSearchDataSource dataSource;

  setUp(() => dataSource = _MockSearchDataSource());

  Future<void> pumpResults(
    WidgetTester tester,
    List<SearchResultProduct> products,
  ) async {
    when(() => dataSource.search('shirt')).thenAnswer(
      (_) async => CustomerSearchResults(
        products: products,
        brands: const [],
        reels: const [],
        creators: const [],
        totalHits: products.length,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerSearchRemoteDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(home: SearchResultsScreen(query: 'shirt')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a sponsored result shows a readable badge and says it first', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpResults(tester, const [_organic, _sponsored]);

    final badge = find.text('Sponsored');
    expect(badge, findsOneWidget);
    expect(tester.getSize(badge).height, greaterThan(0));
    final style = tester.widget<Text>(badge).style;
    expect(style?.color, DesignTokens.warningTextLight);
    expect(style?.fontSize, greaterThanOrEqualTo(12));
    expect(find.byType(SponsoredBadge), findsOneWidget);

    String tileLabel(String productId) => tester
        .getSemantics(find.byKey(ValueKey('search-product-$productId')))
        .label;

    // The disclosure comes first, before the product is named — the
    // requirement. The rest of the sentence is now the Mall row's, so the
    // money and rating read the same here as on any other product row.
    expect(
      tileLabel('p-sponsored'),
      'Sponsored. Linen shirt, Rs 1,200, Rated 4.5 out of 5',
    );
    expect(tileLabel('p-organic'), 'Cotton shirt, Rs 900');
    expect(find.bySemanticsLabel('Why am I seeing this?'), findsOneWidget);

    // Disposed in the body: the leak check runs before tear-downs.
    semantics.dispose();
  });

  testWidgets('the info icon explains the placement and its organic rank', (
    tester,
  ) async {
    await pumpResults(tester, const [_sponsored]);

    await tester.tap(find.byKey(const ValueKey('sponsored-info')));
    await tester.pumpAndSettle();

    expect(
      find.text('$_explanation Without payment it would be result #7.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This is a paid placement.'), findsNothing);
  });

  testWidgets('without an organic position the last sentence is dropped', (
    tester,
  ) async {
    await pumpResults(tester, const [
      SearchResultProduct(
        productId: 'p-unranked',
        name: 'Hemp tote',
        heroImageUrl: '',
        price: 700,
        currency: 'NPR',
        averageRating: 0,
        isSponsored: true,
        sponsoredLabel: 'Sponsored',
      ),
    ]);

    await tester.tap(find.byKey(const ValueKey('sponsored-info')));
    await tester.pumpAndSettle();

    expect(find.text(_explanation), findsOneWidget);
    expect(find.textContaining('Without payment'), findsNothing);
  });

  testWidgets('organic results carry no badge', (tester) async {
    await pumpResults(tester, const [_organic]);

    expect(find.byType(SponsoredBadge), findsNothing);
    expect(find.text('Sponsored'), findsNothing);
    expect(find.text('Cotton shirt'), findsOneWidget);
  });

  test('sponsoredPlacementExplanation adds the rank only when known', () {
    expect(sponsoredPlacementExplanation(null), _explanation);
    expect(
      sponsoredPlacementExplanation(3),
      '$_explanation Without payment it would be result #3.',
    );
  });
}
