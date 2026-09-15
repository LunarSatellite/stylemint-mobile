import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/product_listing_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/product_filter_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../mall_test_support.dart';

final _route = GoRoute(
  path: RouteNames.productListing,
  builder: (_, state) => ProductListingScreen(
    query: ProductListingQuery.fromQueryParameters(state.uri.queryParameters),
    title: state.uri.queryParameters['title'],
  ),
);

Future<FakeMallCatalogRepository> _pump(
  WidgetTester tester,
  Either<NetworkExceptions, CatalogPage<CatalogProduct>> Function(
    ProductsCall call,
  )
  onProducts, {
  String location = '/products?sort=newest&title=New%20arrivals',
  double width = 390,
  double textScale = 1,
}) async {
  final repo = FakeMallCatalogRepository(onProducts: onProducts);
  await pumpMallApp(
    tester,
    location: location,
    routes: [_route],
    overrides: [mallCatalogRepositoryProvider.overrideWithValue(repo)],
    width: width,
    textScale: textScale,
  );
  return repo;
}

Either<NetworkExceptions, CatalogPage<CatalogProduct>> _three(ProductsCall _) =>
    right(productPage(['a', 'b', 'c'], total: 3));

void main() {
  testWidgets('title from the query; sort chips reload from the first page', (
    tester,
  ) async {
    final repo = await _pump(tester, _three);

    expect(find.text('New arrivals'), findsOneWidget);
    expect(find.text('3 products'), findsOneWidget);
    expect(repo.productCalls.single.query.sort, ProductSort.newest);

    await tester.ensureVisible(find.text('Top rated'));
    await tester.pump();
    await tester.tap(find.text('Top rated'));
    await tester.pump();
    await tester.pump();
    expect(repo.productCalls.last.query.sort, ProductSort.rating);
    expect(repo.productCalls.last.cursor, isNull);

    await tester.ensureVisible(find.text('Price ↓'));
    await tester.pump();
    await tester.tap(find.text('Price ↓'));
    await tester.pump();
    expect(repo.productCalls.last.query.sort, ProductSort.priceDesc);
  });

  testWidgets('the filter sheet applies price, on sale and rating', (
    tester,
  ) async {
    final repo = await _pump(tester, _three);

    await tester.tap(find.text('Filter'));
    await settleTransition(tester);
    expect(find.byType(ProductFilterSheet), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '500');
    await tester.enterText(find.byType(TextField).last, '3000');
    await tester.tap(find.text('On sale'));
    await tester.pump();
    await tester.tap(find.text('4★ & up'));
    await tester.pump();
    await tester.ensureVisible(find.text('Show results'));
    await tester.pump();
    await tester.tap(find.text('Show results'));
    await settleTransition(tester);

    final query = repo.productCalls.last.query;
    expect(query.minPrice, 500);
    expect(query.maxPrice, 3000);
    expect(query.onSale, isTrue);
    expect(query.inStock, isFalse);
    expect(query.minRating, 4);
    expect(query.sort, ProductSort.newest);
    expect(find.byType(ProductFilterSheet), findsNothing);
  });

  testWidgets('a minimum above the maximum is caught in the sheet', (
    tester,
  ) async {
    final repo = await _pump(tester, _three);
    await tester.tap(find.text('Filter'));
    await settleTransition(tester);

    await tester.enterText(find.byType(TextField).first, '5000');
    await tester.enterText(find.byType(TextField).last, '100');
    await tester.ensureVisible(find.text('Show results'));
    await tester.pump();
    await tester.tap(find.text('Show results'));
    await tester.pump();

    expect(
      find.text('The minimum price must be below the maximum.'),
      findsOneWidget,
    );
    expect(repo.productCalls, hasLength(1));
  });

  testWidgets('scrolling pages in the next page without duplicates', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      (call) => right(
        call.cursor == null
            ? productPage(
                [for (var i = 0; i < 20; i++) 'p$i'],
                cursor: 'c1',
                total: 23,
              )
            : productPage(['p18', 'p19', 'p20', 'p21', 'p22']),
      ),
    );

    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
      await tester.pump();
    }
    await tester.pump();

    expect(repo.productCalls.map((c) => c.cursor), [null, 'c1']);
    expect(find.text('Product p22'), findsOneWidget);
    expect(find.text('Product p19'), findsOneWidget);
  });

  testWidgets('no matches offers Clear filters', (tester) async {
    final repo = await _pump(
      tester,
      (call) => right(
        call.query.onSale
            ? const CatalogPage<CatalogProduct>(items: [])
            : productPage(['a', 'b', 'c'], total: 3),
      ),
      location: '/products?onSale=true&vendorAccountId=v-1',
    );

    expect(find.text('No products match these filters'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pump();
    await tester.pump();

    expect(repo.productCalls.last.query.onSale, isFalse);
    expect(repo.productCalls.last.query.vendorAccountId, 'v-1');
    expect(find.text('3 products'), findsOneWidget);
  });

  testWidgets('an error retries', (tester) async {
    var fail = true;
    final repo = await _pump(
      tester,
      (call) => fail
          ? left(const NetworkExceptions.serverUnavailable())
          : _three(call),
    );
    expect(
      find.text("Couldn't load products. Please try again."),
      findsOneWidget,
    );
    fail = false;
    await tester.tap(find.text('Tap to retry'));
    await tester.pump();
    await tester.pump();
    expect(repo.productCalls, hasLength(2));
    expect(find.text('3 products'), findsOneWidget);
  });

  testWidgets('a product opens its detail page', (tester) async {
    await _pump(tester, _three);
    // The card's tap overlay sits over its text.
    await tester.tap(find.text('Product b'), warnIfMissed: false);
    await settleTransition(tester);
    expect(find.text('product:b'), findsOneWidget);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('grid and filter sheet fit at ${width.toInt()}dp, text ×1.3', (
      tester,
    ) async {
      await _pump(
        tester,
        (call) => right(
          productPage([for (var i = 0; i < 20; i++) 'p$i'], total: 20),
        ),
        width: width,
        textScale: 1.3,
        location: '/products?title=A%20much%20longer%20listing%20title%20here',
      );
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 2000));
      await tester.pump();

      await tester.tap(find.text('Filter'));
      await settleTransition(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty state fits at ${width.toInt()}dp, text ×1.3', (
      tester,
    ) async {
      await _pump(
        tester,
        (_) => right(const CatalogPage<CatalogProduct>(items: [])),
        location: '/products?onSale=true',
        width: width,
        textScale: 1.3,
      );
      expect(find.text('No products match these filters'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
