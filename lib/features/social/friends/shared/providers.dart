import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/data/datasources/friends_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/data/repositories/friends_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/repositories/friends_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/presentation/notifiers/friends_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — friends feature
// ============================================================================

final friendsRemoteDataSourceProvider = Provider<FriendsRemoteDataSource>(
  (ref) => FriendsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepositoryImpl(
    remoteDataSource: ref.watch(friendsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final friendsNotifierProvider =
    StateNotifierProvider<FriendsNotifier, FriendsViewState>(
      (ref) => FriendsNotifier(ref.watch(friendsRepositoryProvider)),
    );
