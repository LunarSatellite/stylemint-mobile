import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/endless_aisle.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/in_store_locations.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/screens/in_store_store_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Answers each page from [pages] by cursor, in order; the last repeats.
class _FakeInStoreRepository implements InStoreRepository {
  _FakeInStoreRepository(this.pages);

  final Map<String?, List<Either<NetworkExceptions, StoreProductsPage>>> pages;
  final List<({String vendorId, String? cursor})> requested = [];

  @override
  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  }) async {
    requested.add((vendorId: vendorAccountId, cursor: cursor));
    final answers = pages[cursor]!;
    return answers.length > 1 ? answers.removeAt(0) : answers.single;
  }

  @override
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  ) async => right(const []);

  @override
  Future<Either<NetworkExceptions, EndlessAisle>> getEndlessAisle(
    String code,
  ) async => left(const NetworkExceptions.notFound());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<StoreProduct> _products(int from, int count) => [
  for (var i = from; i < from + count; i++)
    StoreProduct(
      id: 'p-$i',
      name: 'Product $i',
      price: Money(amount: 1000.0 + i, currency: 'NPR'),
    ),
];

Either<NetworkExceptions, StoreProductsPage> _page(
  List<StoreProduct> products, {
  String? next,
}) => right((products: products, nextCursor: next));

Finder _card(String id) => find.byKey(ValueKey('store-product-$id'));

void main() {
  Future<void> pump(
    WidgetTester tester,
    _FakeInStoreRepository repository, {
    String? vendorId = 'v-1',
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: inStoreStoreLocation(
        storeId: 's-1',
        code: 'ABCD2345',
        storeName: 'Mint Thamel',
        storeCity: 'Kathmandu',
        vendorName: 'Mint Studio',
        vendorId: vendorId,
      ),
      routes: [
        GoRoute(
          path: RouteNames.inStoreStore,
          builder: (_, state) {
            final query = state.uri.queryParameters;
            return InStoreStoreScreen(
              storeId: state.pathParameters['storeId']!,
              code: query[InStoreQuery.code],
              storeName: query[InStoreQuery.store],
              storeCity: query[InStoreQuery.city],
              vendorName: query[InStoreQuery.vendor],
              vendorId: query[InStoreQuery.vendorId],
            );
          },
        ),
        GoRoute(
          path: RouteNames.inStoreProduct,
          builder: (_, state) {
            final query = state.uri.queryParameters;
            return Text(
              'product ${state.pathParameters['productId']} in '
              '${query[InStoreQuery.store]}, ${query[InStoreQuery.city]} '
              'store ${query[InStoreQuery.storeId]} '
              'code ${query[InStoreQuery.code]}',
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [inStoreRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the store and its products in a two-column grid', (
    tester,
  ) async {
    final repository = _FakeInStoreRepository({
      null: [_page(_products(0, 3))],
    });

    await pump(tester, repository);

    expect(find.text('Mint Thamel'), findsOneWidget);
    expect(find.text('Kathmandu'), findsOneWidget);
    expect(find.text('By Mint Studio'), findsOneWidget);
    expect(find.text(InStoreStoreScreen.productsTitle), findsOneWidget);
    expect(find.text('Product 0'), findsOneWidget);
    expect(find.text('Rs 1,000.00'), findsOneWidget);
    expect(find.text('Product 2'), findsOneWidget);
    expect(find.text('Rs 1,002.00'), findsOneWidget);
    expect(find.text(InStoreStoreScreen.productsEmpty), findsNothing);

    final first = tester.getTopLeft(_card('p-0'));
    final second = tester.getTopLeft(_card('p-1'));
    final third = tester.getTopLeft(_card('p-2'));
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(third.dx, first.dx);
    expect(third.dy, greaterThan(first.dy));

    expect(repository.requested, [(vendorId: 'v-1', cursor: null)]);
  });

  testWidgets('a vendor with no products keeps the shelf-code empty state', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeInStoreRepository({
        null: [_page(const [])],
      }),
    );

    expect(find.text(InStoreStoreScreen.productsEmpty), findsOneWidget);
    expect(find.text('Scan a shelf code'), findsOneWidget);
    expect(_card('p-0'), findsNothing);
  });

  testWidgets('without a vendor id it asks for nothing and shows the '
      'empty state', (tester) async {
    final repository = _FakeInStoreRepository({});

    await pump(tester, repository, vendorId: null);

    expect(find.text(InStoreStoreScreen.productsEmpty), findsOneWidget);
    expect(find.text('Scan a shelf code'), findsOneWidget);
    expect(repository.requested, isEmpty);
  });

  testWidgets('a failed load can be retried', (tester) async {
    final repository = _FakeInStoreRepository({
      null: [
        left(const NetworkExceptions.serverUnavailable()),
        _page(_products(0, 2)),
      ],
    });

    await pump(tester, repository);

    expect(find.text(InStoreStoreScreen.productsFailed), findsOneWidget);
    await tester.tap(find.text('Tap to retry'));
    await tester.pumpAndSettle();

    expect(_card('p-1'), findsOneWidget);
    expect(repository.requested, hasLength(2));
  });

  testWidgets('scrolling toward the end loads the next page once', (
    tester,
  ) async {
    final repository = _FakeInStoreRepository({
      null: [_page(_products(0, 20), next: 'c-2')],
      'c-2': [_page(_products(20, 3))],
    });

    await pump(tester, repository);
    expect(repository.requested.map((r) => r.cursor), [null]);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      _card('p-22'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(_card('p-22'), findsOneWidget);
    expect(repository.requested.map((r) => r.cursor), [null, 'c-2']);
  });

  testWidgets('a product opens the in-store product screen for this store', (
    tester,
  ) async {
    await pump(
      tester,
      _FakeInStoreRepository({
        null: [_page(_products(0, 2))],
      }),
    );

    await tester.tap(_card('p-1'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'product p-1 in Mint Thamel, Kathmandu store s-1 code ABCD2345',
      ),
      findsOneWidget,
    );
  });
}
