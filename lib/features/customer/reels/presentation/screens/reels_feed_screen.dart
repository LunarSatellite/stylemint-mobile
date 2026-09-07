import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';

import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Home Page Reel — vertical, full-screen reels feed (Figma node 9386-5224).
///
/// Tracks the visible reel index so the active [ReelCard] auto-plays its
/// video while all others stay paused.
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  ConsumerState<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends ConsumerState<ReelsFeedScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Scroll back to the first reel and refetch the feed. Triggered when the
  /// user re-taps the Home tab while already on the reels screen.
  void _refresh() {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    if (_currentIndex != 0) setState(() => _currentIndex = 0);
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
          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            // Build the adjacent reels offscreen so the next one's video has
            // already initialised/buffered by the time it's swiped into view —
            // it then plays immediately instead of showing a loading spinner.
            // (Inactive reels stay paused; only the active one plays.)
            allowImplicitScrolling: true,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder:
                (_, index) => ReelCard(
                  reel: reels[index],
                  isActive: index == _currentIndex,
                ),
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
              : 'Failed to load reels: ${failure.toString()}';
          return SmErrorView(
            message: message,
            onRetry: () =>
                ref.read(reelsFeedNotifierProvider.notifier).fetchFeed(),
          );
        },
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
