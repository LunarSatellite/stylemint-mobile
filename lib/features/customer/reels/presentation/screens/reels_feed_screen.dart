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
/// When anyone the viewer can see has an active story, a strip of
/// [StoriesTray] bubbles sits ABOVE the first reel, directly under Home's
/// "Mall | Reels" switch — the way Instagram and Facebook put stories above
/// everything else. It is a solid block with its own height, not something
/// laid over the video: the first reel is laid out below it, that much
/// shorter, and nothing of the strip covers any part of a reel.
///
/// The strip belongs to the first reel. Swipe on and, once the next reel has
/// come to rest, it collapses so every later reel has the whole screen; swipe
/// back (or pull to refresh, or re-tap Home) and it opens again. With no
/// stories there is no strip and the first reel is full height, exactly as
/// before stories existed.
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  /// The stories strip's wrapper — present only while there are stories (or
  /// while the strip is still closing after they ran out).
  static const Key storiesTrayKey = Key('reels-stories-tray');

  /// How tall the stories row in the strip is: [StoriesTray]'s surface style
  /// (a 72 bubble, a 4 gap, a 16 label and 8 above and below). The strip is
  /// this plus Home's top band, and the reel beneath it gives up exactly that
  /// much. Fixed rather than measured, so the reel's own top inset can follow
  /// the strip frame by frame as it opens and closes.
  static const double storiesTrayExtent = 108;

  /// How quickly the strip closes and opens again.
  static const Duration storiesStripMotion = Duration(milliseconds: 220);

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
  /// not snap the strip shut and open again, resizing the first reel twice.
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
    // all — read here too because the strip's height, and so the first reel's,
    // has to agree with whether the tray shows.
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
            // No reels is no reason to hide who has a story: the strip still
            // sits above the message, and stays open — there is no reel to
            // leave.
            return _withStoriesStrip(
              const SmEmptyState(
                message: 'No reels yet. Check back soon for new content.',
                icon: Icons.video_library_outlined,
              ),
            );
          }
          return _withStoriesStrip(
            ReelsPager(
              controller: _pager,
              reels: reels,
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
            settledPage: _pager.settledPage,
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

  /// [content] laid out below the stories strip.
  ///
  /// Over the pager the strip is open while [settledPage] rests on the first
  /// reel and closed on every other; with no [settledPage] (the empty feed)
  /// it simply stays open. It follows the page the pager has come to REST on,
  /// not the one it is passing through, so the pager's viewport only grows or
  /// shrinks once a swipe has finished: the PageView keeps its page index
  /// across that resize, and the embedded players follow the same settled
  /// page, so nothing jumps.
  ///
  /// The same layout is there with or without stories, and [content] keeps
  /// its place in it, so stories arriving (or running out) only opens or
  /// closes the strip. Returning [content] bare when there are none would
  /// remount the pager the moment the first story loads — a new PageView
  /// position, which throws the viewer back to the first reel mid-feed.
  Widget _withStoriesStrip(
    Widget content, {
    ValueListenable<int>? settledPage,
  }) {
    final hasStories = _hasStories;
    if (settledPage == null) {
      return _ReelsStoriesStrip(
        hasStories: hasStories,
        open: hasStories,
        content: content,
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: settledPage,
      child: content,
      builder: (context, page, child) => _ReelsStoriesStrip(
        hasStories: hasStories,
        open: hasStories && page == 0,
        content: child!,
      ),
    );
  }

  Widget _loader() => const SmPageLoader();
}

/// The stories strip above the reels, and [content] below it.
///
/// The strip is a solid block: the height of Home's top band (the status bar
/// and the "Mall | Reels" switch row — the switch floats over this band) plus
/// the stories row. [content] gets the height that is left, so the first reel
/// is laid out below the strip instead of under it.
///
/// Opening and closing animate the strip's height over
/// [ReelsFeedScreen.storiesStripMotion], easing out — at once when the
/// platform asks for reduced motion. It is clipped as it closes and stays aligned to its bottom edge,
/// so the bubbles slide up and away like content scrolling off the top. It
/// ignores the pointer the moment it starts to close: a strip on its way out
/// must never eat a tap meant for the reel growing into its place.
///
/// Because the strip sits outside the pager, a drag that starts on it is the
/// tray's: sideways it scrolls the bubbles, and the vertical pager never
/// enters the gesture arena for it.
///
/// [content]'s top inset follows the strip. While the strip covers the
/// status bar, the reel beneath it has no status bar to keep clear of (a
/// TikTok player, which otherwise starts below the status bar, would leave a
/// black band under the strip). As the strip closes the inset comes back,
/// pixel for pixel, until a later reel has the whole screen and the whole
/// inset, exactly as without stories.
class _ReelsStoriesStrip extends StatelessWidget {
  const _ReelsStoriesStrip({
    required this.hasStories,
    required this.open,
    required this.content,
  });

  /// Whether anyone has an active story at all.
  final bool hasStories;

  /// Whether the strip should be open: there are stories and the viewer is on
  /// the first reel (or there are no reels to leave).
  final bool open;

  final Widget content;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final media = MediaQuery.of(context);
    final band = homeTopInset(context);
    final extent = band + ReelsFeedScreen.storiesTrayExtent;
    return TweenAnimationBuilder<double>(
      // No begin: the first build starts where it should be, so a feed that
      // opens with stories already loaded shows the strip without a flourish.
      tween: Tween<double>(end: open ? 1 : 0),
      duration: reduceMotion
          ? Duration.zero
          : ReelsFeedScreen.storiesStripMotion,
      curve: Curves.easeOut,
      child: content,
      builder: (context, openness, child) {
        final height = extent * openness;
        // What is left of an inset once the strip covers [height] of it.
        double below(double inset) => inset > height ? inset - height : 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height,
              // Built while there are stories, and while a strip whose stories
              // just ran out is still closing — never for a feed with none.
              child: hasStories || openness > 0
                  ? IgnorePointer(
                      key: ReelsFeedScreen.storiesTrayKey,
                      ignoring: !open,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.bottomCenter,
                          minHeight: extent,
                          maxHeight: extent,
                          child: ColoredBox(
                            color: DesignTokens.bgAppFoundation,
                            child: Padding(
                              padding: EdgeInsets.only(top: band),
                              child: const StoriesTray(hideWhenEmpty: true),
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(
              child: MediaQuery(
                data: media.copyWith(
                  padding: media.padding.copyWith(
                    top: below(media.padding.top),
                  ),
                  viewPadding: media.viewPadding.copyWith(
                    top: below(media.viewPadding.top),
                  ),
                ),
                child: child!,
              ),
            ),
          ],
        );
      },
    );
  }
}
