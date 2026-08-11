import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/datasources/earnings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/repositories/earnings_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings_breakdown.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/presentation/notifiers/earnings_notifier.dart';

final earningsRemoteDataSourceProvider = Provider<EarningsRemoteDataSource>(
  (ref) => EarningsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

/// Per-reel earnings breakdown (creator analytics dashboard). Separate from
/// the balance summary because the metrics live on a different endpoint.
/// Throws on failure so `AsyncValue.error` carries the repository's message.
final earningsBreakdownProvider = FutureProvider<EarningsBreakdown>(
  (ref) async =>
      (await ref.watch(earningsRepositoryProvider).getDashboardBreakdown())
          .fold(
        (failure) => throw Exception(NetworkExceptions.getMessage(failure)),
        (breakdown) => breakdown,
      ),
);

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
