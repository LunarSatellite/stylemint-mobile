import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/repositories/reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_landing_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_like_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_view_recorder.dart';

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

/// `/reels/:reelId` (StyleMint share links): the landed reel, then related
/// reels, then the general feed. Disposed with the screen.
// The family's provider type is long and says nothing the right side doesn't.
// ignore: specify_nonobvious_property_types
final reelLandingNotifierProvider = StateNotifierProvider.autoDispose
    .family<ReelLandingNotifier, ReelLandingState, String>(
      (ref, reelId) => ReelLandingNotifier(
        ref.watch(reelsRepositoryProvider),
        reelId: reelId,
      ),
    );

/// Bumped each time the Home (reels) tab is tapped while already on it.
/// The reels feed listens to this to refresh its content and scroll to top.
final homeTabReselectedProvider = StateProvider<int>((ref) => 0);

/// Posts a view for each reel a viewer actually watches. Built per screen so
/// its "already counted" memory lasts exactly as long as the visit.
final reelViewRecorderProvider = Provider.autoDispose<ReelViewRecorder>(
  (ref) => ReelViewRecorder(ref.watch(reelsRepositoryProvider)),
);
