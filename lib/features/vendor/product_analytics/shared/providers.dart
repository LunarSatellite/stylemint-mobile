import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/data/datasources/vendor_product_analytics_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/data/repositories/vendor_product_analytics_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/repositories/vendor_product_analytics_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/presentation/notifiers/vendor_product_analytics_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/product_analytics/presentation/notifiers/vendor_product_analytics_notifier.dart';

final vendorProductAnalyticsRemoteDataSourceProvider =
    Provider<VendorProductAnalyticsRemoteDataSource>(
      (ref) => VendorProductAnalyticsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorProductAnalyticsRepositoryProvider =
    Provider<VendorProductAnalyticsRepository>(
      (ref) => VendorProductAnalyticsRepositoryImpl(
        remoteDataSource: ref.watch(vendorProductAnalyticsRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final vendorProductAnalyticsNotifierProvider = StateNotifierProvider.autoDispose<
  VendorProductAnalyticsNotifier,
  VendorProductAnalyticsState
>(
  (ref) => VendorProductAnalyticsNotifier(
    ref.watch(vendorProductAnalyticsRepositoryProvider),
  ),
);
