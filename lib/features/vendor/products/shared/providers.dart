import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/datasources/vendor_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/repositories/vendor_products_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/repositories/vendor_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';

final vendorProductsRemoteDataSourceProvider =
    Provider<VendorProductsRemoteDataSource>(
  (ref) =>
      VendorProductsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final vendorProductsRepositoryProvider = Provider<VendorProductsRepository>(
  (ref) => VendorProductsRepositoryImpl(
    remoteDataSource: ref.watch(vendorProductsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final vendorProductsNotifierProvider =
    StateNotifierProvider<VendorProductsNotifier, ProductsState>(
  (ref) =>
      VendorProductsNotifier(ref.watch(vendorProductsRepositoryProvider)),
);
