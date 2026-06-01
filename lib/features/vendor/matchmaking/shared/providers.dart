import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/datasources/matchmaking_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/data/repositories/matchmaking_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/repositories/matchmaking_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/notifiers/matchmaking_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/shared/providers.dart'
    as partnerships;

final matchmakingRemoteDataSourceProvider =
    Provider<MatchmakingRemoteDataSource>(
      (ref) => MatchmakingRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final matchmakingRepositoryProvider = Provider<MatchmakingRepository>(
  (ref) => MatchmakingRepositoryImpl(
    remoteDataSource: ref.watch(matchmakingRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final matchmakingNotifierProvider =
    StateNotifierProvider<MatchmakingNotifier, RecommendationsState>(
      (ref) => MatchmakingNotifier(
        ref.watch(matchmakingRepositoryProvider),
      ),
    );

final inviteCreatorNotifierProvider =
    StateNotifierProvider<InviteCreatorNotifier, InviteState>(
      (ref) => InviteCreatorNotifier(
        ref.watch(matchmakingRepositoryProvider),
      ),
    );

final vendorCampaignsProvider =
    partnerships.vendorPartnershipsNotifierProvider;
