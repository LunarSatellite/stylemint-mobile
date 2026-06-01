import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/data/datasources/reach_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/data/repositories/reach_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/repositories/reach_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/presentation/notifiers/reach_notifier.dart';

final reachRemoteDataSourceProvider = Provider<ReachRemoteDataSource>(
  (ref) => ReachRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final reachRepositoryProvider = Provider<ReachRepository>(
  (ref) => ReachRepositoryImpl(
    remoteDataSource: ref.watch(reachRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final reachNotifierProvider =
    StateNotifierProvider<ReachNotifier, ReachState>(
      (ref) => ReachNotifier(ref.watch(reachRepositoryProvider)),
    );

final createBoostNotifierProvider =
    StateNotifierProvider.family<CreateBoostNotifier, CreateBoostState, String>(
      (ref, reelId) => CreateBoostNotifier(
        ref.watch(reachRepositoryProvider),
        reelId: reelId,
      ),
    );
