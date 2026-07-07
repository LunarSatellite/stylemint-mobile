import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/datasources/creator_performance_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/repositories/creator_performance_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/repositories/creator_performance_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/notifiers/creator_performance_notifier.dart';

export 'package:stylemint_mobile_frontend/features/vendor/creator_performance/presentation/notifiers/creator_performance_notifier.dart';

final creatorPerformanceRemoteDataSourceProvider =
    Provider<CreatorPerformanceRemoteDataSource>(
      (ref) => CreatorPerformanceRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final creatorPerformanceRepositoryProvider =
    Provider<CreatorPerformanceRepository>(
      (ref) => CreatorPerformanceRepositoryImpl(
        remoteDataSource: ref.watch(creatorPerformanceRemoteDataSourceProvider),
        networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
      ),
    );

final creatorPerformanceNotifierProvider =
    StateNotifierProvider<CreatorPerformanceNotifier, CreatorPerformanceState>(
      (ref) => CreatorPerformanceNotifier(
        ref.watch(creatorPerformanceRepositoryProvider),
      ),
    );
