import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/in_store_locations.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/screens/in_store_product_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/widgets/product_reels_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/repositories/reviews_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockReviewsRepository extends Mock implements ReviewsRepository {}

/// Answers from [answers] in order; the last one repeats.
class _FakeInStoreRepository implements InStoreRepository {
  _FakeInStoreRepository(this.answers);

  final List<Either<NetworkExceptions, List<ProductReel>>> answers;
  final List<String> requested = [];

  @override
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  ) async {
    requested.add(productId);
    return answers.length > 1 ? answers.removeAt(0) : answers.single;
  }

  @override
  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  }) async => right((products: const <StoreProduct>[], nextCursor: null));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _product = ProductDetail(
  id: 'p-1',
  name: 'Linen shirt',
  description: 'Breathable linen.',
  images: [],
  price: Money(amount: 2499, currency: 'NPR'),
  rating: 4.5,
  reviewCount: 12,
  vendorId: 'v-1',
  vendorName: 'Mint Studio',
  vendorAvatarUrl: '',
  isInStock: true,
  variants: [],
  specifications: {},
  shippingInfo: '',
  isSaved: false,
  isInCart: false,
);

const _reels = [
  ProductReel(
    id: 'r-1',
    permalink: 'https://www.youtube.com/shorts/abc123',
    creatorName: 'Asha Rai',
  ),
  ProductReel(
    id: 'r-2',
    permalink: 'https://www.instagram.com/reel/xyz/',
    creatorName: 'Mint Studio',
  ),
];

void main() {
  late _MockDiscoveryRepository discovery;
  late _MockReviewsRepository reviews;

  setUp(() {
    discovery = _MockDiscoveryRepository();
    reviews = _MockReviewsRepository();
    when(
      () => discovery.getProductDetail('p-1'),
    ).thenAnswer((_) async => right(_product));
    when(() => reviews.getReviewSummary('p-1')).thenAnswer(
      (_) async => right(
        const ReviewSummary(
          averageRating: 4.5,
          totalReviews: 12,
          ratingDistribution: {},
        ),
      ),
    );
    when(
      () => reviews.getProductReviews('p-1', cursor: any(named: 'cursor')),
    ).thenAnswer(
      (_) async => right(
        const PagedResult<Review>(
          items: [],
          totalCount: 12,
          pageSize: 20,
          hasMore: false,
        ),
      ),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    _FakeInStoreRepository inStore,
  ) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: inStoreProductLocation(
        productId: 'p-1',
        storeId: 's-1',
        code: 'ABCD2345',
        storeName: 'Mint Thamel',
        storeCity: 'Kathmandu',
      ),
      routes: [
        GoRoute(
          path: RouteNames.inStoreProduct,
          builder: (_, state) {
            final query = state.uri.queryParameters;
            return InStoreProductScreen(
              productId: state.pathParameters['productId']!,
              storeId: query[InStoreQuery.storeId],
              code: query[InStoreQuery.code],
              storeName: query[InStoreQuery.store],
              storeCity: query[InStoreQuery.city],
            );
          },
        ),
        GoRoute(
          path: RouteNames.reelDetail,
          builder: (_, state) =>
              Scaffold(body: Text('reel ${state.pathParameters['reelId']}')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(discovery),
          reviewsRepositoryProvider.overrideWithValue(reviews),
          inStoreRepositoryProvider.overrideWithValue(inStore),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the store, product, reels and reviews summary', (
    tester,
  ) async {
    final inStore = _FakeInStoreRepository([right(List.of(_reels))]);

    await pump(tester, inStore);

    expect(find.text('In Mint Thamel, Kathmandu'), findsOneWidget);
    expect(find.text('Linen shirt'), findsOneWidget);
    expect(find.text('Rs 2,499.00'), findsOneWidget);
    expect(find.text(ProductReelsSection.title), findsOneWidget);
    expect(find.byKey(const ValueKey('product-reel-r-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('product-reel-r-2')), findsOneWidget);
    expect(find.text('Asha Rai'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('12 reviews'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
    expect(find.text('Save for later'), findsOneWidget);
    expect(inStore.requested, ['p-1']);
  });

  testWidgets('a reel tile opens StyleMint reel screen', (tester) async {
    await pump(tester, _FakeInStoreRepository([right(List.of(_reels))]));

    await tester.tap(find.byKey(const ValueKey('product-reel-r-2')));
    await tester.pumpAndSettle();

    expect(find.text('reel r-2'), findsOneWidget);
  });

  testWidgets('no reels shows a quiet empty line', (tester) async {
    await pump(tester, _FakeInStoreRepository([right(const [])]));

    expect(find.text(ProductReelsSection.emptyMessage), findsOneWidget);
    expect(find.byKey(const ValueKey('product-reel-r-1')), findsNothing);
  });

  testWidgets('a failed reels load can be retried', (tester) async {
    final inStore = _FakeInStoreRepository([
      left(const NetworkExceptions.serverUnavailable()),
      right(List.of(_reels)),
    ]);

    await pump(tester, inStore);

    expect(find.text(ProductReelsSection.failedMessage), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('product-reel-r-1')), findsOneWidget);
    expect(inStore.requested, ['p-1', 'p-1']);
  });

  test('the banner reads "In {store}, {city}"', () {
    expect(
      InStoreProductScreen.storeBannerText(
        storeName: 'Mint Thamel',
        storeCity: 'Kathmandu',
      ),
      'In Mint Thamel, Kathmandu',
    );
    expect(
      InStoreProductScreen.storeBannerText(storeName: 'Mint Thamel'),
      'In Mint Thamel',
    );
    expect(InStoreProductScreen.storeBannerText(), 'Scanned in store');
  });
}
