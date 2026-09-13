import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/datasources/store_actions_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/repositories/store_actions_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/domain/repositories/store_actions_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/presentation/notifiers/store_actions_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/store_actions/presentation/notifiers/store_actions_notifier.dart';

final storeActionsRemoteDataSourceProvider =
    Provider<StoreActionsRemoteDataSource>(
      (ref) =>
          StoreActionsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final storeActionsRepositoryProvider = Provider<StoreActionsRepository>(
  (ref) => StoreActionsRepositoryImpl(
    remoteDataSource: ref.watch(storeActionsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// autoDispose so reopening the screen fetches a fresh list.
final storeActionsNotifierProvider =
    StateNotifierProvider.autoDispose<StoreActionsNotifier, StoreActionsState>(
      (ref) => StoreActionsNotifier(ref.watch(storeActionsRepositoryProvider)),
    );

/// How many store to-dos the vendor has, for the dashboard's Pending Actions
/// row. Null while loading or on any failure (errors swallowed so Riverpod
/// never auto-retries a supplementary count); the row then falls back to a
/// generic description instead of a made-up number.
final storeActionCountProvider = FutureProvider.autoDispose<int?>((ref) async {
  try {
    final result = await ref
        .watch(storeActionsRepositoryProvider)
        .getStoreActions();
    return result.fold((_) => null, (queue) => queue.actions.length);
  } on Object catch (_) {
    return null;
  }
});
