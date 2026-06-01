import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/datasources/reel_studio_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/repositories/reel_studio_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/repositories/reel_studio_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/notifiers/reel_studio_notifier.dart';

final reelStudioRemoteDataSourceProvider =
    Provider<ReelStudioRemoteDataSource>(
      (ref) => ReelStudioRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final reelStudioRepositoryProvider = Provider<ReelStudioRepository>(
  (ref) => ReelStudioRepositoryImpl(
    remoteDataSource: ref.watch(reelStudioRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final reelStudioNotifierProvider =
    StateNotifierProvider<ReelStudioNotifier, ReelStudioState>(
      (ref) => ReelStudioNotifier(ref.watch(reelStudioRepositoryProvider)),
    );

final createDraftNotifierProvider =
    StateNotifierProvider<CreateDraftNotifier, CreateDraftState>(
      (ref) => CreateDraftNotifier(ref.watch(reelStudioRepositoryProvider)),
    );
