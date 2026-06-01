import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/data/datasources/vendor_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/data/repositories/vendor_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/repositories/vendor_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/notifiers/vendor_apply_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/apply/presentation/notifiers/vendor_apply_notifier.dart';

final vendorApplyRemoteDataSourceProvider = Provider<VendorRemoteDataSource>(
  (ref) => VendorRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final vendorRepositoryProvider = Provider<VendorRepository>(
  (ref) => VendorRepositoryImpl(
    remoteDataSource: ref.watch(vendorApplyRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final vendorApplyNotifierProvider =
    StateNotifierProvider<VendorApplyNotifier, ApplicationState>(
      (ref) => VendorApplyNotifier(ref.watch(vendorRepositoryProvider)),
    );
