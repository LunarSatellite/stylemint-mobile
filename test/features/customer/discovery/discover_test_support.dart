import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/recent_searches_local_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/search_suggestions.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/discover_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';

import '../mall_home/mall_test_support.dart';

class FakeDiscoverRepository implements DiscoverRepository {
  FakeDiscoverRepository({this.onSuggest, this.onCollections});

  Either<NetworkExceptions, SearchSuggestions> Function(String query)?
  onSuggest;
  Either<NetworkExceptions, CatalogPage<HomeCollection>> Function(
    String? cursor,
  )?
  onCollections;

  Either<NetworkExceptions, Unit> markResult = right(unit);
  Either<NetworkExceptions, Unit> undoResult = right(unit);

  final List<String> suggestCalls = [];
  final List<String?> collectionCalls = [];
  final List<NotInterestedTarget> marked = [];
  final List<NotInterestedTarget> undone = [];
  final List<(String, ReelReportReason)> reported = [];

  /// Held by the next mark call only.
  Completer<void>? markGate;

  @override
  Future<Either<NetworkExceptions, SearchSuggestions>> suggest(
    String query, {
    int limit = 8,
  }) async {
    suggestCalls.add(query);
    return onSuggest?.call(query) ?? right(SearchSuggestions(query: query));
  }

  @override
  Future<Either<NetworkExceptions, CatalogPage<HomeCollection>>>
  getCollections({String? cursor, int pageSize = 20}) async {
    collectionCalls.add(cursor);
    return onCollections?.call(cursor) ?? right(const CatalogPage(items: []));
  }

  @override
  Future<Either<NetworkExceptions, Unit>> markNotInterested(
    NotInterestedTarget target, {
    String? reason,
  }) async {
    marked.add(target);
    final gate = markGate;
    markGate = null;
    await gate?.future;
    return markResult;
  }

  @override
  Future<Either<NetworkExceptions, Unit>> undoNotInterested(
    NotInterestedTarget target,
  ) async {
    undone.add(target);
    return undoResult;
  }

  @override
  Future<Either<NetworkExceptions, List<NotInterestedSignal>>>
  getNotInterested() async => right(const []);

  @override
  Future<Either<NetworkExceptions, Unit>> reportReel(
    String reelId,
    ReelReportReason reason,
  ) async {
    reported.add((reelId, reason));
    return right(unit);
  }
}

class MemoryRecentSearchesStore implements RecentSearchesStore {
  MemoryRecentSearchesStore([List<String> initial = const []])
    : saved = [...initial];

  List<String> saved;

  @override
  Future<List<String>> read() async => saved;

  @override
  Future<void> write(List<String> terms) async => saved = [...terms];
}

/// Every group filled; no image URLs (widget tests have no network).
SearchSuggestions sampleSuggestions(String query) => SearchSuggestions(
  query: query,
  products: [
    SuggestedProduct(id: 'sp-1', name: 'GlowBloom Face Oil', price: rs(1800)),
  ],
  brands: const [
    SuggestedBrand(vendorAccountId: 'v-9', name: 'GlowBloom', isVerified: true),
  ],
  creators: const [
    SuggestedCreator(
      accountId: 'a-9',
      displayName: 'Asha Rai',
      handle: 'glowwithasha',
    ),
  ],
  categories: const [
    SuggestedCategory(
      id: 'cat-9',
      slug: 'glow-skincare',
      name: 'Glow Skincare',
    ),
  ],
  hashtags: const [SuggestedHashtag(tag: 'glowup', usageCount: 42)],
);

/// Pumps the Discover tab (`/search`) over [sampleHome] with fakes.
Future<void> pumpDiscover(
  WidgetTester tester, {
  FakeMallHomeRepository? home,
  FakeMallCatalogRepository? catalog,
  FakeDiscoverRepository? discover,
  MemoryRecentSearchesStore? recents,
  bool signedIn = true,
  double width = 390,
  double? height,
  double textScale = 1,
  List<Object> overrides = const [],
}) => pumpMallApp(
  tester,
  location: '/search',
  width: width,
  height: height,
  textScale: textScale,
  routes: [
    GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
    GoRoute(
      path: '/search-results',
      builder: (_, state) => Scaffold(
        body: Center(child: Text('results:${state.uri.queryParameters['q']}')),
      ),
    ),
    GoRoute(
      path: '/brands/:vendorAccountId',
      builder: (_, state) => Scaffold(
        body: Center(
          child: Text('brand:${state.pathParameters['vendorAccountId']}'),
        ),
      ),
    ),
  ],
  overrides: [
    mallHomeRepositoryProvider.overrideWithValue(
      home ?? FakeMallHomeRepository([right(sampleHome())]),
    ),
    mallCatalogRepositoryProvider.overrideWithValue(
      catalog ??
          FakeMallCatalogRepository(
            onProducts: (_) => right(productPage(const [])),
          ),
    ),
    discoverRepositoryProvider.overrideWithValue(
      discover ?? FakeDiscoverRepository(),
    ),
    recentSearchesStoreProvider.overrideWithValue(
      recents ?? MemoryRecentSearchesStore(),
    ),
    mallViewerSignedInProvider.overrideWithValue(signedIn),
    discoverAuthGateProvider.overrideWithValue((_, _) async => signedIn),
    ...overrides,
  ],
);
