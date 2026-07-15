import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/datasources/earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/repositories/earnings_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';

final earningsRemoteDataSourceProvider = Provider<EarningsRemoteDataSource>(
  (ref) => EarningsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

/// Month-to-date earnings summary: total earned, sales count, avg per sale,
/// and highest reel earnings. Source: GET /v1/earnings/summary.
final monthlyEarningsSummaryProvider =
    FutureProvider.autoDispose<MonthlySummary>((ref) {
  return ref.watch(earningsRemoteDataSourceProvider).getMonthlySummary();
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

final payoutHistoryProvider =
    FutureProvider.autoDispose<List<PayoutRecord>>((ref) async {
  final result = await ref.watch(earningsRepositoryProvider).getPayouts();
  return result.fold((f) => throw f, (records) => records);
});

final addPayoutMethodNotifierProvider =
    StateNotifierProvider.autoDispose<AddPayoutMethodNotifier, AsyncValue<void>>(
      (ref) => AddPayoutMethodNotifier(ref.watch(earningsRepositoryProvider)),
    );

/// Fetches the structured invoice for a single payout.
/// Keyed by payoutId so each invoice screen gets its own instance.
final payoutInvoiceNotifierProvider = StateNotifierProvider.autoDispose
    .family<PayoutInvoiceNotifier, PayoutInvoiceState, String>(
  (ref, payoutId) => PayoutInvoiceNotifier(
    ref.watch(earningsRepositoryProvider),
    payoutId,
  ),
);

/// One-shot notifier for cancelling a Requested payout.
final cancelPayoutNotifierProvider =
    StateNotifierProvider.autoDispose<CancelPayoutNotifier, CancelPayoutState>(
      (ref) => CancelPayoutNotifier(ref.watch(earningsRepositoryProvider)),
    );
