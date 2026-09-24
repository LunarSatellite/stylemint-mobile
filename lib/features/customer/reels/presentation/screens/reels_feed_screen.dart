import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/feed_signal_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_view_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Home Page Reel — vertical, full-screen reels feed (Figma node 9386-5224).
///
/// The reels play in a [ReelsPager]; its controller lives as long as this
/// screen, so the embedded players warm up while the feed loads and survive a
/// refresh.
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  ConsumerState<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends ConsumerState<ReelsFeedScreen> {
  final ReelsPagerController _pager = ReelsPagerController();

  /// Held rather than read on demand: the pager reports the last reel's
  /// dwell while the screen is being disposed, and a provider cannot be
  /// looked up from a deactivated element.
  late final FeedSignalRecorder _signals;

  /// Held for the same reason as [_signals]: the last reel's dwell arrives
  /// during dispose, and that is exactly the watch worth counting.
  late final ReelViewRecorder _views;

  @override
  void initState() {
    super.initState();
    _signals = ref.read(feedSignalRecorderProvider);
    _views = ref.read(reelViewRecorderProvider);
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  /// Scroll back to the first reel and refetch the feed. Triggered when the
  /// user re-taps the Home tab while already on the reels screen.
  void _refresh() {
    _pager.jumpToStart();
    unawaited(ref.read(reelsFeedNotifierProvider.notifier).fetchFeed());
  }

  @override
  Widget build(BuildContext context) {
    // Refresh + scroll to top when the Home tab is re-tapped.
    ref.listen<int>(homeTabReselectedProvider, (_, _) => _refresh());

    final state = ref.watch(reelsFeedNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (reels) {
          if (reels.isEmpty) {
            return const SmEmptyState(
              message: 'No reels yet. Check back soon for new content.',
              icon: Icons.video_library_outlined,
            );
          }
          return ReelsPager(
            controller: _pager,
            reels: reels,
            onNearEnd: () => unawaited(
              ref.read(reelsFeedNotifierProvider.notifier).fetchNextPage(),
            ),
            // One signal per reel the viewer leaves, and only when the dwell
            // actually says something. The same dwell is what the creator's
            // view count is built from — before this, nothing in the app ever
            // called the views endpoint, so every reel sat at zero views
            // forever.
            onReelDwell: (reel, dwell) {
              _signals.reelDwell(reel.id, dwell);
              _views.recordDwell(reel, dwell);
            },
          );
        },
        loadFailure: (failure) {
          // Previously this fell through to the same "No reels yet" empty
          // state as a genuinely-empty feed for every failure type — making
          // real errors (parsing exceptions, 500s, etc.) indistinguishable
          // from "there's just nothing to show" and impossible to diagnose
          // from the UI alone.
          final message = failure.isNoInternet
              ? 'No internet connection.'
              : 'Failed to load reels. Please try again.';
          return SmErrorView(
            message: message,
            onRetry: () =>
                ref.read(reelsFeedNotifierProvider.notifier).fetchFeed(),
          );
        },
      ),
    );
  }

  Widget _loader() => const SmPageLoader();
}
