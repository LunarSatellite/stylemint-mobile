import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/datasources/shipping_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/data/repositories/shipping_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/domain/repositories/shipping_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/shipping/presentation/notifiers/shipping_notifier.dart';

final shippingRemoteDataSourceProvider = Provider<ShippingRemoteDataSource>(
  (ref) => ShippingRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final shippingRepositoryProvider = Provider<ShippingRepository>(
  (ref) => ShippingRepositoryImpl(
    remoteDataSource: ref.watch(shippingRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final addressNotifierProvider =
    StateNotifierProvider<AddressNotifier, AddressesState>(
      (ref) => AddressNotifier(ref.watch(shippingRepositoryProvider)),
    );
