import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/datasources/earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/repositories/earnings_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings_breakdown.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';

final earningsRemoteDataSourceProvider = Provider<EarningsRemoteDataSource>(
  (ref) => EarningsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// Per-reel earnings breakdown (creator analytics dashboard). Separate from
/// the balance summary because the metrics live on a different endpoint.
final earningsBreakdownProvider = FutureProvider<EarningsBreakdown>((ref) {
  return ref.watch(earningsRemoteDataSourceProvider).getDashboardBreakdown();
});

final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => EarningsRepositoryImpl(
    remoteDataSource: ref.watch(earningsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final earningsNotifierProvider =
    StateNotifierProvider<EarningsNotifier, EarningsState>(
      (ref) => EarningsNotifier(ref.watch(earningsRepositoryProvider)),
    );

final requestPayoutNotifierProvider =
    StateNotifierProvider<RequestPayoutNotifier, RequestPayoutState>(
      (ref) => RequestPayoutNotifier(ref.watch(earningsRepositoryProvider)),
    );
