import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/adaptive_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';
import 'package:stylemint_mobile_frontend/features/settings/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// A contract JSON fixture from `fixtures/`.
Map<String, dynamic> loadMallFixture(String name) =>
    jsonDecode(
          File(
            'test/features/customer/mall_home/fixtures/$name',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

Money rs(double amount) => Money(amount: amount, currency: 'NPR');

/// 13:00 UTC is 18:45 in Kathmandu: "Good evening".
DateTime mallTestNow() => DateTime.utc(2026, 9, 15, 13);

// ── Fakes ──────────────────────────────────────────────────────────────────

class FakeMallHomeRepository implements MallHomeRepository {
  FakeMallHomeRepository(List<Either<NetworkExceptions, MallHome>> results)
    : _results = [...results];

  final List<Either<NetworkExceptions, MallHome>> _results;
  int homeCalls = 0;

  /// When set, `getHome` waits for it.
  Completer<void>? gate;
  final List<String> recorded = [];

  @override
  Future<Either<NetworkExceptions, MallHome>> getHome() async {
    homeCalls++;
    await gate?.future;
    return _results.length > 1 ? _results.removeAt(0) : _results.first;
  }

  @override
  Future<Either<NetworkExceptions, Unit>> recordRecentlyViewed(
    String productId,
  ) async {
    recorded.add(productId);
    return right(unit);
  }
}

/// The adaptive storefront, switched off. Every Mall test gets this unless
/// it overrides the provider itself, so a page under test never reaches for
/// a real layout — and a test that says nothing about personalisation is
/// testing the fixed home, which is exactly what it means to.
class InertStorefrontRepository implements AdaptiveStorefrontRepository {
  @override
  Future<StorefrontLayout> getLayout() async => StorefrontLayout.none;

  @override
  Future<void> trackInteraction(FeedSignal signal) async {}
}

/// A Memory Vault that answers "not paused" and never reaches the network.
class InertMemoryVaultRepository implements MemoryVaultRepository {
  @override
  Future<Either<NetworkExceptions, bool>> isPaused() async => right(false);

  @override
  Future<Either<NetworkExceptions, MemoryVault>> load() async =>
      right(const MemoryVault(paused: false, memories: []));

  @override
  Future<Either<NetworkExceptions, CompanionMemory>> correct(
    String memoryId,
    String content,
  ) => throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> forget(String memoryId) =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> forgetAll() =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, Unit>> setPaused({required bool paused}) =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, String>> export() =>
      throw UnimplementedError();

  @override
  Future<Either<NetworkExceptions, int>> importPortableTwin(
    String bundleJson,
  ) => throw UnimplementedError();
}

typedef ProductsCall = ({ProductListingQuery query, String? cursor});
typedef CollectionCall = ({String slug, String? cursor});

class FakeMallCatalogRepository implements MallCatalogRepository {
  FakeMallCatalogRepository({this.onProducts, this.onCollection});

  Either<NetworkExceptions, CatalogPage<CatalogProduct>> Function(
    ProductsCall call,
  )?
  onProducts;
  Either<NetworkExceptions, CollectionDetail> Function(CollectionCall call)?
  onCollection;

  final List<ProductsCall> productCalls = [];
  final List<CollectionCall> collectionCalls = [];

  /// Held by the next products call only.
  Completer<void>? nextProductsGate;

  @override
  Future<Either<NetworkExceptions, CatalogPage<CatalogProduct>>> getProducts(
    ProductListingQuery query, {
    String? cursor,
    int pageSize = 20,
  }) async {
    final call = (query: query, cursor: cursor);
    productCalls.add(call);
    final gate = nextProductsGate;
    nextProductsGate = null;
    await gate?.future;
    return onProducts!(call);
  }

  @override
  Future<Either<NetworkExceptions, CollectionDetail>> getCollection(
    String slug, {
    String? cursor,
    int pageSize = 20,
  }) async {
    final call = (slug: slug, cursor: cursor);
    collectionCalls.add(call);
    return onCollection!(call);
  }
}

// ── Builders (no image URLs: widget tests have no network) ─────────────────

CatalogProduct catalogProduct(String id, {String? name, double price = 1200}) =>
    CatalogProduct(id: id, name: name ?? 'Product $id', price: rs(price));

CatalogPage<CatalogProduct> productPage(
  Iterable<String> ids, {
  String? cursor,
  int? total,
}) => CatalogPage(
  items: [for (final id in ids) catalogProduct(id)],
  nextCursor: cursor,
  totalCount: total,
);

HomeProduct homeProduct(
  String id, {
  String? name,
  Money? was,
  double? rating,
  int reviewCount = 0,
  DateTime? saleEndsUtc,
  String? imageUrl,
  bool isLowStock = false,
}) => HomeProduct(
  id: id,
  name: name ?? 'Product $id',
  price: rs(1500),
  compareAtPrice: was,
  brandName: 'Kathmandu Atelier',
  imageUrl: imageUrl,
  rating: rating,
  reviewCount: reviewCount,
  isOnSale: was != null,
  saleEndsUtc: saleEndsUtc,
  isLowStock: isLowStock,
  isInStock: true,
);

/// 4h 30m after [mallTestNow], and the same Kathmandu day: a live countdown
/// on the drop plate and "Ends today" on the cards.
DateTime mallTestSaleEnd() => DateTime.utc(2026, 9, 15, 17, 30);

/// A signed-in page with one section of every kind.
MallHome sampleHome({String? firstName = 'Sumendra'}) => MallHome(
  greetingFirstName: firstName,
  personalized: firstName != null,
  sections: [
    const HomeCampaignsSection(
      id: 'hero',
      items: [
        HomeCampaign(
          id: 'c-1',
          title: 'Dubai Evening Edit',
          eyebrow: 'Limited drop',
          subtitle: 'Gold-hour tailoring',
          ctas: [
            HomeCampaignCta(
              label: 'Shop the edit',
              targetKind: HomeCtaTargetKind.collection,
              targetValue: 'dubai-evening-edit',
            ),
            HomeCampaignCta(
              label: 'Watch reels',
              targetKind: HomeCtaTargetKind.reels,
            ),
          ],
        ),
      ],
    ),
    HomeProductsSection(
      id: 'picked-for-you',
      eyebrow: 'For you',
      title: 'Picked for you',
      reason: 'Because you follow Stylemint Nepal',
      seeAll: const HomeSeeAll(
        target: HomeSeeAllTarget.productList,
        params: {'sort': 'bestselling'},
      ),
      items: [
        homeProduct(
          'p-1',
          name: 'Linen co-ord set',
          rating: 4.6,
          reviewCount: 12,
        ),
        homeProduct('p-2', isLowStock: true),
      ],
    ),
    const HomeReelsSection(
      id: 'shoppable-reels',
      title: 'Shoppable reels',
      items: [
        HomeReel(
          id: 'r-ai',
          creatorName: 'Priya',
          taggedProductCount: 2,
          isAiGenerated: true,
          likeCount: 12,
        ),
        HomeReel(id: 'r-human', creatorName: 'Aarav', likeCount: 1),
      ],
    ),
    HomeProductsSection(
      id: 'deals',
      eyebrow: 'Limited time',
      title: 'Deals',
      seeAll: const HomeSeeAll(
        target: HomeSeeAllTarget.productList,
        params: {'onSale': 'true'},
      ),
      items: [
        homeProduct(
          'p-3',
          name: 'Silk scarf',
          was: rs(2000),
          saleEndsUtc: mallTestSaleEnd(),
          imageUrl: 'https://example.com/deal-promo.jpg',
        ),
        homeProduct('p-4', name: 'Wool wrap', was: rs(3000)),
      ],
    ),
    const HomeCategoriesSection(
      id: 'categories',
      title: 'Shop by category',
      items: [
        HomeCategory(id: 'cat-1', slug: 'fashion', name: 'Fashion'),
        HomeCategory(id: 'cat-2', slug: 'home', name: 'Home'),
        HomeCategory(id: 'cat-3', slug: 'tech', name: 'Tech'),
        HomeCategory(id: 'cat-4', slug: 'beauty', name: 'Beauty'),
      ],
    ),
    const HomeBrandsSection(
      id: 'brands',
      title: 'Brands we love',
      items: [
        HomeBrand(
          vendorAccountId: 'v-1',
          name: 'Stylemint Nepal',
          isVerified: true,
          tagline: 'Made in the hills',
        ),
      ],
    ),
    const HomeCreatorsSection(
      id: 'creators',
      title: 'Creators to follow',
      items: [
        HomeCreator(
          accountId: 'a-1',
          displayName: 'Sumi Rai',
          handle: 'sumi',
          styleTags: ['Minimal'],
          followerCount: 120,
        ),
      ],
    ),
    const HomeCollectionsSection(
      id: 'collections',
      title: 'The edits',
      items: [
        HomeCollection(
          slug: 'minimal-workwear',
          title: 'Minimal workwear',
          itemCount: 8,
        ),
        HomeCollection(
          slug: 'monsoon-layers',
          title: 'Monsoon layers',
          itemCount: 12,
        ),
        HomeCollection(
          slug: 'gold-hour',
          title: 'Gold hour',
          itemCount: 6,
        ),
      ],
    ),
    const HomeTrustSection(id: 'trust'),
  ],
);

// ── Harness ────────────────────────────────────────────────────────────────

/// Pumps a router app at [location] in the dark theme with animations
/// disabled. [routes] come first; stub pages print where navigation went
/// (`product:<id>`, `listing:<query>`, …) for any path they don't define.
Future<void> pumpMallApp(
  WidgetTester tester, {
  required String location,
  required List<GoRoute> routes,
  List<Object> overrides = const [],
  AdaptiveStorefrontRepository? storefront,
  MemoryVaultRepository? vault,
  double width = 390,
  double? height,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, height ?? (width <= 320 ? 568 : 844))
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  GoRoute stub(String path, String Function(GoRouterState state) label) =>
      GoRoute(
        path: path,
        builder: (_, state) =>
            Scaffold(body: Center(child: Text(label(state)))),
      );
  final defined = {for (final route in routes) route.path};
  final stubs = [
    stub(
      '/product/:productId',
      (s) => 'product:${s.pathParameters['productId']}',
    ),
    stub('/reels/:reelId', (s) => 'reel:${s.pathParameters['reelId']}'),
    stub(
      '/creator-profile/:accountId',
      (s) => 'creator:${s.pathParameters['accountId']}',
    ),
    stub('/products', (s) => 'listing:${s.uri.query}'),
    stub('/collections/:slug', (s) => 'collection:${s.pathParameters['slug']}'),
    stub('/search', (_) => 'discover'),
    stub('/discover/creators', (_) => 'creators'),
    stub('/home', (_) => 'home'),
  ].where((route) => !defined.contains(route.path));

  final router = GoRouter(
    initialLocation: location,
    routes: [...routes, ...stubs],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      // Riverpod refuses a provider overridden twice, so the adaptive
      // storefront is given here and nowhere else: [storefront] and [vault]
      // for a test that has something to say about personalisation, and the
      // inert pair — which is the fixed home — for every other Mall test.
      overrides: <Object>[
        adaptiveStorefrontRepositoryProvider.overrideWithValue(
          storefront ?? InertStorefrontRepository(),
        ),
        memoryVaultRepositoryProvider.overrideWithValue(
          vault ?? InertMemoryVaultRepository(),
        ),
        ...overrides,
      ].cast(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Lets a pushed page or sheet finish its transition.
Future<void> settleTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}
