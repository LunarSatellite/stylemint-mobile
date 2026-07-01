import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/datasources/analytics_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_dashboard_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_overview_notifier.dart';

final analyticsRemoteDataSourceProvider = Provider<AnalyticsRemoteDataSource>(
  (ref) => AnalyticsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepositoryImpl(
    remoteDataSource: ref.watch(analyticsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final creatorDashboardNotifierProvider =
    StateNotifierProvider<CreatorDashboardNotifier, CreatorDashboardState>(
  (ref) => CreatorDashboardNotifier(ref.watch(analyticsRepositoryProvider)),
);

final creatorOverviewNotifierProvider =
    StateNotifierProvider<CreatorOverviewNotifier, CreatorOverviewState>(
  (ref) => CreatorOverviewNotifier(ref.watch(analyticsRepositoryProvider)),
);
