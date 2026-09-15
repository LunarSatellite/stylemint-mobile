import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/catalog_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/datasources/storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/repositories/storefront_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_page.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/repositories/storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/notifiers/storefront_paged_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';
import 'package:url_launcher/url_launcher.dart';

/// Connectivity check for storefront repositories; tests pin it online.
final storefrontNetworkInfoProvider = Provider<NetworkInfoConnectivity>(
  (ref) => NetworkInfoConnectivityImpl(connectivity: Connectivity()),
);

final storefrontRemoteDataSourceProvider = Provider<StorefrontRemoteDataSource>(
  (ref) => StorefrontRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final storefrontRepositoryProvider = Provider<StorefrontRepository>(
  (ref) => StorefrontRepositoryImpl(
    remoteDataSource: ref.watch(storefrontRemoteDataSourceProvider),
    followApi: ref.watch(followApiProvider),
    networkInfo: ref.watch(storefrontNetworkInfoProvider),
  ),
);

/// The signed-in account id, or null for guests.
final storefrontViewerAccountIdProvider = Provider<String?>(
  (ref) => ref
      .watch(sessionControllerProvider)
      .maybeWhen(authenticated: (id) => id, orElse: () => null),
);

/// A creator's public reels in one sort order.
typedef CreatorReelsKey = ({String accountId, CreatorReelSort sort});

/// Owner and kind of a storefront collection list.
typedef StorefrontCollectionsKey = ({
  StorefrontOwnerKind ownerKind,
  String ownerAccountId,
  CollectionKind kind,
});

// The family provider types are long and repeat the right-hand side.
// ignore: specify_nonobvious_property_types
final creatorReelsProvider = StateNotifierProvider.autoDispose
    .family<
      StorefrontPagedNotifier<StorefrontReel>,
      StorefrontPagedState<StorefrontReel>,
      CreatorReelsKey
    >((ref, key) {
      final repository = ref.watch(storefrontRepositoryProvider);
      return StorefrontPagedNotifier<StorefrontReel>(
        (cursor) => repository.getCreatorReels(
          key.accountId,
          sort: key.sort,
          cursor: cursor,
        ),
        idOf: (reel) => reel.id,
      );
    });

/// Public reels tagging a vendor's products ("As seen on creators").
// ignore: specify_nonobvious_property_types
final vendorReelsProvider = StateNotifierProvider.autoDispose
    .family<
      StorefrontPagedNotifier<StorefrontReel>,
      StorefrontPagedState<StorefrontReel>,
      String
    >((ref, vendorAccountId) {
      final repository = ref.watch(storefrontRepositoryProvider);
      return StorefrontPagedNotifier<StorefrontReel>(
        (cursor) => repository.getVendorReels(vendorAccountId, cursor: cursor),
        idOf: (reel) => reel.id,
      );
    });

/// A creator's or brand's live collections of one kind.
// ignore: specify_nonobvious_property_types
final storefrontCollectionsProvider = StateNotifierProvider.autoDispose
    .family<
      StorefrontPagedNotifier<StorefrontCollection>,
      StorefrontPagedState<StorefrontCollection>,
      StorefrontCollectionsKey
    >((ref, key) {
      final repository = ref.watch(storefrontRepositoryProvider);
      return StorefrontPagedNotifier<StorefrontCollection>(
        (cursor) => repository.getCollections(
          ownerKind: key.ownerKind,
          ownerAccountId: key.ownerAccountId,
          kind: key.kind,
          cursor: cursor,
        ),
        idOf: (collection) => collection.slug,
      );
    });

/// Products of `GET v1/public/products` for one exact query (a brand's
/// listing with its sort and filters).
// ignore: specify_nonobvious_property_types
final storefrontProductsProvider = StateNotifierProvider.autoDispose
    .family<
      StorefrontPagedNotifier<CatalogProduct>,
      StorefrontPagedState<CatalogProduct>,
      ProductListingQuery
    >((ref, query) {
      final repository = ref.watch(mallCatalogRepositoryProvider);
      return StorefrontPagedNotifier<CatalogProduct>((cursor) async {
        final result = await repository.getProducts(
          query,
          cursor: cursor,
          pageSize: storefrontProductPageSize,
        );
        return result.map(
          (page) => StorefrontPage(
            items: page.items,
            nextCursor: page.nextCursor,
            totalCount: page.totalCount,
          ),
        );
      }, idOf: (product) => product.id);
    });

const int storefrontProductPageSize = 20;

/// What a storefront hands to the phone: the share sheet and external links.
abstract interface class StorefrontExternalActions {
  Future<void> share({required String text, required String subject});

  /// Opens an https link outside the app; false when it didn't open.
  Future<bool> open(Uri uri);
}

class PlatformStorefrontExternalActions implements StorefrontExternalActions {
  const PlatformStorefrontExternalActions();

  @override
  Future<void> share({required String text, required String subject}) async {
    await SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Future<bool> open(Uri uri) async {
    if (uri.scheme != 'https') return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

final storefrontExternalActionsProvider = Provider<StorefrontExternalActions>(
  (ref) => const PlatformStorefrontExternalActions(),
);
