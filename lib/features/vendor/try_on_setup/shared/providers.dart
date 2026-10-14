import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/data/datasources/vendor_try_on_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/data/repositories/vendor_try_on_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/entities/vendor_try_on.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/domain/repositories/vendor_try_on_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/try_on_setup/presentation/notifiers/vendor_try_on_setup_notifier.dart';

final vendorTryOnRemoteDataSourceProvider =
    Provider<VendorTryOnRemoteDataSource>(
      (ref) =>
          VendorTryOnRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final vendorTryOnRepositoryProvider = Provider<VendorTryOnRepository>(
  (ref) => VendorTryOnRepositoryImpl(
    remote: ref.watch(vendorTryOnRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final vendorTryOnSetupNotifierProvider = StateNotifierProvider.autoDispose
    .family<VendorTryOnSetupNotifier, VendorTryOnSetupState, String>(
      (ref, productId) => VendorTryOnSetupNotifier(
        ref.watch(vendorTryOnRepositoryProvider),
        productId,
      ),
    );

/// Readiness for the wizard's "Try-on & sizes" card. Null when it could not
/// be read (the card then just offers the setup screen).
final vendorTryOnReadinessProvider = FutureProvider.autoDispose
    .family<TryOnReadiness?, String>((ref, productId) async {
      final result = await ref
          .watch(vendorTryOnRepositoryProvider)
          .getReadiness(productId);
      return result.fold((_) => null, (r) => r);
    });
