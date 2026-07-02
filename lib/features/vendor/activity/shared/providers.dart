import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/data/datasources/vendor_activity_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/data/repositories/vendor_activity_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/domain/repositories/vendor_activity_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/presentation/notifiers/vendor_activity_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/activity/presentation/notifiers/vendor_activity_notifier.dart';

final vendorActivityRemoteDataSourceProvider = Provider<VendorActivityRemoteDataSource>(
  (ref) => VendorActivityRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final vendorActivityRepositoryProvider = Provider<VendorActivityRepository>(
  (ref) => VendorActivityRepositoryImpl(
    remoteDataSource: ref.watch(vendorActivityRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Small preview feed for the dashboard's "Recent Activity" card.
final vendorActivityPreviewNotifierProvider =
    StateNotifierProvider<VendorActivityNotifier, VendorActivityState>(
      (ref) => VendorActivityNotifier(ref.watch(vendorActivityRepositoryProvider), pageSize: 5),
    );

/// Fuller feed for the standalone Recent Activity screen.
final vendorActivityNotifierProvider =
    StateNotifierProvider<VendorActivityNotifier, VendorActivityState>(
      (ref) => VendorActivityNotifier(ref.watch(vendorActivityRepositoryProvider), pageSize: 50),
    );
