import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/mall_catalog_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/datasources/mall_home_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/repositories/mall_catalog_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/repositories/mall_home_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_catalog_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/home_mode.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/collection_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/mall_home_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/product_listing_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/reel_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/recently_viewed_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';

final mallHomeRemoteDataSourceProvider = Provider<MallHomeRemoteDataSource>(
  (ref) => MallHomeRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final mallHomeRepositoryProvider = Provider<MallHomeRepository>(
  (ref) => MallHomeRepositoryImpl(
    remoteDataSource: ref.watch(mallHomeRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final mallCatalogRemoteDataSourceProvider =
    Provider<MallCatalogRemoteDataSource>(
      (ref) =>
          MallCatalogRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final mallCatalogRepositoryProvider = Provider<MallCatalogRepository>(
  (ref) => MallCatalogRepositoryImpl(
    remoteDataSource: ref.watch(mallCatalogRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// The Mall home page; kept for the session so returning to Home is instant.
final mallHomeNotifierProvider =
    StateNotifierProvider<MallHomeNotifier, MallHomeState>(
      (ref) => MallHomeNotifier(ref.watch(mallHomeRepositoryProvider)),
    );

/// `/products` — one listing per initial query, disposed with its screen.
// The family's provider type is long and says nothing the right side doesn't.
// ignore: specify_nonobvious_property_types
final productListingNotifierProvider = StateNotifierProvider.autoDispose
    .family<ProductListingNotifier, ProductListingState, ProductListingQuery>(
      (ref, query) => ProductListingNotifier(
        ref.watch(mallCatalogRepositoryProvider),
        query: query,
      ),
    );

/// `/collections/:slug`, disposed with its screen.
// ignore: specify_nonobvious_property_types
final collectionNotifierProvider = StateNotifierProvider.autoDispose
    .family<CollectionNotifier, CollectionState, String>(
      (ref, slug) => CollectionNotifier(
        ref.watch(mallCatalogRepositoryProvider),
        slug: slug,
      ),
    );

/// A reel's tagged products for the quick product sheet.
// ignore: specify_nonobvious_property_types
final reelProductsNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReelProductsNotifier, ReelProductsState, String>(
      (ref, reelId) => ReelProductsNotifier(
        ref.watch(reelsRepositoryProvider),
        reelId: reelId,
      ),
    );

/// Mall or Reels under the Home switch. Mall by default; the last choice
/// holds for the rest of the session.
final homeModeProvider = StateProvider<HomeMode>((ref) => HomeMode.mall);

/// Bumped when Home is re-tapped while the Mall is showing: the page scrolls
/// to the top and refreshes. (On Reels the shell bumps
/// `homeTabReselectedProvider` as before.)
final mallHomeReselectedProvider = StateProvider<int>((ref) => 0);

/// Whether someone is signed in. The Mall refetches when this changes so
/// the page is personalised (or no longer is).
final mallViewerSignedInProvider = Provider<bool>(
  (ref) => ref.watch(sessionControllerProvider).isAuthenticated,
);

/// The clock behind the greeting; tests pin it.
final mallClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final recentlyViewedRecorderProvider = Provider<RecentlyViewedRecorder>(
  (ref) => RecentlyViewedRecorder(ref.watch(mallHomeRepositoryProvider)),
);
