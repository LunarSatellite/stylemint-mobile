import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/datasources/in_store_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/data/repositories/in_store_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/repositories/in_store_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/notifiers/product_reels_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/notifiers/store_products_notifier.dart';

export 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/notifiers/product_reels_notifier.dart';
export 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/notifiers/store_products_notifier.dart';

final inStoreRemoteDataSourceProvider = Provider<InStoreRemoteDataSource>(
  (ref) => InStoreRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final inStoreRepositoryProvider = Provider<InStoreRepository>(
  (ref) => InStoreRepositoryImpl(
    remoteDataSource: ref.watch(inStoreRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Reels tagging a product, keyed by product id.
final productReelsNotifierProvider = StateNotifierProvider.autoDispose
    .family<ProductReelsNotifier, ProductReelsState, String>(
      (ref, productId) =>
          ProductReelsNotifier(ref.watch(inStoreRepositoryProvider), productId),
    );

/// A vendor's products for the store screen, keyed by vendor account id.
final StateNotifierProviderFamily<
  StoreProductsNotifier,
  StoreProductsState,
  String
>
storeProductsNotifierProvider = StateNotifierProvider.autoDispose
    .family<StoreProductsNotifier, StoreProductsState, String>(
      (ref, vendorId) =>
          StoreProductsNotifier(ref.watch(inStoreRepositoryProvider), vendorId),
    );
