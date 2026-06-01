import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/datasources/add_product_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/data/repositories/add_product_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/domain/repositories/add_product_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';

final addProductRemoteDataSourceProvider =
    Provider<AddProductRemoteDataSource>(
  (ref) => AddProductRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final addProductRepositoryProvider = Provider<AddProductRepository>(
  (ref) => AddProductRepositoryImpl(
    remoteDataSource: ref.watch(addProductRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final addProductNotifierProvider =
    StateNotifierProvider<AddProductNotifier, AddProductState>(
  (ref) => AddProductNotifier(ref.watch(addProductRepositoryProvider)),
);
