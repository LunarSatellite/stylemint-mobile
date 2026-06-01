import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/data/datasources/tips_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/data/repositories/tips_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/repositories/tips_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/presentation/notifiers/tips_notifier.dart';

final tipsRemoteDataSourceProvider = Provider<TipsRemoteDataSource>(
  (ref) => TipsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final tipsRepositoryProvider = Provider<TipsRepository>(
  (ref) => TipsRepositoryImpl(
    remoteDataSource: ref.watch(tipsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final tipsNotifierProvider =
    StateNotifierProvider<TipsNotifier, TipHistoryState>(
  (ref) => TipsNotifier(ref.watch(tipsRepositoryProvider)),
);

final tipBalanceNotifierProvider =
    StateNotifierProvider<TipBalanceNotifier, TipBalanceState>(
  (ref) => TipBalanceNotifier(ref.watch(tipsRepositoryProvider)),
);
