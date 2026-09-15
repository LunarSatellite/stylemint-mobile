import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/notifiers/storefront_paged_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/datasources/creator_storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/repositories/creator_storefront_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_shop_product.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/repositories/creator_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/presentation/notifiers/creator_storefront_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';

final creatorStorefrontRemoteDataSourceProvider =
    Provider<CreatorStorefrontRemoteDataSource>(
      (ref) => CreatorStorefrontRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final creatorStorefrontRepositoryProvider =
    Provider<CreatorStorefrontRepository>(
      (ref) => CreatorStorefrontRepositoryImpl(
        remoteDataSource: ref.watch(creatorStorefrontRemoteDataSourceProvider),
        networkInfo: ref.watch(storefrontNetworkInfoProvider),
      ),
    );

/// A creator's storefront header, disposed with the page.
// The family provider types are long and repeat the right-hand side.
// ignore: specify_nonobvious_property_types
final creatorStorefrontNotifierProvider = StateNotifierProvider.autoDispose
    .family<CreatorStorefrontNotifier, CreatorStorefrontState, String>(
      (ref, accountId) => CreatorStorefrontNotifier(
        ref.watch(creatorStorefrontRepositoryProvider),
        ref.watch(storefrontRepositoryProvider),
        accountId: accountId,
        onFollowSummary: (summary) => ref
            .read(followNotifierProvider.notifier)
            .seed(accountId, following: summary.isFollowedByViewer),
      ),
    );

/// The creator's live collections.
StorefrontCollectionsKey creatorCollectionsKey(String accountId) => (
  ownerKind: StorefrontOwnerKind.creator,
  ownerAccountId: accountId,
  kind: CollectionKind.creatorCollection,
);

/// The creator's live looks.
StorefrontCollectionsKey creatorLooksKey(String accountId) => (
  ownerKind: StorefrontOwnerKind.creator,
  ownerAccountId: accountId,
  kind: CollectionKind.look,
);

/// Products the creator tagged on public reels.
// ignore: specify_nonobvious_property_types
final creatorShopProvider = StateNotifierProvider.autoDispose
    .family<
      StorefrontPagedNotifier<CreatorShopProduct>,
      StorefrontPagedState<CreatorShopProduct>,
      String
    >((ref, accountId) {
      final repository = ref.watch(creatorStorefrontRepositoryProvider);
      return StorefrontPagedNotifier<CreatorShopProduct>(
        (cursor) => repository.getShop(accountId, cursor: cursor),
        idOf: (product) => product.productId,
      );
    });
