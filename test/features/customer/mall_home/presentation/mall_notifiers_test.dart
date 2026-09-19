import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/collection_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/collection_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/mall_home_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/product_listing_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/reel_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

import '../mall_test_support.dart';

const _offline = NetworkExceptions.noInternetConnection();

class _FakeReelsRepository implements ReelsRepository {
  _FakeReelsRepository(this.detail);

  final Either<NetworkExceptions, Reel> detail;

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async =>
      detail;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CollectionDetail _collection(Iterable<String> ids, {String? cursor}) =>
    CollectionDetail(
      id: 'col',
      slug: 'edit',
      title: 'Edit',
      kind: CollectionKind.editorial,
      items: CatalogPage(
        items: [
          for (final id in ids) CollectionItem(product: catalogProduct(id)),
        ],
        nextCursor: cursor,
      ),
    );

void main() {
  group('MallHomeNotifier', () {
    test('loads the page', () async {
      final repo = FakeMallHomeRepository([right(sampleHome())]);
      final notifier = MallHomeNotifier(repo);
      expect(notifier.state, const MallHomeState.loadInProgress());
      await pumpEventQueue();
      expect(notifier.state.homeOrNull?.sections, hasLength(9));
      notifier.dispose();
    });

    test('a failed first load is a failure state', () async {
      final notifier = MallHomeNotifier(
        FakeMallHomeRepository([left(_offline)]),
      );
      await pumpEventQueue();
      expect(notifier.state, const MallHomeState.loadFailure(_offline));
      notifier.dispose();
    });

    test('refresh keeps the page on failure and swaps it on success', () async {
      final updated = MallHome(
        sections: sampleHome().sections.take(2).toList(),
      );
      final repo = FakeMallHomeRepository([
        right(sampleHome()),
        left(_offline),
        right(updated),
      ]);
      final notifier = MallHomeNotifier(repo);
      await pumpEventQueue();

      expect(await notifier.refresh(), isFalse);
      expect(notifier.state.homeOrNull?.sections, hasLength(9));

      expect(await notifier.refresh(), isTrue);
      expect(notifier.state.homeOrNull, same(updated));
      expect(repo.homeCalls, 3);
      notifier.dispose();
    });
  });

  group('ProductListingNotifier', () {
    late FakeMallCatalogRepository repo;

    setUp(() {
      repo = FakeMallCatalogRepository(
        onProducts: (call) => right(
          call.cursor == null
              ? productPage(
                  List.generate(20, (i) => 'p$i'),
                  cursor: 'c1',
                  total: 25,
                )
              : productPage(['p18', 'p19', 'p20', 'p21', 'p22', 'p23', 'p24']),
        ),
      );
    });

    test('pages in without duplicates and stops at the end', () async {
      final notifier = ProductListingNotifier(
        repo,
        query: const ProductListingQuery(),
      );
      await pumpEventQueue();
      await notifier.loadMore();
      await notifier.loadMore();

      final data = notifier.state.maybeWhen(
        loadSuccess: (d) => d,
        orElse: () => null,
      )!;
      expect(data.products.map((p) => p.id).toSet(), hasLength(25));
      expect(data.products, hasLength(25));
      expect(data.hasMore, isFalse);
      expect(repo.productCalls.map((c) => c.cursor), [null, 'c1']);
      notifier.dispose();
    });

    test('a new sort starts from the first page', () async {
      final notifier = ProductListingNotifier(
        repo,
        query: const ProductListingQuery(),
      );
      await pumpEventQueue();
      await notifier.loadMore();
      await notifier.applyQuery(
        const ProductListingQuery(sort: ProductSort.priceDesc),
      );

      expect(repo.productCalls.last.cursor, isNull);
      expect(repo.productCalls.last.query.sort, ProductSort.priceDesc);
      expect(notifier.state.activeQuery.sort, ProductSort.priceDesc);
      notifier.dispose();
    });

    test('ignores a response for a query that was replaced', () async {
      final slow = Completer<void>();
      repo.nextProductsGate = slow;
      final notifier = ProductListingNotifier(
        repo,
        query: const ProductListingQuery(),
      );
      await notifier.applyQuery(
        const ProductListingQuery(sort: ProductSort.rating),
      );
      slow.complete();
      await pumpEventQueue();
      expect(notifier.state.activeQuery.sort, ProductSort.rating);
      notifier.dispose();
    });

    test('a failed page keeps the items and flags a retry', () async {
      var failNext = false;
      repo.onProducts = (call) => failNext
          ? left(_offline)
          : right(productPage(['a', 'b'], cursor: 'c1'));
      final notifier = ProductListingNotifier(
        repo,
        query: const ProductListingQuery(),
      );
      await pumpEventQueue();
      failNext = true;
      await notifier.loadMore();

      final data = notifier.state.maybeWhen(
        loadSuccess: (d) => d,
        orElse: () => null,
      )!;
      expect(data.products, hasLength(2));
      expect(data.loadMoreFailed, isTrue);
      expect(data.hasMore, isTrue);
      notifier.dispose();
    });
  });

  group('CollectionNotifier', () {
    test('pages items in once each', () async {
      final repo = FakeMallCatalogRepository(
        onCollection: (call) => right(
          call.cursor == null
              ? _collection(['a', 'b', 'c'], cursor: 'next')
              : _collection(['c', 'd']),
        ),
      );
      final notifier = CollectionNotifier(repo, slug: 'edit');
      await pumpEventQueue();
      await notifier.loadMore();

      final data = notifier.state.maybeWhen(
        loadSuccess: (d) => d,
        orElse: () => null,
      )!;
      expect(data.items.map((i) => i.product.id), ['a', 'b', 'c', 'd']);
      expect(data.hasMore, isFalse);
      expect(repo.collectionCalls.last, (slug: 'edit', cursor: 'next'));
      notifier.dispose();
    });

    test('not found is a failure', () async {
      final repo = FakeMallCatalogRepository(
        onCollection: (_) => left(const NetworkExceptions.notFound()),
      );
      final notifier = CollectionNotifier(repo, slug: 'gone');
      await pumpEventQueue();
      expect(
        notifier.state,
        const CollectionState.loadFailure(NetworkExceptions.notFound()),
      );
      notifier.dispose();
    });
  });

  group('ReelProductsNotifier', () {
    test('loads the reel detail', () async {
      final reel = Reel(
        id: 'r-1',
        sourceUrl: '',
        thumbnailUrl: '',
        creatorId: 'a-1',
        creatorName: 'Priya',
        creatorAvatarUrl: '',
        caption: '',
        musicTitle: '',
        musicArtist: '',
        taggedProducts: const [],
        likeCount: 0,
        commentCount: 0,
        shareCount: 0,
        createdAt: DateTime(2026),
      );
      final notifier = ReelProductsNotifier(
        _FakeReelsRepository(right(reel)),
        reelId: 'r-1',
      );
      await pumpEventQueue();
      expect(notifier.state, ReelProductsState.loadSuccess(reel));
      notifier.dispose();
    });
  });

  // RecentlyViewedRecorder is covered in recently_viewed_recorder_test.dart.
  // It now takes a consent gate as well as a repository, and the cases that
  // matter most are the ones where the write must not happen at all, so its
  // tests live beside the other memory-purpose fakes.
}
