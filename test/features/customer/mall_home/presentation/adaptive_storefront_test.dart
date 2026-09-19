import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/storefront_layout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/feed_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/storefront_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/adaptive_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/adaptive_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/feed_signal_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/screens/home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/storefront_personalizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/entities/companion_memory.dart';
import 'package:stylemint_mobile_frontend/features/settings/domain/repositories/memory_vault_repository.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';

import '../../reels/fake_reels_repository.dart';
import '../mall_test_support.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakeStorefrontRepository implements AdaptiveStorefrontRepository {
  _FakeStorefrontRepository({this.layout = StorefrontLayout.none});

  StorefrontLayout layout;
  int layoutCalls = 0;
  final List<FeedSignal> tracked = [];

  @override
  Future<StorefrontLayout> getLayout() async {
    layoutCalls++;
    return layout;
  }

  @override
  Future<void> trackInteraction(FeedSignal signal) async => tracked.add(signal);
}

/// Only [isPaused] is ever reached from the storefront.
class _FakeVaultRepository implements MemoryVaultRepository {
  _FakeVaultRepository({this.paused = false, this.fails = false});

  bool paused;
  bool fails;
  int pausedCalls = 0;

  @override
  Future<Either<NetworkExceptions, bool>> isPaused() async {
    pausedCalls++;
    return fails
        ? left(const NetworkExceptions.serverUnavailable())
        : right(paused);
  }

  @override
  Future<Either<NetworkExceptions, MemoryVault>> load() async =>
      right(MemoryVault(paused: paused, memories: const []));

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

// ── Builders ───────────────────────────────────────────────────────────────

HomeSeeAll _categorySeeAll(String id) => HomeSeeAll(
  target: HomeSeeAllTarget.category,
  params: {'categoryId': id},
);

HomeProductsSection _products(
  String id, {
  String? categoryId,
  String? reason,
}) => HomeProductsSection(
  id: id,
  title: id,
  reason: reason,
  seeAll: categoryId == null ? null : _categorySeeAll(categoryId),
  items: const [],
);

MallHome _home(List<HomeSection> sections) => MallHome(sections: sections);

StorefrontLayout _layout(List<(String, String)> ranked) => StorefrontLayout(
  isPersonalized: true,
  rankedCategories: [
    for (var i = 0; i < ranked.length; i++)
      StorefrontCategoryRank(
        categoryId: ranked[i].$1,
        label: ranked[i].$2,
        recentPurchaseCount: ranked.length - i,
      ),
  ],
);

List<String> _ids(MallHome home) => [
  for (final section in home.sections) section.id,
];

void main() {
  group('storefront-layout contract', () {
    test('reads the camelCased record the controller returns', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': [
          {
            'categoryId': 'cat-2',
            'label': 'Dresses',
            'recentPurchaseCount': 7,
          },
        ],
        'isPersonalized': true,
      });
      expect(layout.hasRanking, isTrue);
      expect(layout.rankedCategories.single.categoryId, 'cat-2');
      expect(layout.rankedCategories.single.label, 'Dresses');
      expect(layout.rankedCategories.single.recentPurchaseCount, 7);
    });

    test('reads the PascalCased shape of the same record', () {
      final layout = storefrontLayoutFromJson({
        'RankedCategories': [
          {'CategoryId': 'cat-2', 'Label': 'Dresses', 'RecentPurchaseCount': 7},
        ],
        'IsPersonalized': true,
      });
      expect(layout.rankedCategories.single.categoryId, 'cat-2');
      expect(layout.rankedCategories.single.recentPurchaseCount, 7);
    });

    test('a new customer (empty, not personalised) reads as none', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': <dynamic>[],
        'isPersonalized': false,
      });
      expect(layout.hasRanking, isFalse);
      expect(layout.rankedCategories, isEmpty);
    });

    test('personalised but empty, and junk, both read as none', () {
      expect(
        storefrontLayoutFromJson({
          'rankedCategories': <dynamic>[],
          'isPersonalized': true,
        }).hasRanking,
        isFalse,
      );
      expect(storefrontLayoutFromJson({'oops': 1}).hasRanking, isFalse);
    });

    test('a ranking entry with no category id is dropped', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': [
          {'categoryId': '', 'label': 'Nothing'},
          {'categoryId': 'cat-1', 'label': 'Shoes'},
        ],
        'isPersonalized': true,
      });
      expect(layout.rankedCategories.map((c) => c.categoryId), ['cat-1']);
    });
  });

  group('applyStorefrontLayout', () {
    test('promotes ranked sections, best first, inside the movable band', () {
      final home = _home([
        const HomeCampaignsSection(id: 'hero', items: []),
        _products('editorial'),
        _products('tech', categoryId: 'cat-3'),
        _products('shoes', categoryId: 'cat-1'),
        const HomeTrustSection(id: 'trust'),
      ]);

      final adapted = applyStorefrontLayout(
        home,
        _layout([('cat-1', 'Shoes'), ('cat-3', 'Tech')]),
      );

      expect(_ids(adapted), [
        'hero', // the stage stays the stage
        'shoes',
        'tech',
        'editorial',
        'trust', // and the trust strip stays last
      ]);
    });

    test('keeps the server order among sections it cannot rank', () {
      final home = _home([
        _products('a'),
        _products('b'),
        _products('shoes', categoryId: 'cat-1'),
        _products('c'),
      ]);
      final adapted = applyStorefrontLayout(home, _layout([('cat-1', 'S')]));
      expect(_ids(adapted), ['shoes', 'a', 'b', 'c']);
    });

    test('sorts the category mosaic by the ranking', () {
      final home = _home([
        const HomeCategoriesSection(
          id: 'categories',
          items: [
            HomeCategory(id: 'cat-1', name: 'Fashion'),
            HomeCategory(id: 'cat-2', name: 'Home'),
            HomeCategory(id: 'cat-3', name: 'Tech'),
          ],
        ),
        _products('filler'),
      ]);
      final adapted = applyStorefrontLayout(
        home,
        _layout([('cat-3', 'Tech'), ('cat-1', 'Fashion')]),
      );
      final tiles = adapted.sections
          .whereType<HomeCategoriesSection>()
          .single
          .items;
      expect(tiles.map((c) => c.id), ['cat-3', 'cat-1', 'cat-2']);
    });

    test('matches ids case- and dash-insensitively', () {
      final home = _home([
        _products('plain'),
        _products(
          'shoes',
          categoryId: '{2B5F0D1A-0000-0000-0000-000000000001}',
        ),
      ]);
      final adapted = applyStorefrontLayout(
        home,
        _layout([('2b5f0d1a000000000000000000000001', 'Shoes')]),
      );
      expect(_ids(adapted).first, 'shoes');
    });

    test('explains a promotion, but never with a placeholder label', () {
      final ranked = applyStorefrontLayout(
        _home([_products('plain'), _products('shoes', categoryId: 'cat-1')]),
        _layout([('cat-1', 'Shoes')]),
      );
      expect(ranked.sections.first.reason, "Because you've been buying Shoes");

      final placeholder = applyStorefrontLayout(
        _home([_products('plain'), _products('shoes', categoryId: 'cat-1')]),
        _layout([('cat-1', 'Category')]),
      );
      expect(placeholder.sections.first.reason, isNull);
    });

    test("never overwrites the server's own reason line", () {
      final adapted = applyStorefrontLayout(
        _home([
          _products('plain'),
          _products('shoes', categoryId: 'cat-1', reason: 'Because you follow'),
        ]),
        _layout([('cat-1', 'Shoes')]),
      );
      expect(adapted.sections.first.reason, 'Because you follow');
    });

    test('an unusable layout leaves the page exactly as it was', () {
      final home = _home([
        const HomeCampaignsSection(id: 'hero', items: []),
        _products('shoes', categoryId: 'cat-1'),
        _products('plain'),
      ]);
      for (final layout in [
        StorefrontLayout.none,
        const StorefrontLayout(rankedCategories: [], isPersonalized: true),
        // A ranking for categories this page does not carry.
        _layout([('cat-99', 'Nothing here')]),
      ]) {
        final adapted = applyStorefrontLayout(home, layout);
        expect(_ids(adapted), _ids(home));
        expect(adapted.sections, orderedEquals(home.sections));
      }
    });

    test('drops nothing and invents nothing', () {
      final home = _home([
        const HomeCampaignsSection(id: 'hero', items: []),
        _products('a'),
        _products('shoes', categoryId: 'cat-1'),
        const HomeCategoriesSection(id: 'categories', items: []),
        const HomeTrustSection(id: 'trust'),
      ]);
      final adapted = applyStorefrontLayout(home, _layout([('cat-1', 'S')]));
      expect(_ids(adapted)..sort(), _ids(home)..sort());
    });
  });

  group('consent', () {
    StorefrontPersonalizer build({
      required _FakeStorefrontRepository storefront,
      required _FakeVaultRepository vault,
      bool signedIn = true,
    }) => StorefrontPersonalizer(
      storefront: storefront,
      vault: vault,
      isSignedIn: () => signedIn,
    );

    test('a guest is never personalised and never tracked', () async {
      final storefront = _FakeStorefrontRepository(
        layout: _layout([('cat-1', 'Shoes')]),
      );
      final vault = _FakeVaultRepository();
      final personalizer = build(
        storefront: storefront,
        vault: vault,
        signedIn: false,
      );

      expect((await personalizer.layout()).hasRanking, isFalse);
      await personalizer.track(
        const FeedSignal(
          entityId: 'r-1',
          entity: FeedSignalEntity.reel,
          action: FeedSignalAction.watched,
        ),
      );

      expect(storefront.layoutCalls, 0);
      expect(storefront.tracked, isEmpty);
      // A guest is not even asked about consent.
      expect(vault.pausedCalls, 0);
    });

    test(
      'paused personalisation stops both the using and the collecting',
      () async {
        final storefront = _FakeStorefrontRepository(
          layout: _layout([('cat-1', 'Shoes')]),
        );
        final personalizer = build(
          storefront: storefront,
          vault: _FakeVaultRepository(paused: true),
        );

        expect((await personalizer.layout()).hasRanking, isFalse);
        await personalizer.track(
          const FeedSignal(
            entityId: 'r-1',
            entity: FeedSignalEntity.reel,
            action: FeedSignalAction.watched,
          ),
        );

        expect(storefront.layoutCalls, 0);
        expect(storefront.tracked, isEmpty);
      },
    );

    test('an unreadable consent flag is treated as paused', () async {
      final storefront = _FakeStorefrontRepository(
        layout: _layout([('cat-1', 'Shoes')]),
      );
      final personalizer = build(
        storefront: storefront,
        vault: _FakeVaultRepository(fails: true),
      );
      expect((await personalizer.layout()).hasRanking, isFalse);
      expect(storefront.layoutCalls, 0);
    });

    test('a consenting customer is personalised and tracked', () async {
      final storefront = _FakeStorefrontRepository(
        layout: _layout([('cat-1', 'Shoes')]),
      );
      final personalizer = build(
        storefront: storefront,
        vault: _FakeVaultRepository(),
      );

      expect((await personalizer.layout()).hasRanking, isTrue);
      await personalizer.track(
        const FeedSignal(
          entityId: 'r-1',
          entity: FeedSignalEntity.reel,
          action: FeedSignalAction.watched,
        ),
      );
      expect(storefront.tracked.single.entityId, 'r-1');
    });

    test('the consent answer is cached, and forgotten on request', () async {
      final vault = _FakeVaultRepository();
      final personalizer = build(
        storefront: _FakeStorefrontRepository(),
        vault: vault,
      );

      await personalizer.allowed();
      await personalizer.allowed();
      expect(vault.pausedCalls, 1);

      personalizer.forgetConsent();
      vault.paused = true;
      expect(await personalizer.allowed(), isFalse);
      expect(vault.pausedCalls, 2);
    });

    test('a failed consent read is not cached', () async {
      final vault = _FakeVaultRepository(fails: true);
      final personalizer = build(
        storefront: _FakeStorefrontRepository(),
        vault: vault,
      );
      await personalizer.allowed();
      await personalizer.allowed();
      expect(vault.pausedCalls, 2);
    });

    test('a failed layout call is indistinguishable from no history', () async {
      final storefront = _FakeStorefrontRepository();
      final personalizer = build(
        storefront: storefront,
        vault: _FakeVaultRepository(),
      );
      expect((await personalizer.layout()).hasRanking, isFalse);
      expect(storefront.layoutCalls, 1);
    });
  });

  group('which signals are sent', () {
    ({FeedSignalRecorder recorder, _FakeStorefrontRepository storefront})
    build() {
      final storefront = _FakeStorefrontRepository();
      return (
        recorder: FeedSignalRecorder(
          StorefrontPersonalizer(
            storefront: storefront,
            vault: _FakeVaultRepository(),
            isSignedIn: () => true,
          ),
        ),
        storefront: storefront,
      );
    }

    test('opening a product page sends viewed_detail', () async {
      final f = build();
      f.recorder.productViewed('p-1');
      await pumpEventQueue();
      expect(f.storefront.tracked.single.toJson(), {
        'entityId': 'p-1',
        'entityType': 'product',
        'action': 'viewed_detail',
      });
    });

    test('a reel held past the watch threshold sends watched', () async {
      final f = build();
      f.recorder.reelDwell('r-1', const Duration(seconds: 9));
      await pumpEventQueue();
      expect(f.storefront.tracked.single.action, FeedSignalAction.watched);
      expect(f.storefront.tracked.single.entity, FeedSignalEntity.reel);
    });

    test('a reel swiped straight past sends skipped', () async {
      final f = build();
      f.recorder.reelDwell('r-1', const Duration(milliseconds: 400));
      await pumpEventQueue();
      expect(f.storefront.tracked.single.action, FeedSignalAction.skipped);
    });

    test('an ordinary swipe in between says nothing at all', () async {
      final f = build();
      f.recorder.reelDwell('r-1', const Duration(seconds: 3));
      await pumpEventQueue();
      expect(f.storefront.tracked, isEmpty);
    });

    test('the same signal is never sent twice for the same entity', () async {
      final f = build();
      f.recorder
        ..productViewed('p-1')
        ..productViewed('p-1')
        ..reelDwell('r-1', const Duration(seconds: 9))
        ..reelDwell('r-1', const Duration(seconds: 9));
      await pumpEventQueue();
      expect(f.storefront.tracked, hasLength(2));
    });

    test('an empty id is never sent', () async {
      final f = build();
      f.recorder
        ..productViewed('')
        ..productViewed('   ')
        ..reelDwell('', const Duration(seconds: 9));
      await pumpEventQueue();
      expect(f.storefront.tracked, isEmpty);
    });

    test('dwell thresholds', () {
      expect(reelDwellSignal(Duration.zero), FeedSignalAction.skipped);
      expect(
        reelDwellSignal(reelSkipThreshold - const Duration(milliseconds: 1)),
        FeedSignalAction.skipped,
      );
      expect(reelDwellSignal(reelSkipThreshold), isNull);
      expect(
        reelDwellSignal(reelWatchThreshold - const Duration(milliseconds: 1)),
        isNull,
      );
      expect(reelDwellSignal(reelWatchThreshold), FeedSignalAction.watched);
    });
  });

  group('the Mall page', () {
    /// [sampleHome] with its "Deals" rail tied to a category, so a ranking
    /// has something on the real page to act on.
    MallHome pageHome() {
      final home = sampleHome();
      return MallHome(
        greetingFirstName: home.greetingFirstName,
        personalized: home.personalized,
        generatedUtc: home.generatedUtc,
        sections: [
          for (final section in home.sections)
            if (section is HomeProductsSection && section.id == 'deals')
              HomeProductsSection(
                id: section.id,
                items: section.items,
                eyebrow: section.eyebrow,
                title: section.title,
                seeAll: _categorySeeAll('cat-3'),
              )
            else
              section,
        ],
      );
    }

    Future<
      ({_FakeStorefrontRepository storefront, List<String> Function() order})
    >
    pump(
      WidgetTester tester, {
      required bool signedIn,
      StorefrontLayout layout = StorefrontLayout.none,
      bool paused = false,
      double width = 390,
      double textScale = 1,
    }) async {
      final storefront = _FakeStorefrontRepository(layout: layout);
      await pumpMallApp(
        tester,
        location: '/home',
        routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
        overrides: [
          mallHomeRepositoryProvider.overrideWithValue(
            FakeMallHomeRepository([right(pageHome())]),
          ),
          mallViewerSignedInProvider.overrideWithValue(signedIn),
          mallClockProvider.overrideWithValue(mallTestNow),
          reelsRepositoryProvider.overrideWithValue(FakeReelsRepository()),
        ],
        storefront: storefront,
        vault: _FakeVaultRepository(paused: paused),
        width: width,
        textScale: textScale,
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      return (
        storefront: storefront,
        order: () => _ids(
          container.read(mallHomeNotifierProvider).homeOrNull ??
              _home(const []),
        ),
      );
    }

    final serverOrder = _ids(pageHome());

    testWidgets('renders the personalised order for a signed-in customer', (
      tester,
    ) async {
      final page = await pump(
        tester,
        signedIn: true,
        layout: _layout([('cat-3', 'Tech')]),
      );
      expect(page.storefront.layoutCalls, 1);
      // The ranked rail leads the movable band, under the hero.
      expect(page.order()[1], 'deals');
      expect(page.order().first, 'hero');
      expect(page.order().last, 'trust');
      // Still the Mall's own kit, still the Mall | Reels switch.
      expect(find.byType(MallCinematicHero), findsOneWidget);
      expect(find.text('Reels'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a guest gets the fixed home and is never asked for a layout', (
      tester,
    ) async {
      final page = await pump(
        tester,
        signedIn: false,
        layout: _layout([('cat-3', 'Tech')]),
      );
      expect(page.storefront.layoutCalls, 0);
      expect(page.order(), serverOrder);
      expect(find.byType(MallCinematicHero), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed layout call falls back invisibly', (tester) async {
      // The fake answers `none`, which is what the repository turns every
      // failure into.
      final page = await pump(tester, signedIn: true);
      expect(page.storefront.layoutCalls, 1);
      expect(page.order(), serverOrder);
      expect(find.byType(MallCinematicHero), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty ranking falls back invisibly', (tester) async {
      final page = await pump(
        tester,
        signedIn: true,
        layout: const StorefrontLayout(
          rankedCategories: [],
          isPersonalized: true,
        ),
      );
      expect(page.order(), serverOrder);
      expect(tester.takeException(), isNull);
    });

    testWidgets('paused personalisation gets the fixed home', (tester) async {
      final page = await pump(
        tester,
        signedIn: true,
        paused: true,
        layout: _layout([('cat-3', 'Tech')]),
      );
      expect(page.storefront.layoutCalls, 0);
      expect(page.order(), serverOrder);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
      final page = await pump(
        tester,
        signedIn: true,
        layout: _layout([('cat-3', 'Tech')]),
        width: 320,
        textScale: 1.3,
      );
      expect(page.order()[1], 'deals');
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
