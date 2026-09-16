import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/screens/brand_storefront_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_follow_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/storefront_links.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_reel_grid.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../reels/fake_reels_repository.dart';
import '../storefront/storefront_test_support.dart';
import '../storefront/storefront_widget_harness.dart';

void main() {
  late FakeBrandStorefrontRepository brands;
  late FakeStorefrontRepository storefront;
  late FakeMallCatalogRepository catalog;
  late FakeExternalActions external;

  setUp(() {
    brands = FakeBrandStorefrontRepository();
    storefront = FakeStorefrontRepository();
    catalog = FakeMallCatalogRepository();
    external = FakeExternalActions();
  });

  Future<void> pump(
    WidgetTester tester, {
    double width = 390,
    double height = 1600,
    double textScale = 1,
  }) => pumpStorefrontApp(
    tester,
    initialLocation: StorefrontLinks.brand(vendorId),
    storefrontRoute: GoRoute(
      path: RouteNames.brandStorefront,
      builder: (_, state) => BrandStorefrontScreen(
        vendorAccountId: state.pathParameters['vendorAccountId']!,
      ),
    ),
    width: width,
    height: height,
    textScale: textScale,
    scope: (app) => ProviderScope(
      overrides: [
        brandStorefrontRepositoryProvider.overrideWithValue(brands),
        storefrontRepositoryProvider.overrideWithValue(storefront),
        mallCatalogRepositoryProvider.overrideWithValue(catalog),
        storefrontExternalActionsProvider.overrideWithValue(external),
        followApiProvider.overrideWithValue(FollowApi(ApiClient(dio: Dio()))),
        // Home's reels rail opens the window, which resolves playback here.
        reelsRepositoryProvider.overrideWithValue(FakeReelsRepository()),
      ],
      child: app,
    ),
  );

  CatalogPage<CatalogProduct> products(List<CatalogProduct> items) =>
      CatalogPage(items: items, totalCount: items.length);

  testWidgets('hero reads as the official flagship', (tester) async {
    await pump(tester);

    expect(find.textContaining('Mint Goods'), findsWidgets);
    expect(find.text('VERIFIED · OFFICIAL STORE'), findsOneWidget);
    expect(find.text('Hand-made in the hills'), findsOneWidget);
    expect(
      find.textContaining('Kathmandu, Nepal · Since 2019'),
      findsOneWidget,
    );
    expect(find.text('Follow'), findsOneWidget);
    for (final label in [
      'Home',
      'Shop All',
      'New',
      'Reels',
      'Collections',
      'About',
    ]) {
      expect(storefrontTab(label), findsOneWidget);
    }

    await tester.tap(find.byTooltip('Share Mint Goods').first);
    await tester.pump();
    expect(
      external.shared.single,
      contains('https://stylemint.voyageritnepal.com/brands/$vendorId'),
    );
  });

  testWidgets('home has new arrivals, best sellers, reels and the story', (
    tester,
  ) async {
    catalog.products = (query) => right(
      products(
        query.sort == ProductSort.bestselling
            ? [catalogProduct('b1')]
            : [catalogProduct('n1'), catalogProduct('n2')],
      ),
    );
    storefront
      ..vendorReels = right(page([aiReel]))
      ..collections[CollectionKind.brandCollection] = right(
        page([
          sampleCollection('monsoon', kind: CollectionKind.brandCollection),
        ]),
      );
    // Tall enough that every Home section is laid out.
    await pump(tester, height: 3200);

    expect(find.text('New arrivals'), findsOneWidget);
    expect(find.text('Best sellers'), findsOneWidget);
    expect(find.text('Featured collection'), findsOneWidget);
    expect(find.text('Styled in reels'), findsOneWidget);
    expect(
      find.textContaining('Since 1998 we have woven dhaka by hand.'),
      findsOneWidget,
    );
    expect(
      catalog.queries.map((q) => (q.vendorAccountId, q.sort)),
      containsAll([
        (vendorId, ProductSort.newest),
        (vendorId, ProductSort.bestselling),
      ]),
    );
  });

  testWidgets('the home reels rail plays in the window, not the pager', (
    tester,
  ) async {
    addTearDown(ReelWindow.debugResetOpenState);
    storefront.vendorReels = right(page([aiReel]));
    await pump(tester, height: 3200);

    final card = find.byType(MallReelCard).first;
    await tester.ensureVisible(card);
    await tester.pump();
    await tester.tap(card, warnIfMissed: false);
    await settleStorefront(tester);

    expect(find.byType(ReelWindow), findsOneWidget);
    // The disclosure follows the reel into the window's chrome.
    expect(find.byKey(ReelWindow.aiLabelKey), findsOneWidget);
    expect(find.text('reel reel-ai'), findsNothing);
  });

  testWidgets('shop all sorts and filters through the filter sheet', (
    tester,
  ) async {
    catalog.products = (query) => right(
      products(query.inStock ? const [] : [catalogProduct('p1')]),
    );
    await pump(tester);
    await tapStorefrontTab(tester, 'Shop All');

    expect(find.text('Newest'), findsOneWidget);
    await tester.ensureVisible(find.text('Price ↑'));
    await tester.pump();
    await tester.tap(find.text('Price ↑'));
    await settleStorefront(tester);
    expect(catalog.queries.last.sort, ProductSort.priceAsc);
    expect(catalog.queries.last.vendorAccountId, vendorId);

    await tester.tap(find.text('Filter'));
    await settleStorefront(tester);
    expect(find.text('In stock only'), findsOneWidget);
    expect(find.text('On sale'), findsOneWidget);
    // Size and colour aren't supported by the listing, so they aren't faked.
    expect(find.textContaining('Size'), findsNothing);
    expect(find.textContaining('Colo'), findsNothing);

    await tester.tap(find.text('In stock only'));
    await tester.pump();
    await tester.tap(find.text('Show results'));
    await settleStorefront(tester);

    final query = catalog.queries.last;
    expect(query.inStock, isTrue);
    expect(query.sort, ProductSort.priceAsc);
    expect(query.vendorAccountId, vendorId);
    expect(find.text('Filter · 1'), findsOneWidget);
    expect(find.text('No pieces match these filters'), findsOneWidget);

    await tester.tap(find.text('Clear filters'));
    await settleStorefront(tester);
    expect(catalog.queries.last.inStock, isFalse);
    expect(find.byType(MallProductTile), findsOneWidget);
  });

  testWidgets('new and reels tabs show products and labelled reels', (
    tester,
  ) async {
    catalog.products = (_) => right(products([catalogProduct('n1')]));
    storefront.vendorReels = right(page([aiReel, humanReel]));
    await pump(tester);

    await tapStorefrontTab(tester, 'New');
    expect(find.text('New arrivals'), findsOneWidget);
    expect(find.byType(MallProductTile), findsOneWidget);

    await tapStorefrontTab(tester, 'Reels');
    expect(find.byType(StorefrontReelTile), findsNWidgets(2));
    expect(find.text('AI-generated'), findsOneWidget);
  });

  testWidgets('every tab has a polished empty state', (tester) async {
    await pump(tester);

    expect(find.text('The flagship is being styled'), findsOneWidget);
    await tapStorefrontTab(tester, 'Shop All');
    expect(find.text('No products yet'), findsOneWidget);
    await tapStorefrontTab(tester, 'New');
    expect(find.text('No new arrivals yet'), findsOneWidget);
    await tapStorefrontTab(tester, 'Reels');
    expect(find.text('No creator reels yet'), findsOneWidget);
    await tapStorefrontTab(tester, 'Collections');
    expect(find.text('No collections yet'), findsOneWidget);
  });

  testWidgets('about tells the story, returns, support and trust', (
    tester,
  ) async {
    await pump(tester);
    await tapStorefrontTab(tester, 'About');

    expect(find.text('OUR STORY'), findsOneWidget);
    expect(
      find.text('“Since 1998 we have woven dhaka by hand.”'),
      findsOneWidget,
    );
    expect(
      find.text('Every piece is made in Pokhara by the same families.'),
      findsOneWidget,
    );
    expect(find.text('Kathmandu, Nepal'), findsOneWidget);
    expect(find.text('2019'), findsOneWidget);
    expect(find.text('30-day free returns on unworn pieces'), findsOneWidget);
    for (final point in [
      'Authentic products',
      'Verified seller',
      'Secure checkout',
      'Easy returns',
    ]) {
      expect(find.text(point), findsOneWidget);
    }

    await tester.ensureVisible(find.text('Customer support'));
    await tester.tap(find.text('Customer support'));
    await tester.pump();
    expect(external.opened, [Uri.parse('https://help.mint.example/contact')]);
  });

  testWidgets('about hides a support link that is not https', (tester) async {
    brands.brand = right(
      const PublicBrandProfile(
        accountId: vendorId,
        name: 'Mint Goods',
        supportUrl: 'http://help.mint.example',
      ),
    );
    await pump(tester);
    await tapStorefrontTab(tester, 'About');

    expect(find.text('Customer support'), findsNothing);
    expect(
      find.text("Mint Goods hasn't shared its story yet."),
      findsOneWidget,
    );
    expect(find.text('Approved seller'), findsOneWidget);
  });

  testWidgets('404 shows that the brand is not available', (tester) async {
    brands.brand = left(const NetworkExceptions.notFound());
    await pump(tester);
    expect(find.text("This brand isn't available"), findsOneWidget);
  });

  testWidgets('no overflow at 320dp with text ×1.3 on any tab', (tester) async {
    brands.brand = right(
      const PublicBrandProfile(
        accountId: vendorId,
        name: 'Kathmandu Atelier of Hand Loomed Goods',
        tagline:
            'Hand-loomed Himalayan textiles, cut for the city and the hills.',
        brandStory:
            'Since 2019 we have worked with weaving families across the '
            'valley. Every piece is made by hand.',
        originCity: 'Lalitpur',
        originCountryCode: 'NP',
        foundedYear: 2019,
        isVerified: true,
        returnPolicySummary: '30-day free returns on unworn pieces with tags',
        supportUrl: 'https://help.kathmandu-atelier.example/contact',
      ),
    );
    storefront
      ..follow = right(
        const StorefrontFollowSummary(followers: 10, isFollowedByViewer: true),
      )
      ..vendorReels = right(page([aiReel, humanReel]))
      ..collections[CollectionKind.brandCollection] = right(
        page([sampleCollection('edit', kind: CollectionKind.brandCollection)]),
      );
    catalog.products = (_) => right(
      products([catalogProduct('p1'), catalogProduct('p2', price: 1250000)]),
    );

    await pump(tester, width: 320, height: 2600, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.text('Following'), findsOneWidget);

    for (final tab in [
      'Shop All',
      'New',
      'Reels',
      'Collections',
      'About',
      'Home',
    ]) {
      await tapStorefrontTab(tester, tab);
      expect(tester.takeException(), isNull, reason: '$tab tab');
    }

    await tapStorefrontTab(tester, 'Shop All');
    await tester.tap(find.text('Filter'));
    await settleStorefront(tester);
    expect(tester.takeException(), isNull, reason: 'filter sheet');
  });
}
