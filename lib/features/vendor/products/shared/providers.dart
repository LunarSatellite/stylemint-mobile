import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/datasources/vendor_products_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/data/repositories/vendor_products_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/repositories/vendor_products_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';

final vendorProductsRemoteDataSourceProvider =
    Provider<VendorProductsRemoteDataSource>(
      (ref) => VendorProductsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorProductsRepositoryProvider = Provider<VendorProductsRepository>(
  (ref) => VendorProductsRepositoryImpl(
    remoteDataSource: ref.watch(vendorProductsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Carries a repository [NetworkExceptions] out of [vendorProductProvider].
///
/// A FutureProvider reports failure by throwing, and the thing thrown has to
/// be an Exception; `NetworkExceptions` is a plain sealed union and is not
/// one. Readers that care about the reason unwrap [failure].
class VendorProductLoadException implements Exception {
  const VendorProductLoadException(this.failure);

  final NetworkExceptions failure;

  @override
  String toString() => 'VendorProductLoadException($failure)';
}

/// One listing the vendor owns, fetched by id.
///
/// For screens reached without the product travelling on the route:
/// go_router's `extra` is null on a deep link and after the process is
/// restored, and a screen that needs the listing's variant has nothing to
/// work with. Keyed by product id so two listings never share a result, and
/// autoDispose so leaving the screen drops it.
final FutureProviderFamily<VendorProduct, String>
vendorProductProvider = FutureProvider.autoDispose
    .family<VendorProduct, String>((ref, productId) async {
      final result = await ref
          .watch(vendorProductsRepositoryProvider)
          .getProduct(productId);
      return result.fold(
        (failure) => throw VendorProductLoadException(failure),
        (product) => product,
      );
    });

final vendorProductsNotifierProvider =
    StateNotifierProvider<VendorProductsNotifier, ProductsState>(
      (ref) =>
          VendorProductsNotifier(ref.watch(vendorProductsRepositoryProvider)),
    );
