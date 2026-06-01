import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/data/datasources/creator_dashboard_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/data/repositories/creator_dashboard_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/repositories/creator_dashboard_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/notifiers/creator_dashboard_notifier.dart';

export 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/notifiers/creator_dashboard_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — creator dashboard feature
// ============================================================================

final creatorDashboardRemoteDataSourceProvider =
    Provider<CreatorDashboardRemoteDataSource>(
      (ref) => CreatorDashboardRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final creatorDashboardRepositoryProvider =
    Provider<CreatorDashboardRepository>(
      (ref) => CreatorDashboardRepositoryImpl(
        remoteDataSource: ref.watch(creatorDashboardRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final creatorDashboardNotifierProvider =
    StateNotifierProvider<CreatorDashboardNotifier, DashboardState>(
      (ref) => CreatorDashboardNotifier(
        ref.watch(creatorDashboardRepositoryProvider),
      ),
    );
