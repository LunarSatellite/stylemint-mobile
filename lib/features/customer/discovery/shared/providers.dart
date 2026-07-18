import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/customer_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/datasources/discovery_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/repositories/discovery_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/related_products_notifier.dart';

final discoveryRemoteDataSourceProvider = Provider<DiscoveryRemoteDataSource>(
  (ref) => DiscoveryRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => DiscoveryRepositoryImpl(
    remoteDataSource: ref.watch(discoveryRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final discoverNotifierProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>(
      (ref) => DiscoverNotifier(ref.watch(discoveryRepositoryProvider)),
    );

final productDetailNotifierProvider = StateNotifierProvider.family<
  ProductDetailNotifier,
  ProductDetailState,
  String
>((ref, productId) => ProductDetailNotifier(ref.watch(discoveryRepositoryProvider)));

final relatedProductsProvider = StateNotifierProvider.family<
  RelatedProductsNotifier,
  RelatedProductsState,
  String
>((ref, productId) => RelatedProductsNotifier(
    ref.watch(discoveryRepositoryProvider),
    productId: productId,
  ));

final customerSearchRemoteDataSourceProvider =
    Provider<CustomerSearchRemoteDataSource>(
  (ref) => CustomerSearchRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// Real search results for the given query, keyed so each distinct query
/// string gets its own cached fetch.
final customerSearchResultsProvider = FutureProvider.autoDispose
    .family<CustomerSearchResults, String>((ref, query) {
  return ref.watch(customerSearchRemoteDataSourceProvider).search(query);
});
