import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/datasources/saved_items_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/data/repositories/saved_items_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/repositories/saved_items_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_items_notifier.dart';

final savedItemsRemoteDataSourceProvider = Provider<SavedItemsRemoteDataSource>(
  (ref) => SavedItemsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final savedItemsRepositoryProvider = Provider<SavedItemsRepository>(
  (ref) => SavedItemsRepositoryImpl(
    remoteDataSource: ref.watch(savedItemsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final savedItemsNotifierProvider =
    StateNotifierProvider<SavedItemsNotifier, SavedItemsState>(
  (ref) => SavedItemsNotifier(ref.watch(savedItemsRepositoryProvider)),
);
