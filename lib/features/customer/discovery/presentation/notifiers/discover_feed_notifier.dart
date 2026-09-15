import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feed.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_feed_sources.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';

/// The feed under the selected chip.
sealed class DiscoverFeedState {
  const DiscoverFeedState();
}

final class DiscoverFeedLoading extends DiscoverFeedState {
  const DiscoverFeedLoading();
}

final class DiscoverFeedFailure extends DiscoverFeedState {
  const DiscoverFeedFailure(this.failure);

  final NetworkExceptions failure;
}

@immutable
final class DiscoverFeedLoaded extends DiscoverFeedState {
  const DiscoverFeedLoaded({
    required this.blocks,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<DiscoverBlock> blocks;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get canLoadMore => hasMore && !isLoadingMore && !loadMoreFailed;

  DiscoverFeedLoaded copyWith({bool? isLoadingMore, bool? loadMoreFailed}) =>
      DiscoverFeedLoaded(
        blocks: blocks,
        hasMore: hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
      );
}

@immutable
class DiscoverState {
  const DiscoverState({
    required this.chips,
    required this.selected,
    required this.feed,
  });

  final List<DiscoverChip> chips;
  final DiscoverChip selected;
  final DiscoverFeedState feed;

  DiscoverState copyWith({
    List<DiscoverChip>? chips,
    DiscoverChip? selected,
    DiscoverFeedState? feed,
  }) => DiscoverState(
    chips: chips ?? this.chips,
    selected: selected ?? this.selected,
    feed: feed ?? this.feed,
  );
}

class _FeedSession {
  _FeedSession(this.source);

  final DiscoverFeedSource source;
  DiscoverFeedState state = const DiscoverFeedLoading();
}

/// The Discover chips and their feeds. Each chip keeps its feed (and paging)
/// for the session, so switching back is instant; answers for a chip that is
/// no longer selected only fill its cache. The home page is fetched once and
/// shared by For You, Reels, Creators, Brands and the category chips.
class DiscoverFeedNotifier extends StateNotifier<DiscoverState> {
  DiscoverFeedNotifier({
    required MallHomeRepository homeRepository,
    required MallCatalogRepository catalogRepository,
    required DiscoverRepository discoverRepository,
    bool loadOnCreate = true,
  }) : _homeRepository = homeRepository,
       _catalog = catalogRepository,
       _discover = discoverRepository,
       super(
         const DiscoverState(
           chips: DiscoverChip.fixed,
           selected: DiscoverKindChip(DiscoverFeedKind.forYou),
           feed: DiscoverFeedLoading(),
         ),
       ) {
    if (loadOnCreate) unawaited(_start(state.selected));
  }

  /// Top home categories shown as chips after the fixed ones.
  static const int maxCategoryChips = 6;

  final MallHomeRepository _homeRepository;
  final MallCatalogRepository _catalog;
  final DiscoverRepository _discover;
  final Map<String, _FeedSession> _sessions = {};

  MallHome? _home;
  Future<Either<NetworkExceptions, MallHome>>? _homeRequest;

  Future<void> select(DiscoverChip chip) async {
    if (chip == state.selected) return;
    final session = _sessions[chip.key];
    state = state.copyWith(
      selected: chip,
      feed: session?.state ?? const DiscoverFeedLoading(),
    );
    if (session == null || session.state is DiscoverFeedFailure) {
      await _start(chip);
    }
  }

  /// Loads the selected chip's feed again after a failure.
  Future<void> retry() => _start(state.selected);

  /// Pull to refresh: forgets every cached feed and the home page.
  Future<void> refresh() {
    _home = null;
    _homeRequest = null;
    _sessions.clear();
    return _start(state.selected);
  }

  /// Appends the next blocks; no-op while loading, after a failed page (use
  /// [retryLoadMore]) or at the end.
  Future<void> loadMore() => _append(retrying: false);

  Future<void> retryLoadMore() => _append(retrying: true);

  Future<void> _start(DiscoverChip chip) async {
    final session = _FeedSession(_sourceFor(chip));
    _sessions[chip.key] = session;
    _emit(chip, session, const DiscoverFeedLoading());
    final result = await session.source.first();
    if (!mounted) return;
    _emit(
      chip,
      session,
      result.fold<DiscoverFeedState>(
        DiscoverFeedFailure.new,
        (blocks) => DiscoverFeedLoaded(
          blocks: blocks,
          hasMore: session.source.hasMore,
        ),
      ),
    );
  }

  Future<void> _append({required bool retrying}) async {
    final chip = state.selected;
    final session = _sessions[chip.key];
    final feed = session?.state;
    if (session == null ||
        feed is! DiscoverFeedLoaded ||
        !feed.hasMore ||
        feed.isLoadingMore ||
        (feed.loadMoreFailed && !retrying)) {
      return;
    }
    _emit(
      chip,
      session,
      feed.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    final result = await session.source.more(feed.blocks);
    if (!mounted) return;
    _emit(
      chip,
      session,
      result.fold<DiscoverFeedState>(
        (_) => feed.copyWith(isLoadingMore: false, loadMoreFailed: true),
        (blocks) => DiscoverFeedLoaded(
          blocks: blocks,
          hasMore: session.source.hasMore,
        ),
      ),
    );
  }

  void _emit(
    DiscoverChip chip,
    _FeedSession session,
    DiscoverFeedState feed,
  ) {
    // A refresh replaced this session: drop its late answer.
    if (!identical(_sessions[chip.key], session)) return;
    session.state = feed;
    final chips = _chips();
    if (state.selected == chip) {
      state = state.copyWith(feed: feed, chips: chips);
    } else if (!listEquals(chips, state.chips)) {
      state = state.copyWith(chips: chips);
    }
  }

  DiscoverFeedSource _sourceFor(DiscoverChip chip) => switch (chip) {
    DiscoverKindChip(kind: DiscoverFeedKind.forYou) => ForYouFeedSource(
      _loadHome,
      _catalog,
    ),
    DiscoverKindChip(kind: DiscoverFeedKind.trending) => ListingFeedSource(
      _catalog,
      const ProductListingQuery(sort: ProductSort.bestselling),
      eyebrow: 'Trending',
      title: 'Bestselling right now',
    ),
    DiscoverKindChip(kind: DiscoverFeedKind.newDrops) => ListingFeedSource(
      _catalog,
      const ProductListingQuery(),
      eyebrow: 'New drops',
      title: 'Just landed',
    ),
    DiscoverKindChip(kind: DiscoverFeedKind.sale) => ListingFeedSource(
      _catalog,
      const ProductListingQuery(onSale: true),
      eyebrow: 'Sale',
      title: 'On sale now',
    ),
    DiscoverKindChip(kind: DiscoverFeedKind.collections) =>
      CollectionsFeedSource(_discover),
    DiscoverKindChip(:final kind) => HomeFeedSource(_loadHome, kind),
    DiscoverCategoryChip(:final category) => ListingFeedSource(
      _catalog,
      ProductListingQuery(
        categorySlug: category.slug.isEmpty ? null : category.slug,
        categoryId: category.slug.isEmpty ? category.id : null,
      ),
      eyebrow: 'Category',
      title: category.name,
    ),
  };

  Future<Either<NetworkExceptions, MallHome>> _loadHome() async {
    final cached = _home;
    if (cached != null) return right(cached);
    final request = _homeRequest ??= _homeRepository.getHome();
    final result = await request;
    if (identical(_homeRequest, request)) {
      _homeRequest = null;
      _home = result.getRight().toNullable();
    }
    return result;
  }

  List<DiscoverChip> _chips() {
    final home = _home;
    if (home == null) return state.chips;
    final seen = <String>{};
    final categories = [
      for (final section in home.sections.whereType<HomeCategoriesSection>())
        for (final category in section.items)
          if (category.name.trim().isNotEmpty) DiscoverCategoryChip(category),
    ].where((chip) => seen.add(chip.key)).take(maxCategoryChips);
    return [...DiscoverChip.fixed, ...categories];
  }
}
