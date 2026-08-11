import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/data/datasources/creator_search_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/data/repositories/creator_search_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/domain/repositories/creator_search_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/search/presentation/notifiers/creator_search_notifier.dart';

final creatorSearchRemoteDataSourceProvider =
    Provider<CreatorSearchRemoteDataSource>(
  (ref) => CreatorSearchRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  ),
);

final creatorSearchRepositoryProvider = Provider<CreatorSearchRepository>(
  (ref) => CreatorSearchRepositoryImpl(
    remoteDataSource: ref.watch(creatorSearchRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final creatorSearchNotifierProvider =
    StateNotifierProvider.autoDispose<CreatorSearchNotifier, CreatorSearchState>(
  (ref) => CreatorSearchNotifier(ref.watch(creatorSearchRepositoryProvider)),
);
