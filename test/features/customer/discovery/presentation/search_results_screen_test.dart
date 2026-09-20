import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

class _MockSearchDataSource extends Mock
    implements CustomerSearchRemoteDataSource {}

const _rated = SearchResultProduct(
  productId: 'p-rated',
  name: 'Linen shirt',
  heroImageUrl: 'https://example.com/product-photo.jpg',
  price: 1200,
  currency: 'NPR',
  averageRating: 4.5,
);

const _unrated = SearchResultProduct(
  productId: 'p-unrated',
  name: 'Cotton shirt',
  heroImageUrl: 'https://example.com/product-photo.jpg',
  price: 900,
  currency: 'NPR',
  averageRating: 0,
);

const _reel = SearchResultReel(
  reelId: 'r-1',
  thumbnailUrl: 'https://example.com/reel.jpg',
  viewCount: 2400,
);

const _reelNoViews = SearchResultReel(
  reelId: 'r-2',
  thumbnailUrl: '',
  viewCount: 0,
);

const _brand = SearchResultBrand(
  brandId: 'b-1',
  name: 'Kathmandu Atelier',
  averageRating: 0,
  productCount: 12,
);

CustomerSearchResults _results({
  List<SearchResultProduct> products = const [],
  List<SearchResultReel> reels = const [],
  List<SearchResultBrand> brands = const [],
}) => CustomerSearchResults(
  products: products,
  brands: brands,
  reels: reels,
  creators: const [],
  totalHits: products.length + reels.length + brands.length,
);

Set<String> _loadedImageUrls(WidgetTester tester) => tester
    .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
    .map((image) => image.imageUrl)
    .toSet();

void main() {
  late _MockSearchDataSource dataSource;

  setUp(() => dataSource = _MockSearchDataSource());

  Future<void> pump(
    WidgetTester tester,
    CustomerSearchResults results, {
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = Size(width, width <= 320 ? 568 : 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    when(() => dataSource.search('shirt')).thenAnswer((_) async => results);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerSearchRemoteDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: app ?? const SizedBox.shrink(),
          ),
          home: const SearchResultsScreen(query: 'shirt'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('product hits are Mall rows, and no product photo is built', (
    tester,
  ) async {
    await pump(tester, _results(products: const [_rated, _unrated]));

    expect(find.byType(MallResultRow), findsNWidgets(2));
    expect(find.text('Linen shirt'), findsOneWidget);
    // The owner directive: product photos live on product detail only.
    expect(
      _loadedImageUrls(tester),
      isNot(contains('https://example.com/product-photo.jpg')),
    );
  });

  testWidgets('a product with no rating claims none', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, _results(products: const [_rated, _unrated]));

    String labelOf(String name) => tester
        .getSemantics(
          find.ancestor(
            of: find.text(name),
            matching: find.byType(MallResultRow),
          ),
        )
        .label;

    expect(labelOf('Linen shirt'), contains('Rated 4.5 out of 5'));
    // Not "0.0 Stars", which is what the old row drew for every product the
    // catalogue had never reviewed.
    expect(labelOf('Cotton shirt'), isNot(contains('Rated')));
    expect(find.text('0.0'), findsNothing);

    semantics.dispose();
  });

  testWidgets('no result row carries a control that does nothing', (
    tester,
  ) async {
    await pump(tester, _results(products: const [_rated]));

    // The row used to end in a shopping-cart glyph that was not a button and
    // added nothing: an affordance the screen could not honour.
    expect(find.byIcon(Icons.shopping_cart_outlined), findsNothing);
  });

  testWidgets('each empty tab is the kit empty state, not a bare sentence', (
    tester,
  ) async {
    await pump(tester, _results());

    expect(find.byType(MallEmptyState), findsOneWidget);
    expect(find.text('No products found'), findsOneWidget);

    await openTab(tester, 'Reels');
    expect(find.text('No reels found'), findsOneWidget);

    await openTab(tester, 'Brands');
    expect(find.text('No brands found'), findsOneWidget);
  });

  testWidgets('a failed search gets the designed failure state', (
    tester,
  ) async {
    when(() => dataSource.search('shirt')).thenThrow(Exception('boom'));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          customerSearchRemoteDataSourceProvider.overrideWithValue(dataSource),
        ],
        child: const MaterialApp(home: SearchResultsScreen(query: 'shirt')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MallErrorState), findsOneWidget);
    expect(find.text("We couldn't run that search"), findsOneWidget);
    // Never the raw exception.
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('a reel result is a labelled button and only claims real views', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, _results(reels: const [_reel, _reelNoViews]));
    await openTab(tester, 'Reels');

    expect(find.bySemanticsLabel('Reel, 2.4k views'), findsOneWidget);
    // The second reel has no view count, so it claims none.
    expect(find.bySemanticsLabel('Reel'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets('a brand result is a labelled button', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, _results(brands: const [_brand]));
    await openTab(tester, 'Brands');

    expect(
      find.bySemanticsLabel('Kathmandu Atelier. 12 products'),
      findsOneWidget,
    );
    // The brand carries no rating, so no star is drawn.
    expect(find.byIcon(Icons.star_rounded), findsNothing);

    semantics.dispose();
  });

  for (final width in const [320.0, 390.0]) {
    for (final scale in const [1.0, 1.3]) {
      testWidgets(
        'results lay out without overflow — ${width.toInt()}dp, text ×$scale',
        (tester) async {
          await pump(
            tester,
            _results(
              products: const [_rated, _unrated],
              reels: const [_reel],
              brands: const [_brand],
            ),
            width: width,
            textScale: scale,
          );

          expect(tester.takeException(), isNull);
          // Every tab, not only Brands: the reel grid's gutter and the brand
          // row's rhythm were both retuned and each has its own layout.
          for (final tab in const ['Reels', 'Brands', 'Products']) {
            await openTab(tester, tab);
            expect(
              tester.takeException(),
              isNull,
              reason: 'the $tab tab overflowed at ${width}dp x $scale',
            );
          }
        },
      );
    }
  }
}
