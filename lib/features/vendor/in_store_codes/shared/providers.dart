import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/datasources/vendor_codes_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/repositories/vendor_codes_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/entities/code_stats.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/domain/repositories/vendor_codes_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/notifiers/vendor_code_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/notifiers/vendor_code_notifier.dart';

final vendorCodesRemoteDataSourceProvider =
    Provider<VendorCodesRemoteDataSource>(
      (ref) =>
          VendorCodesRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final vendorCodesRepositoryProvider = Provider<VendorCodesRepository>(
  (ref) => VendorCodesRepositoryImpl(
    remoteDataSource: ref.watch(vendorCodesRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// The code for a product in a store, or for a store.
final vendorCodeNotifierProvider = StateNotifierProvider.autoDispose
    .family<VendorCodeNotifier, VendorCodeState, VendorCodeTarget>(
      (ref, target) =>
          VendorCodeNotifier(ref.watch(vendorCodesRepositoryProvider), target),
    );

/// Scan counts for a code. A failure comes back as a Left, so Riverpod
/// never retries on its own.
final vendorCodeStatsProvider = FutureProvider.autoDispose
    .family<Either<NetworkExceptions, CodeStats>, String>(
      (ref, code) => ref.watch(vendorCodesRepositoryProvider).getStats(code),
    );
