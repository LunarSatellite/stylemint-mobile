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
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
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

/// A layout that blows up the moment the page tries to organise around it:
/// stands in for a shape from a newer server this build mishandles. The
/// customer must still get the ordinary page.
class _ExplodingLayout extends StorefrontLayout {
  const _ExplodingLayout()
    : super(rankedCategories: const [], isPersonalized: false);

  @override
  bool get hasModules => true;

  @override
  List<StorefrontModule> get modules =>
      throw StateError('a shape this build cannot read');
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

/// A module, in the shape the server sends one.
StorefrontModule _module(
  StorefrontModuleKind kind, {
  required int rank,
  required int evidence,
  StorefrontSignal signal = StorefrontSignal.recentOrders,
  List<String> categoryIds = const [],
  HomeSeeAll? target,
}) => StorefrontModule(
  kind: kind,
  rank: rank,
  signal: signal,
  evidence: evidence,
  categoryIds: categoryIds,
  target: target,
);

/// A layout that carries modules and nothing else — the mission-only
/// customer, who has no purchase ranking at all.
StorefrontLayout _modules(List<StorefrontModule> modules) => StorefrontLayout(
  rankedCategories: const [],
  isPersonalized: false,
  status: StorefrontLayoutStatus.noHistory,
  modules: modules,
);

HomeReelsSection _reels(String id, {Map<String, String> params = const {}}) =>
    HomeReelsSection(
      id: id,
      title: id,
      items: const [],
      seeAll: HomeSeeAll(target: HomeSeeAllTarget.reels, params: params),
    );

const HomeSeeAll _missionTarget = HomeSeeAll(
  target: HomeSeeAllTarget.mission,
  params: {'missionId': 'mis-1'},
);

const HomeSeeAll _reorderTarget = HomeSeeAll(target: HomeSeeAllTarget.reorder);

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

    test('a module the page cannot draw never makes it a broken block', () {
      final home = _home([
        const HomeCampaignsSection(id: 'hero', items: []),
        _products('plain'),
        const HomeTrustSection(id: 'trust'),
      ]);
      // Refill's target has no destination in this build, and an unknown
      // kind from a newer server has no drawing at all.
      final adapted = applyStorefrontLayout(
        home,
        _modules([
          _module(
            StorefrontModuleKind.refill,
            rank: 0,
            signal: StorefrontSignal.replenishmentDue,
            evidence: 4,
            target: _reorderTarget,
          ),
          _module(
            StorefrontModuleKind.unknown,
            rank: 1,
            evidence: 9,
            signal: StorefrontSignal.unknown,
            target: const HomeSeeAll(target: HomeSeeAllTarget.unknown),
          ),
        ]),
      );
      expect(adapted.sections, orderedEquals(home.sections));
      expect(_ids(adapted), ['hero', 'plain', 'trust']);
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

  group('modules', () {
    MallHome page() => _home([
      const HomeCampaignsSection(id: 'hero', items: []),
      _products('editorial'),
      _products('shoes', categoryId: 'cat-1'),
      _reels('watch'),
      const HomeTrustSection(id: 'trust'),
    ]);

    test('matched sections lead the page in the server rank order', () {
      final adapted = applyStorefrontLayout(
        page(),
        _modules([
          _module(
            StorefrontModuleKind.becauseYouWatched,
            rank: 0,
            signal: StorefrontSignal.watchedReels,
            evidence: 2,
            categoryIds: const ['cat-9'],
            target: const HomeSeeAll(
              target: HomeSeeAllTarget.reels,
              params: {'categoryId': 'cat-9'},
            ),
          ),
          _module(
            StorefrontModuleKind.boughtBefore,
            rank: 1,
            evidence: 6,
            categoryIds: const ['cat-1'],
            target: const HomeSeeAll(
              target: HomeSeeAllTarget.category,
              params: {'categoryId': 'cat-1'},
            ),
          ),
        ]),
      );
      // Hero keeps the top, trust keeps the bottom, modules lead the band.
      expect(_ids(adapted), ['hero', 'watch', 'shoes', 'editorial', 'trust']);
    });

    test('a module the client cannot draw is skipped and the rest render', () {
      final adapted = applyStorefrontLayout(
        page(),
        _modules([
          _module(
            StorefrontModuleKind.refill,
            rank: 0,
            signal: StorefrontSignal.replenishmentDue,
            evidence: 4,
            target: _reorderTarget,
          ),
          _module(
            StorefrontModuleKind.unknown,
            rank: 1,
            evidence: 9,
            signal: StorefrontSignal.unknown,
          ),
          _module(
            StorefrontModuleKind.becauseYouWatched,
            rank: 2,
            signal: StorefrontSignal.watchedReels,
            evidence: 2,
            target: const HomeSeeAll(target: HomeSeeAllTarget.reels),
          ),
        ]),
      );
      expect(_ids(adapted), ['hero', 'watch', 'editorial', 'shoes', 'trust']);
      expect(
        adapted.sections.whereType<HomePromptSection>(),
        isEmpty,
        reason: 'nothing may be drawn for a module with nowhere to go',
      );
    });

    test('an open mission becomes a typographic prompt', () {
      final adapted = applyStorefrontLayout(
        page(),
        _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 3,
            target: _missionTarget,
          ),
        ]),
      );
      final prompt = adapted.sections.whereType<HomePromptSection>().single;
      expect(_ids(adapted).first, 'hero');
      expect(_ids(adapted)[1], prompt.id);
      // The recorded count, phrased as the count it is.
      expect(prompt.fact, '3 items still on your list');
      expect(prompt.action, isNotEmpty);
      // And it opens a screen the app already has.
      final destination = destinationForSeeAll(prompt);
      expect(destination, isA<MallPush>());
      expect((destination! as MallPush).location, contains('mis-1'));
    });

    test('one item reads as one item', () {
      final adapted = applyStorefrontLayout(
        page(),
        _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 1,
            target: _missionTarget,
          ),
        ]),
      );
      expect(
        adapted.sections.whereType<HomePromptSection>().single.fact,
        '1 item still on your list',
      );
    });

    test('a count the server did not send is never drawn', () {
      final adapted = applyStorefrontLayout(
        page(),
        _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 0,
            target: _missionTarget,
          ),
        ]),
      );
      expect(
        adapted.sections.whereType<HomePromptSection>().single.fact,
        isNull,
      );
    });

    test('a mission with no target is skipped rather than guessed at', () {
      final home = page();
      final adapted = applyStorefrontLayout(
        home,
        _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 3,
          ),
        ]),
      );
      expect(adapted.sections, orderedEquals(home.sections));
    });

    test('a module never lands on a section about something else', () {
      final home = _home([
        _products('shoes', categoryId: 'cat-1'),
        _products('plain'),
      ]);
      final adapted = applyStorefrontLayout(
        home,
        _modules([
          _module(
            StorefrontModuleKind.boughtBefore,
            rank: 0,
            evidence: 2,
            target: const HomeSeeAll(
              target: HomeSeeAllTarget.category,
              params: {'categoryId': 'cat-77'},
            ),
          ),
        ]),
      );
      expect(adapted.sections, orderedEquals(home.sections));
    });

    test('the category ids still match when the target does not', () {
      final adapted = applyStorefrontLayout(
        page(),
        _modules([
          _module(
            StorefrontModuleKind.boughtBefore,
            rank: 0,
            evidence: 2,
            categoryIds: const ['CAT-1'],
            target: const HomeSeeAll(target: HomeSeeAllTarget.unknown),
          ),
        ]),
      );
      expect(_ids(adapted)[1], 'shoes');
    });

    test('modules and the ranked categories both act on one page', () {
      final layout = StorefrontLayout(
        isPersonalized: true,
        rankedCategories: const [
          StorefrontCategoryRank(
            categoryId: 'cat-1',
            label: 'Shoes',
            recentPurchaseCount: 4,
          ),
        ],
        modules: [
          _module(
            StorefrontModuleKind.becauseYouWatched,
            rank: 0,
            signal: StorefrontSignal.watchedReels,
            evidence: 2,
            target: const HomeSeeAll(target: HomeSeeAllTarget.reels),
          ),
        ],
      );
      final adapted = applyStorefrontLayout(page(), layout);
      // The module leads; the ranked rail keeps the promotion it earned.
      expect(_ids(adapted), ['hero', 'watch', 'shoes', 'editorial', 'trust']);
      final shoes = adapted.sections.firstWhere((s) => s.id == 'shoes');
      expect(shoes.reason, "Because you've been buying Shoes");
      // The reels rail says what it rests on, and claims nothing more.
      final watch = adapted.sections.firstWhere((s) => s.id == 'watch');
      expect(watch.reason, 'From reels you have been watching');
    });

    test("a module never overwrites the server's own reason", () {
      final home = MallHome(
        sections: [
          const HomeReelsSection(
            id: 'watch',
            title: 'watch',
            items: [],
            reason: 'Hand-picked for the season',
            seeAll: HomeSeeAll(target: HomeSeeAllTarget.reels),
          ),
          _products('plain'),
        ],
      );
      final adapted = applyStorefrontLayout(
        home,
        _modules([
          _module(
            StorefrontModuleKind.becauseYouWatched,
            rank: 0,
            signal: StorefrontSignal.watchedReels,
            evidence: 2,
            target: const HomeSeeAll(target: HomeSeeAllTarget.reels),
          ),
        ]),
      );
      expect(adapted.sections.first.reason, 'Hand-picked for the season');
    });
  });

  group('the modules contract', () {
    test('reads modules and context, camelCased', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': <dynamic>[],
        'isPersonalized': false,
        'status': 'NoHistory',
        'modules': [
          {
            'kind': 'ContinueMission',
            'rank': 0,
            'signal': 'ActiveMission',
            'evidence': 3,
            'categoryIds': <dynamic>[],
            'target': {
              'target': 'mission',
              'params': {'missionId': 'mis-1'},
            },
          },
        ],
        'context': {
          'sessionIntent': 'hunting',
          'signalsUsed': ['ActiveMission'],
          'signalsUnavailable': ['WatchedReels'],
        },
      });
      // No ranking at all, and still plenty to organise around.
      expect(layout.hasRanking, isFalse);
      expect(layout.hasModules, isTrue);
      expect(layout.status, StorefrontLayoutStatus.noHistory);
      final module = layout.modules.single;
      expect(module.kind, StorefrontModuleKind.continueMission);
      expect(module.signal, StorefrontSignal.activeMission);
      expect(module.evidence, 3);
      expect(module.target!.target, HomeSeeAllTarget.mission);
      expect(module.target!.params['missionId'], 'mis-1');
      expect(layout.context.sessionIntent, 'hunting');
      expect(layout.context.signalsUsed, [StorefrontSignal.activeMission]);
      expect(layout.context.signalsUnavailable, [
        StorefrontSignal.watchedReels,
      ]);
    });

    test('reads the PascalCased shape of the same fields', () {
      final layout = storefrontLayoutFromJson({
        'RankedCategories': <dynamic>[],
        'IsPersonalized': false,
        'Status': 'NoHistory',
        'Modules': [
          {
            'Kind': 'Refill',
            'Rank': 0,
            'Signal': 'ReplenishmentDue',
            'Evidence': 4,
            'CategoryIds': <dynamic>[],
            'Target': {'Target': 'reorder', 'Params': <String, String>{}},
          },
        ],
        'Context': {'SessionIntent': 'Researching'},
      });
      expect(layout.modules.single.kind, StorefrontModuleKind.refill);
      expect(layout.modules.single.evidence, 4);
      expect(layout.modules.single.target!.target, HomeSeeAllTarget.reorder);
      expect(layout.context.sessionIntent, 'researching');
    });

    test('modules arrive in rank order however the list was sent', () {
      final layout = storefrontLayoutFromJson({
        'isPersonalized': false,
        'modules': [
          {'kind': 'BoughtBefore', 'rank': 1, 'evidence': 2},
          {'kind': 'BecauseYouWatched', 'rank': 0, 'evidence': 2},
        ],
      });
      expect(layout.modules.map((m) => m.rank), [0, 1]);
      expect(layout.modules.first.kind, StorefrontModuleKind.becauseYouWatched);
    });

    test('a kind this build does not know parses, and is dropped later', () {
      final layout = storefrontLayoutFromJson({
        'isPersonalized': false,
        'modules': [
          {'kind': 'SomethingNewNextQuarter', 'rank': 0, 'evidence': 9},
        ],
      });
      expect(layout.modules.single.kind, StorefrontModuleKind.unknown);
    });

    test('an unknown status is read as unknown and changes nothing', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': [
          {'categoryId': 'cat-1', 'label': 'Shoes', 'recentPurchaseCount': 2},
        ],
        'isPersonalized': true,
        'status': 'SomeFutureStatus',
      });
      expect(layout.status, StorefrontLayoutStatus.unknown);
      // Unknown is not a failure: the ranking it came with is still real.
      expect(layout.hasRanking, isTrue);
    });

    test('a paused customer gets nothing to apply, and it is not an error', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': <dynamic>[],
        'isPersonalized': false,
        'status': 'PersonalizationPaused',
        'modules': <dynamic>[],
      });
      expect(layout.status, StorefrontLayoutStatus.personalizationPaused);
      expect(layout.isEmpty, isTrue);
      expect(layout.hasModules, isFalse);
    });

    test('a paused status wins over anything else in the body', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': [
          {'categoryId': 'cat-1', 'label': 'Shoes', 'recentPurchaseCount': 2},
        ],
        'isPersonalized': true,
        'status': 'PersonalizationPaused',
        'modules': [
          {'kind': 'BoughtBefore', 'rank': 0, 'evidence': 2},
        ],
      });
      expect(layout.isEmpty, isTrue);
      expect(layout.rankedCategories, isEmpty);
      expect(layout.modules, isEmpty);
    });

    test('the old body, with no new fields at all, still reads as before', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': [
          {'categoryId': 'cat-1', 'label': 'Shoes', 'recentPurchaseCount': 2},
        ],
        'isPersonalized': true,
      });
      expect(layout.hasRanking, isTrue);
      expect(layout.status, StorefrontLayoutStatus.personalized);
      expect(layout.modules, isEmpty);
      expect(layout.context.sessionIntent, 'browsing');
    });

    test('a malformed module list is no reason to lose the page', () {
      final layout = storefrontLayoutFromJson({
        'rankedCategories': [
          {'categoryId': 'cat-1', 'label': 'Shoes', 'recentPurchaseCount': 2},
        ],
        'isPersonalized': true,
        'modules': 'not a list',
        'context': 42,
      });
      expect(layout.hasRanking, isTrue);
      expect(layout.modules, isEmpty);
      expect(layout.context.sessionIntent, 'browsing');
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
        FeedSignal.forEntity(
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
          FeedSignal.forEntity(
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
        FeedSignal.forEntity(
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

    testWidgets('modules organise the page the shopper actually sees', (
      tester,
    ) async {
      final page = await pump(
        tester,
        signedIn: true,
        layout: _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 3,
            target: _missionTarget,
          ),
          _module(
            StorefrontModuleKind.boughtBefore,
            rank: 1,
            evidence: 5,
            categoryIds: const ['cat-3'],
            target: const HomeSeeAll(
              target: HomeSeeAllTarget.category,
              params: {'categoryId': 'cat-3'},
            ),
          ),
        ]),
      );
      final order = page.order();
      expect(order.first, 'hero');
      expect(order[1], 'storefront-mission');
      expect(order[2], 'deals');
      expect(order.last, 'trust');
      // The count the server recorded, on the page, phrased as a count.
      expect(find.text('3 items still on your list'), findsOneWidget);
      expect(find.text('Pick up where you left off'), findsOneWidget);
      // Still the Mall's own kit.
      expect(find.byType(MallCinematicHero), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a module with nowhere to go leaves no trace on the page', (
      tester,
    ) async {
      final page = await pump(
        tester,
        signedIn: true,
        layout: _modules([
          _module(
            StorefrontModuleKind.refill,
            rank: 0,
            signal: StorefrontSignal.replenishmentDue,
            evidence: 4,
            target: _reorderTarget,
          ),
          _module(
            StorefrontModuleKind.unknown,
            rank: 1,
            evidence: 9,
            signal: StorefrontSignal.unknown,
          ),
        ]),
      );
      expect(page.order(), serverOrder);
      expect(find.textContaining('restock'), findsNothing);
      expect(find.textContaining('4 items'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a client-side failure falls back invisibly', (tester) async {
      final page = await pump(
        tester,
        signedIn: true,
        layout: const _ExplodingLayout(),
      );
      expect(page.order(), serverOrder);
      expect(find.byType(MallCinematicHero), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a paused customer is not personalised, not collected from, '
        'and never nudged', (tester) async {
      final page = await pump(
        tester,
        signedIn: true,
        paused: true,
        layout: _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 3,
            target: _missionTarget,
          ),
        ]),
      );
      // Not asked for, and nothing recorded either.
      expect(page.storefront.layoutCalls, 0);
      expect(page.storefront.tracked, isEmpty);
      expect(page.order(), serverOrder);
      // No module, no error, and no invitation to switch it back on.
      expect(find.text('Pick up where you left off'), findsNothing);
      expect(find.textContaining('personalis'), findsNothing);
      expect(find.textContaining('personaliz'), findsNothing);
      expect(find.textContaining('Turn on'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a prompt does not overflow at 320dp and text scale 1.3', (
      tester,
    ) async {
      await pump(
        tester,
        signedIn: true,
        layout: _modules([
          _module(
            StorefrontModuleKind.continueMission,
            rank: 0,
            signal: StorefrontSignal.activeMission,
            evidence: 12,
            target: _missionTarget,
          ),
        ]),
        width: 320,
        textScale: 1.3,
      );
      expect(find.text('12 items still on your list'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
      await tester.pumpAndSettle();
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

  group('the searched signal', () {
    StorefrontPersonalizer personalizerWith(
      _FakeStorefrontRepository storefront, {
      bool paused = false,
      bool signedIn = true,
    }) => StorefrontPersonalizer(
      storefront: storefront,
      vault: _FakeVaultRepository(paused: paused),
      isSignedIn: () => signedIn,
    );

    test('a free-text search carries the query and no id', () {
      final signal = FeedSignal.searchedQuery('  red cotton saree  ');

      expect(signal.entityId, isNull);
      expect(signal.query, 'red cotton saree');
      expect(signal.isQueryShaped, isTrue);
      expect(signal.toJson(), {
        'entityType': 'search',
        'action': 'searched',
        'query': 'red cotton saree',
      });
      expect(signal.toJson().containsKey('entityId'), isFalse);
    });

    test('an id-shaped signal still needs a real id', () {
      expect(
        () => FeedSignal.forEntity(
          entityId: '   ',
          entity: FeedSignalEntity.reel,
          action: FeedSignalAction.watched,
        ),
        throwsArgumentError,
      );
      // The zero GUID is the placeholder the backend rejects, in every
      // spelling a client might reach for.
      for (final zero in [
        '00000000-0000-0000-0000-000000000000',
        '00000000000000000000000000000000',
        '{00000000-0000-0000-0000-000000000000}',
      ]) {
        expect(
          () => FeedSignal.forEntity(
            entityId: zero,
            entity: FeedSignalEntity.search,
            action: FeedSignalAction.searched,
          ),
          throwsArgumentError,
          reason: zero,
        );
      }
    });

    test('no invalid combination can be constructed', () {
      // An id-shaped signal never carries a query...
      final idShaped = FeedSignal.forEntity(
        entityId: 'cat-1',
        entity: FeedSignalEntity.search,
        action: FeedSignalAction.searched,
      );
      expect(idShaped.query, isNull);
      expect(idShaped.toJson().containsKey('query'), isFalse);

      // ...and a query-shaped one is always the searched action, never with
      // an id, and never with nothing to say.
      final queryShaped = FeedSignal.searchedQuery('boots');
      expect(queryShaped.action, FeedSignalAction.searched);
      expect(queryShaped.entity, FeedSignalEntity.search);
      expect(() => FeedSignal.searchedQuery('   '), throwsArgumentError);
    });

    test('the recorder sends one query-shaped signal per query', () async {
      final storefront = _FakeStorefrontRepository();
      FeedSignalRecorder(personalizerWith(storefront))
        ..searchedQuery('red saree')
        ..searchedQuery('RED SAREE')
        ..searchedQuery('  ')
        ..searchedQuery('boots');
      await Future<void>.delayed(Duration.zero);

      expect(storefront.tracked.map((s) => s.query), [
        'red saree',
        'boots',
      ]);
      expect(storefront.tracked.every((s) => s.entityId == null), isTrue);
    });

    test('a paused customer sends no search signal at all', () async {
      final storefront = _FakeStorefrontRepository();
      FeedSignalRecorder(
        personalizerWith(storefront, paused: true),
      ).searchedQuery('red saree');
      await Future<void>.delayed(Duration.zero);

      expect(storefront.tracked, isEmpty);
    });

    test('a guest sends no search signal at all', () async {
      final storefront = _FakeStorefrontRepository();
      FeedSignalRecorder(
        personalizerWith(storefront, signedIn: false),
      ).searchedQuery('red saree');
      await Future<void>.delayed(Duration.zero);

      expect(storefront.tracked, isEmpty);
    });
  });
}
