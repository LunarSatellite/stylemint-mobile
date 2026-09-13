import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/playback/device_memory_tier.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_layer.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_scope.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

/// Home Page Reel — vertical, full-screen reels feed (Figma node 9386-5224).
///
/// Tracks the visible reel index so only the active [ReelCard] plays.
/// Embedded reels (YouTube, TikTok, Facebook) share a small pool of players
/// hosted beneath the pages by [EmbedPlayerLayer]: the reel the feed rests on
/// plays and the next one is cued, so a swipe starts playback without
/// loading a new player.
class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  ConsumerState<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends ConsumerState<ReelsFeedScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final EmbedPlayerPool _embedPool = EmbedPlayerPool();
  int _currentIndex = 0;

  /// The page the feed last came to rest on. Embedded players follow this
  /// rather than [_currentIndex], which changes halfway through a drag.
  int _settledIndex = 0;

  List<Reel> _reels = const [];
  Map<String, int> _embedIndex = const {};
  bool _tabVisible = true;
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      embedSlotCountForDevice().then((count) {
        if (mounted) _embedPool.setCapacity(count);
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _tabVisible) {
      _tabVisible = visible;
      _embedPool.setHostActive(_tabVisible && _appResumed);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    _embedPool.setHostActive(_tabVisible && _appResumed);
  }

  @override
  void didHaveMemoryPressure() => _embedPool.trim();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _embedPool.dispose();
    super.dispose();
  }

  /// Scroll back to the first reel and refetch the feed. Triggered when the
  /// user re-taps the Home tab while already on the reels screen.
  void _refresh() {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    if (_currentIndex != 0 || _settledIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _settledIndex = 0;
      });
    }
    _syncEmbeds();
    unawaited(ref.read(reelsFeedNotifierProvider.notifier).fetchFeed());
  }

  EmbedRequest? _embedAt(int index) {
    if (index < 0 || index >= _reels.length) return null;
    final source = resolveReelPlayback(_reels[index]);
    return source is EmbedSource ? EmbedRequest(source) : null;
  }

  /// Plays the reel the feed rests on (if embedded), cues its neighbours
  /// (next reel first) and warms the next posters.
  void _syncEmbeds() {
    if (!mounted) return;
    if (_reels.isEmpty) {
      _embedPool.setWindow(active: null);
      return;
    }
    _embedPool.setWindow(
      active: _embedAt(_settledIndex),
      neighbours: [
        _embedAt(_settledIndex + 1),
        _embedAt(_settledIndex - 1),
      ].nonNulls.toList(),
    );
    final last = (_settledIndex + 3).clamp(0, _reels.length - 1);
    for (var i = _settledIndex + 1; i <= last; i++) {
      final url = ReelPoster.urlFor(_reels[i]);
      if (url != null) {
        unawaited(precacheImage(CachedNetworkImageProvider(url), context));
      }
    }
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    // Only the feed's own PageView; product strips inside pages scroll too.
    if (notification.depth != 0 || !_pageController.hasClients) return false;
    final page = _pageController.page?.round();
    if (page != null && page != _settledIndex) {
      setState(() => _settledIndex = page);
      _syncEmbeds();
    }
    return false;
  }

  void _adoptReels(List<Reel> reels) {
    if (identical(reels, _reels)) return;
    _reels = reels;
    // Built back to front so the first page holding a video wins.
    _embedIndex = {
      for (var i = reels.length - 1; i >= 0; i--)
        if (_embedAt(i) case final request?) request.key: i,
    };
    if (_settledIndex >= reels.length) _settledIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEmbeds());
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
          _adoptReels(reels);
          if (reels.isEmpty) {
            return const SmEmptyState(
              message: 'No reels yet. Check back soon for new content.',
              icon: Icons.video_library_outlined,
            );
          }
          final padding = MediaQuery.paddingOf(context);
          return EmbedPlayerScope(
            pool: _embedPool,
            child: NotificationListener<ScrollEndNotification>(
              onNotification: _onScrollEnd,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: EmbedPlayerLayer(
                      pool: _embedPool,
                      controller: _pageController,
                      settledIndex: _settledIndex,
                      indexOfKey: (key) => _embedIndex[key],
                      playerRectAt: (index, page) =>
                          reelPlayerRect(reels[index], page, padding),
                    ),
                  ),
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    // Track the drag from the initial touch-down rather than
                    // from where the recognizer eventually "starts" — this
                    // feed's vertical PageView is nested inside
                    // SwipeableBranchView's horizontal one, and starting from
                    // `down` gives the vertical recognizer the full gesture
                    // (and its true velocity) instead of only what's left
                    // after the two axes finish resolving which one owns the
                    // pointer.
                    dragStartBehavior: DragStartBehavior.down,
                    itemCount: reels.length,
                    // Build the adjacent reels offscreen so a native reel's
                    // next video has already initialised by the time it's
                    // swiped into view. (Inactive reels stay paused; only the
                    // active one plays.)
                    allowImplicitScrolling: true,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                      // Page in more reels before the user actually hits the
                      // end — otherwise the feed dead-ends and further swipes
                      // have nothing new to show.
                      if (index >= reels.length - 3) {
                        unawaited(
                          ref
                              .read(reelsFeedNotifierProvider.notifier)
                              .fetchNextPage(),
                        );
                      }
                    },
                    itemBuilder: (_, index) => ReelCard(
                      reel: reels[index],
                      isActive: index == _currentIndex,
                    ),
                  ),
                ],
              ),
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
