import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/datasources/vendor_earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/repositories/vendor_earnings_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/repositories/vendor_earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/presentation/notifiers/vendor_earnings_notifier.dart';

final vendorEarningsRemoteDataSourceProvider =
    Provider<VendorEarningsRemoteDataSource>(
      (ref) => VendorEarningsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final vendorEarningsRepositoryProvider = Provider<VendorEarningsRepository>(
  (ref) => VendorEarningsRepositoryImpl(
    remoteDataSource: ref.watch(vendorEarningsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final vendorEarningsNotifierProvider =
    StateNotifierProvider<VendorEarningsNotifier, EarningsSummaryState>(
      (ref) => VendorEarningsNotifier(
        ref.watch(vendorEarningsRepositoryProvider),
      ),
    );

final ledgerNotifierProvider =
    StateNotifierProvider<LedgerNotifier, LedgerState>(
      (ref) => LedgerNotifier(
        ref.watch(vendorEarningsRepositoryProvider),
      ),
    );

final payoutNotifierProvider =
    StateNotifierProvider<PayoutNotifier, PayoutState>(
      (ref) => PayoutNotifier(
        ref.watch(vendorEarningsRepositoryProvider),
      ),
    );

final payoutMethodsNotifierProvider =
    StateNotifierProvider<PayoutMethodsNotifier, PayoutMethodsState>(
      (ref) => PayoutMethodsNotifier(
        ref.watch(vendorEarningsRepositoryProvider),
      ),
    );
