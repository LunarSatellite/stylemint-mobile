import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/recent_searches_local_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/not_interested_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/recent_searches_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/search_suggest_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';

import '../../mall_home/mall_test_support.dart';
import '../discover_test_support.dart';

DiscoverFeedLoaded _loaded(DiscoverFeedNotifier notifier) =>
    notifier.state.feed as DiscoverFeedLoaded;

List<String> _productIds(DiscoverFeedNotifier notifier) => [
  for (final block in _loaded(
    notifier,
  ).blocks.whereType<DiscoverProductsBlock>())
    ...block.items.map((product) => product.id),
];

void main() {
  group('SearchSuggestNotifier', () {
    testWidgets('debounces edits into one request for the latest query', (
      tester,
    ) async {
      final repository = FakeDiscoverRepository(
        onSuggest: (query) => right(sampleSuggestions(query)),
      );
      final notifier = SearchSuggestNotifier(repository);
      addTearDown(notifier.dispose);

      notifier
        ..onQueryChanged('gl')
        ..onQueryChanged('glo')
        ..onQueryChanged(' Glow ');
      expect(notifier.state, isA<SuggestLoading>());

      await tester.pump(const Duration(milliseconds: 249));
      expect(repository.suggestCalls, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(repository.suggestCalls, ['glow']);
      final state = notifier.state as SuggestLoaded;
      expect(state.query, 'glow');
      expect(state.suggestions.brands, isNotEmpty);
    });

    testWidgets('stays idle under two characters and sends nothing', (
      tester,
    ) async {
      final repository = FakeDiscoverRepository();
      final notifier = SearchSuggestNotifier(repository)
        ..onQueryChanged('glow')
        ..onQueryChanged('g')
        ..onQueryChanged('#a ');
      addTearDown(notifier.dispose);

      await tester.pump(const Duration(milliseconds: 400));

      expect(notifier.state, isA<SuggestIdle>());
      expect(repository.suggestCalls, isEmpty);
    });

    testWidgets('a too_short answer is idle; other failures show', (
      tester,
    ) async {
      var failure = const NetworkExceptions.validation(
        code: SearchSuggestNotifier.tooShortCode,
      );
      final repository = FakeDiscoverRepository(
        onSuggest: (_) => left(failure),
      );
      final notifier = SearchSuggestNotifier(repository)..onQueryChanged('ab');
      addTearDown(notifier.dispose);
      await tester.pump(const Duration(milliseconds: 300));
      expect(notifier.state, isA<SuggestIdle>());

      failure = const NetworkExceptions.noInternetConnection();
      notifier.onQueryChanged('abc');
      await tester.pump(const Duration(milliseconds: 300));
      expect(notifier.state, isA<SuggestFailure>());
    });
  });

  group('RecentSearchesNotifier', () {
    test('keeps the last 8, newest first, each once ignoring case', () async {
      final store = MemoryRecentSearchesStore(['linen']);
      final notifier = RecentSearchesNotifier(store);
      addTearDown(notifier.dispose);
      await notifier.ready;
      expect(notifier.state, ['linen']);

      for (var i = 0; i < 9; i++) {
        await notifier.add('term $i');
      }
      await notifier.add('  TERM   8 ');

      expect(notifier.state, hasLength(RecentSearchesNotifier.maxEntries));
      expect(notifier.state.first, 'TERM 8');
      expect(notifier.state.skip(1).first, 'term 7');
      expect(notifier.state, isNot(contains('linen')));
      expect(store.saved, notifier.state);

      await notifier.remove('TERM 8');
      expect(notifier.state.first, 'term 7');

      await notifier.clear();
      expect(notifier.state, isEmpty);
      expect(store.saved, isEmpty);
    });

    test('the shared_preferences store round-trips', () async {
      SharedPreferences.setMockInitialValues({});
      const store = SharedPreferencesRecentSearchesStore();

      await store.write(['silk', 'linen']);
      expect(await store.read(), ['silk', 'linen']);

      await store.write(const []);
      expect(await store.read(), isEmpty);
    });
  });

  group('DiscoverFeedNotifier', () {
    late FakeMallHomeRepository home;
    late FakeDiscoverRepository discover;

    DiscoverFeedNotifier build(FakeMallCatalogRepository catalog) {
      final notifier = DiscoverFeedNotifier(
        homeRepository: home,
        catalogRepository: catalog,
        discoverRepository: discover,
      );
      addTearDown(notifier.dispose);
      return notifier;
    }

    setUp(() {
      home = FakeMallHomeRepository([right(sampleHome())]);
      discover = FakeDiscoverRepository();
    });

    test('For You keeps its rhythm and shows each product once', () async {
      final catalog = FakeMallCatalogRepository(
        onProducts: (call) => right(
          call.cursor == null
              ? productPage([
                  'p-2',
                  'p-3',
                  for (var i = 4; i <= 11; i++) 'p-$i',
                ], cursor: 'page-2')
              : productPage([
                  'p-11',
                  'p-1',
                  for (var i = 12; i <= 18; i++) 'p-$i',
                ]),
        ),
      );
      final notifier = build(catalog);
      await pumpEventQueue();

      expect(_loaded(notifier).blocks.map((block) => block.runtimeType), [
        DiscoverProductsBlock,
        DiscoverReelsBlock,
        DiscoverCreatorsBlock,
        DiscoverProductsBlock,
        DiscoverCollectionBlock,
        DiscoverBrandsBlock,
      ]);
      expect(catalog.productCalls.first.query.sort, ProductSort.bestselling);
      // The personalised rail leads, then the other home rails.
      expect(_productIds(notifier).take(3), ['p-1', 'p-2', 'p-3']);
      expect(_loaded(notifier).hasMore, isTrue);

      await notifier.loadMore();

      final ids = _productIds(notifier);
      expect(ids, hasLength(18));
      expect(ids.toSet(), hasLength(ids.length));
      expect(_loaded(notifier).hasMore, isFalse);
      expect(notifier.state.chips.last, isA<DiscoverCategoryChip>());
    });

    test('chips load their own feeds and keep them', () async {
      final catalog = FakeMallCatalogRepository(
        onProducts: (call) => right(productPage(['x-${call.query.sort.wire}'])),
      );
      final notifier = build(catalog);
      await pumpEventQueue();

      await notifier.select(const DiscoverKindChip(DiscoverFeedKind.trending));
      expect(catalog.productCalls.last.query.sort, ProductSort.bestselling);
      expect(_productIds(notifier), ['x-bestselling']);
      expect(
        (_loaded(notifier).blocks.single as DiscoverProductsBlock).isListing,
        isTrue,
      );

      await notifier.select(const DiscoverKindChip(DiscoverFeedKind.newDrops));
      expect(catalog.productCalls.last.query.sort, ProductSort.newest);

      await notifier.select(const DiscoverKindChip(DiscoverFeedKind.sale));
      expect(catalog.productCalls.last.query.onSale, isTrue);

      await notifier.select(
        notifier.state.chips.whereType<DiscoverCategoryChip>().first,
      );
      expect(catalog.productCalls.last.query.categorySlug, 'fashion');

      await notifier.select(
        const DiscoverKindChip(DiscoverFeedKind.collections),
      );
      expect(discover.collectionCalls, [null]);

      for (final kind in [
        DiscoverFeedKind.reels,
        DiscoverFeedKind.creators,
        DiscoverFeedKind.brands,
      ]) {
        await notifier.select(DiscoverKindChip(kind));
        expect(_loaded(notifier).blocks, hasLength(1));
      }

      final calls = catalog.productCalls.length;
      await notifier.select(const DiscoverKindChip(DiscoverFeedKind.trending));
      expect(catalog.productCalls, hasLength(calls));
      expect(_productIds(notifier), ['x-bestselling']);
      expect(home.homeCalls, 1);
    });

    test('a late answer for a chip left behind is not shown', () async {
      final catalog = FakeMallCatalogRepository(
        onProducts: (call) => right(productPage(['x-${call.query.sort.wire}'])),
      );
      final notifier = build(catalog);
      await pumpEventQueue();

      final gate = Completer<void>();
      catalog.nextProductsGate = gate;
      final trending = notifier.select(
        const DiscoverKindChip(DiscoverFeedKind.trending),
      );
      await notifier.select(const DiscoverKindChip(DiscoverFeedKind.reels));
      gate.complete();
      await trending;

      expect(
        notifier.state.selected,
        const DiscoverKindChip(DiscoverFeedKind.reels),
      );
      expect(_loaded(notifier).blocks.single, isA<DiscoverReelsBlock>());
    });

    test('a failed home page fails For You; retry recovers', () async {
      home = FakeMallHomeRepository([
        left(const NetworkExceptions.noInternetConnection()),
        right(sampleHome()),
      ]);
      final notifier = build(
        FakeMallCatalogRepository(onProducts: (_) => right(productPage([]))),
      );
      await pumpEventQueue();
      expect(notifier.state.feed, isA<DiscoverFeedFailure>());

      await notifier.retry();
      expect(notifier.state.feed, isA<DiscoverFeedLoaded>());
    });
  });

  group('NotInterestedNotifier', () {
    const product = NotInterestedTarget(NotInterestedKind.product, 'p-1');

    test('hides at once and rolls back when the server refuses', () async {
      final repository = FakeDiscoverRepository()
        ..markResult = left(const NetworkExceptions.serverUnavailable());
      final notifier = NotInterestedNotifier(repository);
      addTearDown(notifier.dispose);

      final hiding = notifier.hide(product);
      expect(notifier.state, {product});
      expect(await hiding, isFalse);
      expect(notifier.state, isEmpty);
    });

    test('undo waits for the hide to land before deleting', () async {
      final gate = Completer<void>();
      final repository = FakeDiscoverRepository()..markGate = gate;
      final notifier = NotInterestedNotifier(repository);
      addTearDown(notifier.dispose);

      unawaited(notifier.hide(product));
      final undoing = notifier.undo(product);
      expect(notifier.state, isEmpty);
      await pumpEventQueue();
      expect(repository.undone, isEmpty);

      gate.complete();
      expect(await undoing, isTrue);
      expect(repository.undone, [product]);
    });

    test('a brand hides its products and a creator their reels', () {
      final hidden = {
        const NotInterestedTarget(NotInterestedKind.brand, 'v-1'),
        const NotInterestedTarget(NotInterestedKind.creator, 'a-1'),
      };

      expect(
        hidden.hidesProduct(
          HomeProduct(
            id: 'p-9',
            name: 'Scarf',
            price: rs(900),
            vendorAccountId: 'v-1',
          ),
        ),
        isTrue,
      );
      expect(
        hidden.hidesReel(
          const HomeReel(
            id: 'r-9',
            creatorName: 'Sumi',
            creatorAccountId: 'a-1',
          ),
        ),
        isTrue,
      );
      expect(
        hidden.hidesBrand(const HomeBrand(vendorAccountId: 'v-2', name: 'B')),
        isFalse,
      );
    });
  });
}
