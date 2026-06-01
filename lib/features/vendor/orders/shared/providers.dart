import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/repositories/vendor_orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';

final vendorOrdersRemoteDataSourceProvider =
    Provider<VendorOrdersRemoteDataSource>(
  (ref) =>
      VendorOrdersRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final vendorOrdersRepositoryProvider = Provider<VendorOrdersRepository>(
  (ref) => VendorOrdersRepositoryImpl(
    remoteDataSource: ref.watch(vendorOrdersRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final vendorOrdersNotifierProvider =
    StateNotifierProvider<VendorOrdersNotifier, OrdersState>(
  (ref) => VendorOrdersNotifier(ref.watch(vendorOrdersRepositoryProvider)),
);

final vendorOrderDetailNotifierProvider =
    StateNotifierProvider<VendorOrderDetailNotifier, OrderDetailState>(
  (ref) =>
      VendorOrderDetailNotifier(ref.watch(vendorOrdersRepositoryProvider)),
);
