import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_card.dart';
import 'package:stylemint_mobile_frontend/shared/playback/device_memory_tier.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_layer.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_scope.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/reel_shapes.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';

/// What a [ReelsPager] keeps while its reels reload: the page position and the
/// pool of embedded players.
///
/// A screen creates one up front, so the players start warming while the
/// first reels are still being fetched and outlive a refresh, and disposes it
/// with the screen. Nothing plays while the app is in the background, and
/// memory pressure frees every player but the one on screen.
class ReelsPagerController with WidgetsBindingObserver {
  ReelsPagerController({EmbedPlayerPool? embedPool})
    : embedPool = embedPool ?? EmbedPlayerPool() {
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      embedSlotCountForDevice().then((count) {
        if (!_disposed) this.embedPool.setCapacity(count);
      }),
    );
  }

  final EmbedPlayerPool embedPool;
  final PageController pageController = PageController();

  int _currentIndex = 0;

  /// The page the pager last came to rest on. Embedded players follow this
  /// rather than the page on screen, which changes halfway through a drag.
  int _settledIndex = 0;

  bool _tabVisible = true;
  bool _appResumed = true;
  bool _disposed = false;
  _ReelsPagerState? _pager;

  /// Back to the first reel, e.g. before a refresh.
  void jumpToStart() {
    if (pageController.hasClients) pageController.jumpToPage(0);
    final pager = _pager;
    if (pager != null) {
      pager._backToStart();
    } else {
      _currentIndex = 0;
      _settledIndex = 0;
    }
  }

  void _setTabVisible(bool visible) {
    if (visible == _tabVisible) return;
    _tabVisible = visible;
    embedPool.setHostActive(_tabVisible && _appResumed);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appResumed = state == AppLifecycleState.resumed;
    embedPool.setHostActive(_tabVisible && _appResumed);
  }

  @override
  void didHaveMemoryPressure() => embedPool.trim();

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    embedPool.dispose();
  }
}

/// Full-screen, vertical reels, one [ReelCard] per page: the Home feed and a
/// shared reel's page.
///
/// Tracks the visible reel so only the active [ReelCard] plays. Embedded reels
/// (YouTube, TikTok, Facebook) share the controller's pool of players, hosted
/// beneath the pages by [EmbedPlayerLayer]: the reel the pager rests on plays
/// and the next one is loaded (and pre-rolled) the moment the pager settles,
/// so a swipe only tells an already-loaded player to play. A TikTok reel up to
/// two pages ahead also warms TikTok's connections.
class ReelsPager extends StatefulWidget {
  const ReelsPager({
    required this.controller,
    required this.reels,
    this.onNearEnd,
    this.onReelDwell,
    this.clock = DateTime.now,
    super.key,
  });

  /// [onNearEnd] fires on landing this many pages or fewer from the last reel.
  static const nearEndPages = 3;

  /// Whether pagers host their embedded players' WebViews. Widget tests turn
  /// this off: they have no WebView platform.
  @visibleForTesting
  static bool debugHostEmbedPlayers = true;

  final ReelsPagerController controller;
  final List<Reel> reels;

  /// Pages in more reels before the viewer hits the end, so the pager never
  /// dead-ends with nothing new to swipe to.
  final VoidCallback? onNearEnd;

  /// How long the viewer stayed on a reel, reported once, when they leave it
  /// (or when the pager goes away under them). This is the only thing the
  /// pager says about attention: it fires per reel, not per frame, and the
  /// caller decides what a given dwell means.
  final void Function(Reel reel, Duration dwell)? onReelDwell;

  /// The clock behind [onReelDwell]; tests pin it.
  final DateTime Function() clock;

  @override
  State<ReelsPager> createState() => _ReelsPagerState();
}

class _ReelsPagerState extends State<ReelsPager> {
  List<Reel> _reels = const [];
  Map<String, int> _embedIndex = const {};

  /// When the reel now on screen arrived.
  DateTime? _dwellSince;
  int _dwellIndex = 0;

  ReelsPagerController get _controller => widget.controller;
  EmbedPlayerPool get _embedPool => widget.controller.embedPool;

  @override
  void initState() {
    super.initState();
    _controller._pager = this;
    _adoptReels(widget.reels);
    _dwellIndex = _controller._currentIndex;
    _dwellSince = widget.clock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller._setTabVisible(TickerMode.valuesOf(context).enabled);
  }

  @override
  void didUpdateWidget(ReelsPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      if (identical(oldWidget.controller._pager, this)) {
        oldWidget.controller._pager = null;
      }
      _controller._pager = this;
    }
    _adoptReels(widget.reels);
  }

  @override
  void dispose() {
    // Leaving the feed ends the current reel's watch as surely as swiping
    // does; without this, the reel someone actually sat through is the one
    // that never counts.
    _reportDwell(_dwellIndex);
    if (identical(_controller._pager, this)) _controller._pager = null;
    super.dispose();
  }

  /// Reports how long [index] was on screen, then starts the next reel's
  /// clock. Reporting twice for the same visit is not possible: the start
  /// time is cleared as it is read.
  void _reportDwell(int index, {int? next}) {
    final since = _dwellSince;
    _dwellSince = null;
    if (since != null && index >= 0 && index < _reels.length) {
      widget.onReelDwell?.call(_reels[index], widget.clock().difference(since));
    }
    if (next != null) {
      _dwellIndex = next;
      _dwellSince = widget.clock();
    }
  }

  void _backToStart() {
    if (_dwellIndex != 0) _reportDwell(_dwellIndex, next: 0);
    if (_controller._currentIndex != 0 || _controller._settledIndex != 0) {
      setState(() {
        _controller
          .._currentIndex = 0
          .._settledIndex = 0;
      });
    }
    _syncEmbeds();
  }

  EmbedRequest? _embedAt(int index) {
    if (index < 0 || index >= _reels.length) return null;
    final source = resolveReelPlayback(_reels[index]);
    return source is EmbedSource ? EmbedRequest(source) : null;
  }

  /// Plays the reel the pager rests on (if embedded), cues its neighbours
  /// (next reel first) and warms the next posters.
  void _syncEmbeds() {
    if (!mounted) return;
    if (_reels.isEmpty) {
      _embedPool.setWindow(active: null);
      return;
    }
    final settled = _controller._settledIndex;
    _embedPool.setWindow(
      active: _embedAt(settled),
      neighbours: [
        _embedAt(settled + 1),
        _embedAt(settled - 1),
      ].nonNulls.toList(),
      upcoming: [_embedAt(settled + 2)].nonNulls.toList(),
    );
    final last = (settled + 3).clamp(0, _reels.length - 1);
    // Learn video shapes ahead of the swipe so wide videos are already sized.
    for (var i = settled; i <= last; i++) {
      unawaited(ReelShapes.instance.learnReel(_reels[i]));
    }
    for (var i = settled + 1; i <= last; i++) {
      final url = ReelPoster.urlFor(_reels[i]);
      if (url != null) {
        unawaited(precacheImage(CachedNetworkImageProvider(url), context));
      }
    }
  }

  bool _onScrollEnd(ScrollEndNotification notification) {
    // Only the pager's own PageView; product strips inside pages scroll too.
    final pages = _controller.pageController;
    if (notification.depth != 0 || !pages.hasClients) return false;
    final page = pages.page?.round();
    if (page != null && page != _controller._settledIndex) {
      setState(() => _controller._settledIndex = page);
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
    if (_controller._settledIndex >= reels.length) {
      _controller._settledIndex = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEmbeds());
  }

  @override
  Widget build(BuildContext context) {
    final reels = _reels;
    final topInset = MediaQuery.paddingOf(context).top;
    return EmbedPlayerScope(
      pool: _embedPool,
      child: NotificationListener<ScrollEndNotification>(
        onNotification: _onScrollEnd,
        child: Stack(
          children: [
            if (ReelsPager.debugHostEmbedPlayers)
              Positioned.fill(
                child: EmbedPlayerLayer(
                  pool: _embedPool,
                  controller: _controller.pageController,
                  settledIndex: _controller._settledIndex,
                  indexOfKey: (key) => _embedIndex[key],
                  playerRectAt: (index, page) =>
                      reelPlayerRect(reels[index], page, topInset: topInset),
                  layoutChanges: ReelShapes.instance,
                ),
              ),
            PageView.builder(
              controller: _controller.pageController,
              scrollDirection: Axis.vertical,
              // Track the drag from the initial touch-down rather than from
              // where the recognizer eventually "starts" — on Home this
              // vertical PageView is nested inside SwipeableBranchView's
              // horizontal one, and starting from `down` gives the vertical
              // recognizer the full gesture (and its true velocity) instead of
              // only what's left after the two axes finish resolving which one
              // owns the pointer.
              dragStartBehavior: DragStartBehavior.down,
              itemCount: reels.length,
              // Build the adjacent reels offscreen so a native reel's next
              // video has already initialised by the time it's swiped into
              // view. (Inactive reels stay paused; only the active one plays.)
              allowImplicitScrolling: true,
              onPageChanged: (index) {
                if (index != _dwellIndex) {
                  _reportDwell(_dwellIndex, next: index);
                }
                setState(() => _controller._currentIndex = index);
                // Page in more reels before the viewer actually hits the end —
                // otherwise the pager dead-ends and further swipes have
                // nothing new to show.
                if (index >= reels.length - ReelsPager.nearEndPages) {
                  widget.onNearEnd?.call();
                }
              },
              itemBuilder: (_, index) => ReelCard(
                reel: reels[index],
                isActive: index == _controller._currentIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
