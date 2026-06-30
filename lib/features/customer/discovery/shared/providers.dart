import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/related_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/mock_discovery_repository.dart';

// Using MockDiscoveryRepository for development/demo (static data, no API needed).
// To restore the real network implementation, replace the body below with:
//
//   DiscoveryRepositoryImpl(
//     remoteDataSource: ref.watch(discoveryRemoteDataSourceProvider),
//     networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
//   )
//
final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => MockDiscoveryRepository(),
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
