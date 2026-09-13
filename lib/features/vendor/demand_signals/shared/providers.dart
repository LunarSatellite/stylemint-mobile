import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/datasources/demand_signals_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/repositories/demand_signals_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/repositories/demand_signals_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/presentation/notifiers/demand_signals_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/demand_signals/presentation/notifiers/demand_signals_notifier.dart';

final demandSignalsRemoteDataSourceProvider =
    Provider<DemandSignalsRemoteDataSource>(
      (ref) => DemandSignalsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final demandSignalsRepositoryProvider = Provider<DemandSignalsRepository>(
  (ref) => DemandSignalsRepositoryImpl(
    remoteDataSource: ref.watch(demandSignalsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// autoDispose so reopening the screen fetches fresh counts.
final demandSignalsNotifierProvider =
    StateNotifierProvider.autoDispose<
      DemandSignalsNotifier,
      DemandSignalsState
    >((ref) => DemandSignalsNotifier(ref.watch(demandSignalsRepositoryProvider)));
