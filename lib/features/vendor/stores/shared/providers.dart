import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/datasources/vendor_stores_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/repositories/vendor_stores_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/repositories/vendor_stores_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/notifiers/vendor_stores_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/notifiers/vendor_stores_notifier.dart';

final vendorStoresRemoteDataSourceProvider =
    Provider<VendorStoresRemoteDataSource>(
      (ref) => VendorStoresRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorStoresRepositoryProvider = Provider<VendorStoresRepository>(
  (ref) => VendorStoresRepositoryImpl(
    remoteDataSource: ref.watch(vendorStoresRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// autoDispose so reopening the stores list (or a product's in-store codes)
/// fetches fresh; screens pushed on top keep it alive meanwhile.
final vendorStoresNotifierProvider =
    StateNotifierProvider.autoDispose<VendorStoresNotifier, VendorStoresState>(
      (ref) => VendorStoresNotifier(ref.watch(vendorStoresRepositoryProvider)),
    );
