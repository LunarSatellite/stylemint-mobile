import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/data/datasources/vendor_dashboard_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/data/repositories/vendor_dashboard_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/repositories/vendor_dashboard_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/notifiers/vendor_dashboard_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/notifiers/vendor_dashboard_notifier.dart';

final vendorDashboardRemoteDataSourceProvider =
    Provider<VendorDashboardRemoteDataSource>(
      (ref) => VendorDashboardRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorDashboardRepositoryProvider =
    Provider<VendorDashboardRepository>(
      (ref) => VendorDashboardRepositoryImpl(
        remoteDataSource: ref.watch(vendorDashboardRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final vendorDashboardNotifierProvider =
    StateNotifierProvider<VendorDashboardNotifier, VendorDashboardState>(
      (ref) => VendorDashboardNotifier(
        ref.watch(vendorDashboardRepositoryProvider),
      ),
    );
