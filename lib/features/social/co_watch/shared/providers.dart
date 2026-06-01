import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/data/datasources/co_watch_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/data/repositories/co_watch_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/repositories/co_watch_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/presentation/notifiers/co_watch_notifier.dart';

final coWatchRemoteDataSourceProvider = Provider<CoWatchRemoteDataSource>(
  (ref) => CoWatchRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final coWatchRepositoryProvider = Provider<CoWatchRepository>(
  (ref) => CoWatchRepositoryImpl(
    remoteDataSource: ref.watch(coWatchRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final coWatchSessionsNotifierProvider =
    StateNotifierProvider<CoWatchNotifier, CoWatchSessionsState>(
  (ref) => CoWatchNotifier(ref.watch(coWatchRepositoryProvider)),
);

final coWatchSessionDetailNotifierProvider = StateNotifierProvider.family<
    CoWatchSessionDetailNotifier, CoWatchSessionDetailState, String>(
  (ref, sessionId) => CoWatchSessionDetailNotifier(
    ref.watch(coWatchRepositoryProvider),
    sessionId,
  ),
);
