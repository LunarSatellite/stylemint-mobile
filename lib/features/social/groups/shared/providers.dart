import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/data/datasources/groups_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/data/repositories/groups_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/repositories/groups_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/presentation/notifiers/groups_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — groups feature
// ============================================================================

final groupsRemoteDataSourceProvider = Provider<GroupsRemoteDataSource>(
  (ref) => GroupsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepositoryImpl(
    remoteDataSource: ref.watch(groupsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final groupsNotifierProvider =
    StateNotifierProvider<GroupsNotifier, GroupsViewState>(
      (ref) => GroupsNotifier(ref.watch(groupsRepositoryProvider)),
    );
