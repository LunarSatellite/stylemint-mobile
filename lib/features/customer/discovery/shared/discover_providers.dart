import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discover_feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/recent_searches_local_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discover_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_feedback.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discover_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/not_interested_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/recent_searches_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/search_suggest_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';

final discoverFeedRemoteDataSourceProvider =
    Provider<DiscoverFeedRemoteDataSource>(
      (ref) =>
          DiscoverFeedRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final discoverRepositoryProvider = Provider<DiscoverRepository>(
  (ref) => DiscoverRepositoryImpl(
    remoteDataSource: ref.watch(discoverFeedRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final recentSearchesStoreProvider = Provider<RecentSearchesStore>(
  (ref) => const SharedPreferencesRecentSearchesStore(),
);

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>(
      (ref) => RecentSearchesNotifier(ref.watch(recentSearchesStoreProvider)),
    );

/// Live suggestions for the Discover search field.
// The autoDispose provider type is long and says nothing the right side
// doesn't.
// ignore: specify_nonobvious_property_types
final searchSuggestNotifierProvider =
    StateNotifierProvider.autoDispose<
      SearchSuggestNotifier,
      SearchSuggestState
    >((ref) => SearchSuggestNotifier(ref.watch(discoverRepositoryProvider)));

/// Chips and feeds, kept for the session. Rebuilt when the viewer signs in
/// or out so For You is personalised (or no longer is).
final discoverFeedNotifierProvider =
    StateNotifierProvider<DiscoverFeedNotifier, DiscoverState>((ref) {
      ref.watch(mallViewerSignedInProvider);
      return DiscoverFeedNotifier(
        homeRepository: ref.watch(mallHomeRepositoryProvider),
        catalogRepository: ref.watch(mallCatalogRepositoryProvider),
        discoverRepository: ref.watch(discoverRepositoryProvider),
      );
    });

/// Cards hidden with "Not interested"; seeded from the account when signed
/// in.
final notInterestedNotifierProvider =
    StateNotifierProvider<NotInterestedNotifier, Set<NotInterestedTarget>>((
      ref,
    ) {
      final notifier = NotInterestedNotifier(
        ref.watch(discoverRepositoryProvider),
      );
      if (ref.watch(mallViewerSignedInProvider)) {
        unawaited(notifier.loadSaved());
      }
      return notifier;
    });

/// Resolves true when the viewer is (or becomes) signed in.
typedef DiscoverAuthGate =
    Future<bool> Function(BuildContext context, WidgetRef ref);

/// The sign-in gate for feedback actions; tests replace it.
final discoverAuthGateProvider = Provider<DiscoverAuthGate>(
  (ref) =>
      (context, widgetRef) =>
          ensureAuth(context, widgetRef, reason: AuthReason.general),
);

enum DiscoverProductLayout { grid, list }

/// Grid or list for product results; holds for the session.
final discoverProductLayoutProvider = StateProvider<DiscoverProductLayout>(
  (ref) => DiscoverProductLayout.grid,
);
