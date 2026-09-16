import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_zones.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../mall_test_support.dart';

const MallStrings _strings = MallStrings.english;

const HomeTrustSection _trust = HomeTrustSection(id: 'trust');

HomeProductsSection _products(String id, List<HomeProduct> items) =>
    HomeProductsSection(id: id, title: id, items: items);

void main() {
  group('spotlightPickOf', () {
    test('money off wins, and it is the biggest one', () {
      final pick = spotlightPickOf([
        homeProduct('a', was: rs(2000)),
        homeProduct('b', was: rs(6000)),
        homeProduct('c'),
      ]);
      expect(pick?.product.id, 'b');
      expect(pick?.reason, MallSpotlightReason.biggestSaving);
      expect(
        mallSpotlightEyebrow(pick?.reason, _strings),
        _strings.biggestSaving,
      );
    });

    test('with nothing discounted, the soonest real deadline leads', () {
      final pick = spotlightPickOf([
        homeProduct('a', saleEndsUtc: DateTime.utc(2026, 9, 20)),
        homeProduct('b', saleEndsUtc: DateTime.utc(2026, 9, 17)),
      ]);
      expect(pick?.product.id, 'b');
      expect(pick?.reason, MallSpotlightReason.endingSoonest);
    });

    test('then the most reviewed item that also carries a rating', () {
      final pick = spotlightPickOf([
        homeProduct('a', rating: 4.9, reviewCount: 2),
        homeProduct('b', rating: 4.1, reviewCount: 40),
        // A count with no rating behind it is not a claim.
        homeProduct('c', reviewCount: 400),
      ]);
      expect(pick?.product.id, 'b');
      expect(pick?.reason, MallSpotlightReason.bestReviewed);
    });

    test('then whatever the server flagged new', () {
      final pick = spotlightPickOf([
        homeProduct('a'),
        HomeProduct(id: 'b', name: 'New thing', price: rs(900), isNew: true),
      ]);
      expect(pick?.product.id, 'b');
      expect(pick?.reason, MallSpotlightReason.justArrived);
    });

    test('a block with nothing to say still leads, and claims nothing', () {
      final pick = spotlightPickOf([homeProduct('a'), homeProduct('b')]);
      expect(pick?.product.id, 'a');
      expect(pick?.reason, isNull);
      expect(mallSpotlightEyebrow(pick?.reason, _strings), isNull);
    });

    test('no items, no spotlight', () {
      expect(spotlightPickOf(const []), isNull);
    });
  });

  group('spotlightSectionIndex', () {
    test("the first discovery products block gets the page's one", () {
      final sections = [
        const HomeCampaignsSection(id: 'hero', items: []),
        _products('picks', [homeProduct('a')]),
        _products('more', [homeProduct('b')]),
      ];
      expect(spotlightSectionIndex(sections), 1);
    });

    test('the drop plate is skipped: it is already the loud one', () {
      final sections = [
        _products('deals', [
          homeProduct('a', was: rs(4000)),
          homeProduct('b', was: rs(4000)),
        ]),
        _products('picks', [homeProduct('c')]),
      ];
      expect(isDropBlock(sections.first.items), isTrue);
      expect(spotlightSectionIndex(sections), 1);
    });

    test('a page with no products block gets none', () {
      expect(
        spotlightSectionIndex(const [
          HomeCampaignsSection(id: 'hero', items: []),
          _trust,
        ]),
        isNull,
      );
    });
  });

  group('mallTickerWords', () {
    test("interleaves the page's brands, edits and categories", () {
      expect(
        mallTickerWords(sampleHome().sections),
        const [
          'Stylemint Nepal',
          'Minimal workwear',
          'Fashion',
          'Monsoon layers',
          'Home',
          'Gold hour',
          'Tech',
          'Beauty',
        ],
      );
    });

    test('drops repeats and blanks, and stops at the cap', () {
      final words = mallTickerWords(const [
        HomeBrandsSection(
          id: 'b',
          items: [
            HomeBrand(vendorAccountId: 'v1', name: 'Loom'),
            HomeBrand(vendorAccountId: 'v2', name: '  '),
            HomeBrand(vendorAccountId: 'v3', name: 'loom'),
            HomeBrand(vendorAccountId: 'v4', name: 'Atelier'),
          ],
        ),
      ], max: 2);
      expect(words, const ['Loom', 'Atelier']);
    });

    test('a page with no names has no band', () {
      expect(mallTickerWords(const [_trust]), isEmpty);
      expect(mallTickerWords(const []), isEmpty);
    });
  });

  group('tickerSectionIndex', () {
    test('hangs under the first block after the stage', () {
      expect(tickerSectionIndex(sampleHome().sections), 1);
    });

    test('never under the last thing on the page', () {
      expect(
        tickerSectionIndex([
          const HomeCampaignsSection(id: 'hero', items: []),
          _products('picks', [homeProduct('a')]),
        ]),
        isNull,
      );
      expect(
        tickerSectionIndex(const [
          HomeCampaignsSection(id: 'hero', items: []),
          _trust,
        ]),
        isNull,
      );
    });
  });

  group('the page', () {
    Future<void> pump(WidgetTester tester, {double textScale = 1}) =>
        pumpMallApp(
          tester,
          location: '/home',
          routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ],
          overrides: [
            mallHomeRepositoryProvider.overrideWithValue(
              FakeMallHomeRepository([right(sampleHome())]),
            ),
            mallViewerSignedInProvider.overrideWithValue(false),
            mallClockProvider.overrideWithValue(mallTestNow),
          ],
          height: 6000,
          textScale: textScale,
        );

    testWidgets('carries one spotlight and one directory band', (tester) async {
      await pump(tester);
      expect(find.byType(MallSpotlight), findsOneWidget);
      expect(find.byType(MallTicker), findsOneWidget);
      // Reviews are the only claim these items support.
      expect(find.text('BEST REVIEWED HERE'), findsOneWidget);
      expect(find.text('STYLEMINT NEPAL'), findsOneWidget);
    });

    testWidgets('the spotlit product is not repeated in its own rail', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Linen co-ord set'), findsOneWidget);
    });

    testWidgets('every product on the page can be bought from', (
      tester,
    ) async {
      await pump(tester);
      // Two rails of two, less the spotlit item, plus the spotlight's own.
      expect(find.byKey(MallQuickAdd.tapKey), findsNWidgets(4));
    });

    testWidgets('the page fits at 320dp with large text', (tester) async {
      await pumpMallApp(
        tester,
        location: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
        ],
        overrides: [
          mallHomeRepositoryProvider.overrideWithValue(
            FakeMallHomeRepository([right(sampleHome())]),
          ),
          mallViewerSignedInProvider.overrideWithValue(false),
          mallClockProvider.overrideWithValue(mallTestNow),
        ],
        width: 320,
        height: 8000,
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(MallSpotlight), findsOneWidget);
    });
  });
}
