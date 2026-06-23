import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/repositories/reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/mock_reels_repository.dart';

final reelsRemoteDataSourceProvider = Provider<ReelsRemoteDataSource>(
  (ref) => ReelsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

// Using MockReelsRepository for development/demo (static data, no API needed).
// To restore the real network implementation, replace the body below with:
//
//   ReelsRepositoryImpl(
//     remoteDataSource: ref.watch(reelsRemoteDataSourceProvider),
//     networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
//   )
//
final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => MockReelsRepository(),
);

final reelsFeedNotifierProvider =
    StateNotifierProvider<ReelsFeedNotifier, ReelsFeedState>(
      (ref) => ReelsFeedNotifier(ref.watch(reelsRepositoryProvider)),
    );

/// Bumped each time the Home (reels) tab is tapped while already on it.
/// The reels feed listens to this to refresh its content and scroll to top.
final homeTabReselectedProvider = StateProvider<int>((ref) => 0);
