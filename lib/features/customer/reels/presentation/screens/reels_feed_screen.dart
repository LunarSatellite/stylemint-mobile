import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/feed_signal_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/home_mode_switch.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/reel_view_recorder.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reels_pager.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Home Page Reel — vertical, full-screen reels feed (Figma node 9386-5224).
///
/// The reels play in a [ReelsPager]; its controller lives as long as this
/// screen, so the embedded players warm up while the feed loads and survive a
/// refresh.
///
/// When anyone the viewer can see has an active story, a [StoriesTray] is
/// pinned across the top, under Home's "Mall | Reels" switch — the way
/// Instagram and Facebook put stories above everything else. It belongs to
/// the first reel: swipe on and it steps aside so the video has the screen,
/// swipe back (or pull to refresh, or re-tap Home) and it returns. With no
/// stories there is no tray, no scrim and nothing in the way.
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  /// The stories tray's wrapper — present only while there are stories.
  static const Key storiesTrayKey = Key('reels-stories-tray');

  /// How tall the overlay-style tray draws (bubble, ring and name). Used to
  /// keep the first reel's rail clear of it; the tray itself sizes freely.
  static const double storiesTrayExtent = 104;

  /// How quickly the tray steps aside and comes back.
  static const Duration storiesTrayMotion = Duration(milliseconds: 200);

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

  /// Whether anyone has an active story, as of the last answer the stories
  /// feed gave. Held through a reload rather than dropped, so a refresh does
  /// not blink the scrim off and back or make the first reel's rail jump.
  bool _hasStories = false;

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
    unawaited(_refreshStories());
    unawaited(ref.read(reelsFeedNotifierProvider.notifier).fetchFeed());
  }

  /// Stories ride along with every reels refresh: whoever just posted should
  /// show up when the viewer asks for something new, not only on the next
  /// cold start. Never awaited by a refresh — the spinner speaks for the
  /// reels, and a slow stories call must not hold it up.
  Future<void> _refreshStories() =>
      ref.read(storiesNotifierProvider.notifier).loadStoryGroups();

  @override
  Widget build(BuildContext context) {
    // Refresh + scroll to top when the Home tab is re-tapped.
    ref.listen<int>(homeTabReselectedProvider, (_, _) => _refresh());

    // The same rule the tray's hideWhenEmpty draws by — any story group at
    // all — read here too because the scrim, the tray's touch area and the
    // first reel's rail clearance all have to agree with whether it shows.
    _hasStories = ref
        .watch(storiesNotifierProvider)
        .when(
          initial: () => _hasStories,
          loadInProgress: () => _hasStories,
          loadSuccess: (groups) => groups.isNotEmpty,
          loadFailure: (_) => false,
        );

    final state = ref.watch(reelsFeedNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (reels) {
          if (reels.isEmpty) {
            // No reels is no reason to hide who has a story: the tray still
            // sits at the top, and stays put — there is no reel to leave.
            return _withStoriesTray(
              const SmEmptyState(
                message: 'No reels yet. Check back soon for new content.',
                icon: Icons.video_library_outlined,
              ),
            );
          }
          return _withStoriesTray(
            ReelsPager(
              controller: _pager,
              reels: reels,
              // While the tray is up the first reel's rail keeps below it, so
              // nothing on the rail ends up under the tray, out of reach.
              firstReelTopClearance: _hasStories
                  ? homeTopInset(context) +
                        ReelsFeedScreen.storiesTrayExtent +
                        DesignTokens.s8
                  : 0,
              onNearEnd: () => unawaited(
                ref.read(reelsFeedNotifierProvider.notifier).fetchNextPage(),
              ),
              // Pull down on the first reel to reload. Re-tapping the Home tab
              // still works and still jumps to the top, but it was the ONLY
              // way to refresh — undiscoverable, and unavailable whenever the
              // reels screen was reached from anywhere but that tab.
              onRefresh: () {
                unawaited(_refreshStories());
                return ref
                    .read(reelsFeedNotifierProvider.notifier)
                    .refreshFeedInPlace();
              },
              // One signal per reel the viewer leaves, and only when the dwell
              // actually says something. The same dwell is what the creator's
              // view count is built from — before this, nothing in the app
              // ever called the views endpoint, so every reel sat at zero
              // views forever.
              onReelDwell: (reel, dwell) {
                _signals.reelDwell(reel.id, dwell);
                _views.recordDwell(reel, dwell);
              },
            ),
            page: _pager.currentPage,
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

  /// [content] with the stories tray laid over its top, when there are
  /// stories. Over the pager the tray follows [page]; with no [page] it
  /// simply stays.
  ///
  /// Laid over rather than stacked above in a Column: shrinking the pager to
  /// make room would resize every page — and every embedded player placed
  /// against those pages — each time the tray came or went.
  ///
  /// The Stack is there with or without stories, and [content] is always its
  /// first child, so stories arriving (or running out) only adds or drops the
  /// overlay. Returning [content] bare when there are none would remount the
  /// pager the moment the first story loads — a new PageView position, which
  /// throws the viewer back to the first reel mid-feed.
  Widget _withStoriesTray(Widget content, {ValueListenable<int>? page}) =>
      Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (_hasStories)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ReelsStoriesOverlay(
                page: page,
                trayTop: homeTopInset(context),
              ),
            ),
        ],
      );

  Widget _loader() => const SmPageLoader();
}

/// The stories tray over the reels, with a soft top scrim so its white names
/// read over a bright video.
///
/// Shown while [page] is on the first reel (always, with no [page]). Hidden,
/// it slides up and fades out, and ignores the pointer outright: an invisible
/// tray must never eat a tap meant for the reel beneath it.
///
/// Shown, only the tray itself takes touches. The scrim never does, and
/// neither does the band above the tray (status bar and Home's switch row,
/// which sit on top of this anyway). Because the tray is drawn above the
/// pager rather than inside it, a drag that starts on the tray is the
/// tray's: sideways it scrolls the bubbles, and the vertical pager never
/// enters the gesture arena for it.
class _ReelsStoriesOverlay extends StatelessWidget {
  const _ReelsStoriesOverlay({required this.trayTop, this.page});

  final ValueListenable<int>? page;

  /// Where the tray starts: below the status bar and Home's switch row.
  final double trayTop;

  @override
  Widget build(BuildContext context) {
    final page = this.page;
    if (page == null) return _overlay(context, visible: true);
    return ValueListenableBuilder<int>(
      valueListenable: page,
      builder: (context, index, _) => _overlay(context, visible: index == 0),
    );
  }

  Widget _overlay(BuildContext context, {required bool visible}) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : ReelsFeedScreen.storiesTrayMotion;
    return IgnorePointer(
      key: ReelsFeedScreen.storiesTrayKey,
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: DesignTokens.motionCurve,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, -0.5),
          duration: duration,
          curve: DesignTokens.motionCurve,
          child: Stack(
            children: [
              // From the very top of the screen down past the tray: keeps
              // white names legible over a bright video, and the status bar
              // and the switch above it with them.
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Color(0x59000000),
                          Color(0x00000000),
                        ],
                        stops: [0, 0.65, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                // The extra room underneath is where the scrim fades out; it
                // takes no touches (padding never does).
                padding: EdgeInsets.only(
                  top: trayTop,
                  bottom: DesignTokens.s16,
                ),
                child: const StoriesTray(
                  style: StoriesTrayStyle.overlay,
                  hideWhenEmpty: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
