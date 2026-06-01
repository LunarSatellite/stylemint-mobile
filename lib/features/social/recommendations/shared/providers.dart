import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/data/datasources/recommendations_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/data/repositories/recommendations_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/domain/repositories/recommendations_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/presentation/notifiers/recommendations_notifier.dart';

// ============================================================================
// DEPENDENCY INJECTION — recommendations feature
// ============================================================================

final recommendationsRemoteDataSourceProvider =
    Provider<RecommendationsRemoteDataSource>(
      (ref) => RecommendationsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepositoryImpl(
    remoteDataSource: ref.watch(recommendationsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final recommendationsNotifierProvider =
    StateNotifierProvider<RecommendationsNotifier, RecommendationsState>(
      (ref) =>
          RecommendationsNotifier(ref.watch(recommendationsRepositoryProvider)),
    );
