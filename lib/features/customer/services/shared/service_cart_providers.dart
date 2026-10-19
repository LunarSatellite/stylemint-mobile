import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/datasources/service_cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/repositories/service_cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/service_cart_repository.dart';

final serviceCartRemoteDataSourceProvider =
    Provider<ServiceCartRemoteDataSource>(
      (ref) =>
          ServiceCartRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

/// Stays and trips in the cart and at checkout (service cart contract v1).
final serviceCartRepositoryProvider = Provider<ServiceCartRepository>(
  (ref) => ServiceCartRepositoryImpl(
    remote: ref.watch(serviceCartRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);
