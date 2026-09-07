import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/data/datasources/creator_activity_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/data/repositories/creator_activity_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/domain/repositories/creator_activity_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/presentation/notifiers/creator_activity_notifier.dart';

final creatorActivityRemoteDataSourceProvider =
    Provider<CreatorActivityRemoteDataSource>(
  (ref) => CreatorActivityRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  ),
);

final creatorActivityRepositoryProvider =
    Provider<CreatorActivityRepository>(
  (ref) => CreatorActivityRepositoryImpl(
    remoteDataSource: ref.watch(creatorActivityRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final creatorActivityNotifierProvider =
    StateNotifierProvider.autoDispose<CreatorActivityNotifier,
        CreatorActivityState>(
  (ref) =>
      CreatorActivityNotifier(ref.watch(creatorActivityRepositoryProvider)),
);
