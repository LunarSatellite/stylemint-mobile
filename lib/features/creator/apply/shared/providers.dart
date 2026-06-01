import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/datasources/creator_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/repositories/creator_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/repositories/creator_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_apply_notifier.dart';

export 'package:stylemint_mobile_frontend/features/creator/apply/presentation/notifiers/creator_apply_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — creator apply feature
// ============================================================================

final creatorApplyRemoteDataSourceProvider = Provider<CreatorRemoteDataSource>(
  (ref) => CreatorRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final creatorRepositoryProvider = Provider<CreatorRepository>(
  (ref) => CreatorRepositoryImpl(
    remoteDataSource: ref.watch(creatorApplyRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final creatorApplyNotifierProvider =
    StateNotifierProvider<CreatorApplyNotifier, ApplicationStatusState>(
      (ref) => CreatorApplyNotifier(ref.watch(creatorRepositoryProvider)),
    );
