import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/repositories/reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_like_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';

final reelsRemoteDataSourceProvider = Provider<ReelsRemoteDataSource>(
  (ref) => ReelsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => ReelsRepositoryImpl(
    remoteDataSource: ref.watch(reelsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final reelsFeedNotifierProvider =
    StateNotifierProvider<ReelsFeedNotifier, ReelsFeedState>(
      (ref) => ReelsFeedNotifier(ref.watch(reelsRepositoryProvider)),
    );

/// StyleMint likes on reels, shared by every rail showing the same reel.
final reelLikeNotifierProvider =
    StateNotifierProvider<ReelLikeNotifier, Map<String, ReelLikeState>>(
      (ref) => ReelLikeNotifier(ref.watch(reelsRepositoryProvider)),
    );

/// One reel by id, for `/reels/:reelId` (StyleMint share links). Throws the
/// typed [NetworkExceptions] so the screen can tell "not found" apart.
// ignore: specify_nonobvious_property_types
final reelDetailProvider = FutureProvider.autoDispose.family<Reel, String>(
  (ref, reelId) async =>
      (await ref.watch(reelsRepositoryProvider).getReelDetail(reelId)).fold(
        // ignore: only_throw_errors
        (failure) => throw failure,
        (reel) => reel,
      ),
);

/// Bumped each time the Home (reels) tab is tapped while already on it.
/// The reels feed listens to this to refresh its content and scroll to top.
final homeTabReselectedProvider = StateProvider<int>((ref) => 0);
