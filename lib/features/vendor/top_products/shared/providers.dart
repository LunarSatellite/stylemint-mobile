import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/data/datasources/vendor_top_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/data/repositories/vendor_top_products_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/repositories/vendor_top_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/presentation/notifiers/vendor_top_products_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/top_products/presentation/notifiers/vendor_top_products_notifier.dart';

final vendorTopProductsRemoteDataSourceProvider =
    Provider<VendorTopProductsRemoteDataSource>(
      (ref) => VendorTopProductsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorTopProductsRepositoryProvider =
    Provider<VendorTopProductsRepository>(
      (ref) => VendorTopProductsRepositoryImpl(
        remoteDataSource: ref.watch(vendorTopProductsRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final vendorTopProductsNotifierProvider =
    StateNotifierProvider<VendorTopProductsNotifier, VendorTopProductsState>(
      (ref) =>
          VendorTopProductsNotifier(ref.watch(vendorTopProductsRepositoryProvider)),
    );
