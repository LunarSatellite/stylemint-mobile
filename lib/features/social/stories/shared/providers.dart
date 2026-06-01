import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/datasources/stories_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/repositories/stories_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';

final storiesRemoteDataSourceProvider = Provider<StoriesRemoteDataSource>(
  (ref) => StoriesRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final storiesRepositoryProvider = Provider<StoriesRepository>(
  (ref) => StoriesRepositoryImpl(
    remoteDataSource: ref.watch(storiesRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final storiesNotifierProvider =
    StateNotifierProvider<StoriesNotifier, StoriesState>(
      (ref) => StoriesNotifier(ref.watch(storiesRepositoryProvider)),
    );
