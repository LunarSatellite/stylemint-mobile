import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/data/datasources/brand_storefront_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/data/repositories/brand_storefront_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/repositories/brand_storefront_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/notifiers/brand_storefront_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';

final brandStorefrontRemoteDataSourceProvider =
    Provider<BrandStorefrontRemoteDataSource>(
      (ref) => BrandStorefrontRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final brandStorefrontRepositoryProvider = Provider<BrandStorefrontRepository>(
  (ref) => BrandStorefrontRepositoryImpl(
    remoteDataSource: ref.watch(brandStorefrontRemoteDataSourceProvider),
    networkInfo: ref.watch(storefrontNetworkInfoProvider),
  ),
);

/// A brand's storefront hero, disposed with the page.
// The family provider type is long and repeats the right-hand side.
// ignore: specify_nonobvious_property_types
final brandStorefrontNotifierProvider = StateNotifierProvider.autoDispose
    .family<BrandStorefrontNotifier, BrandStorefrontState, String>(
      (ref, vendorAccountId) => BrandStorefrontNotifier(
        ref.watch(brandStorefrontRepositoryProvider),
        ref.watch(storefrontRepositoryProvider),
        vendorAccountId: vendorAccountId,
        onFollowSummary: (summary) => ref
            .read(followNotifierProvider.notifier)
            .seed(vendorAccountId, following: summary.isFollowedByViewer),
      ),
    );
