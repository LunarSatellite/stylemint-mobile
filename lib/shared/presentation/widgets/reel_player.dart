import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/data/reel_video_cache.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_pool.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_scope.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_reel_surface.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_play_indicator.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_sound_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:video_player/video_player.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

/// Lets an ancestor (e.g. a full-screen tap layer) toggle the player's
/// play/pause state without owning the underlying controller.
class ReelPlaybackController {
  VoidCallback? _onToggle;

  /// Toggle play/pause on the attached [ReelPlayer]; no-op if none attached.
  void toggle() => _onToggle?.call();
}

/// Inline player for a reel, shared by the customer feed, the creator's reel
/// details and the import preview. [resolveReelPlayback] decides how a reel
/// plays:
///
/// - **Native** (Instagram with an official media URL): [VideoPlayer], with
///   neighbouring reels pre-downloaded into [ReelVideoCache].
/// - **Embed** (YouTube, TikTok, Facebook): the platform's official embedded
///   player. Inside an [EmbedPlayerScope] (the feed) the player lives in the
///   scope's pool beneath the page, and this widget draws the poster until
///   the player has frames. Elsewhere it owns a single player.
/// - **External only**: the poster with a short "can't play here" note.
///
/// A reel that cannot play (external only, a refused media URL, or an embed
/// that gave up) never opens its platform's app or site: nothing on a reel
/// surface leaves StyleMint (owner decision, 2026-09-14).
///
/// Plays while [isActive] is true, its tab is visible and the app is in the
/// foreground. A tap through [playbackController] pauses and resumes it.
class ReelPlayer extends StatefulWidget {
  const ReelPlayer({
    required this.reel,
    required this.isActive,
    this.playbackController,
    this.showSoundControl = true,
    super.key,
  });

  /// Shown over the poster when the reel cannot play in StyleMint.
  static const unavailableMessage = "This reel can't play here right now";

  /// Media meta extracted from the reel entity. See [ReelMedia].
  final ReelMedia reel;

  /// Whether the reel is currently the visible one in the viewport. Only the
  /// active reel plays; the rest stay paused.
  final bool isActive;

  /// Optional handle so an ancestor can toggle play/pause on tap.
  final ReelPlaybackController? playbackController;

  /// Draws the sound toggle over the video.
  ///
  /// Set false only where the surface lays its own tap target over this
  /// player — the customer feed does, and a control drawn here would sit
  /// underneath it and never receive a tap. That surface draws its own.
  final bool showSoundControl;

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> with WidgetsBindingObserver {
  late ReelPlaybackSource _source = resolveReelPlayback(widget.reel);

  // Native playback.
  VideoPlayerController? _controller;
  bool _initialized = false;

  /// An already-`initialize()`d (paused, muted) controller built ahead of
  /// time while this reel was still a neighbour — see
  /// [_prefetchInstagramVideo]. Adopted by [_initInstagramVideo] when the
  /// reel becomes active instead of building fresh.
  VideoPlayerController? _preloadController;

  /// Resolves when [_preloadController]'s `initialize()` completes — may
  /// already be a swipe ahead of the preload finishing, so
  /// [_initInstagramVideo] awaits this rather than assuming the controller
  /// is ready the instant it exists.
  Future<void>? _preloadInitFuture;

  /// True when [_controller] was built from a cached file rather than the
  /// network, so a decode failure can be treated as a bad cache entry.
  bool _playingFromCache = false;
  bool _hasError = false;

  /// Sound state for the native path. Embeds keep theirs in the pool, which
  /// already shares one setting across every reel in the session.
  bool _nativeMuted = false;

  // Embedded playback: the feed's pool when inside one, otherwise a
  // single-slot pool owned by this player.
  EmbedPlayerPool? _scopePool;
  EmbedPlayerPool? _ownPool;

  /// User explicitly tapped to pause. Reset whenever this reel scrolls
  /// off-screen so it auto-plays again next time it becomes active.
  bool _manuallyPaused = false;

  /// False while this tab branch is offscreen (go_router wraps inactive
  /// shell branches in `TickerMode(enabled: false)`).
  bool _tabVisible = true;
  bool _appResumed = true;

  bool get _shouldPlay =>
      widget.isActive && _tabVisible && !_manuallyPaused && _appResumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.playbackController?._onToggle = _togglePlayPause;
    _initNative();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scopePool = EmbedPlayerScope.maybeOf(context);
    _syncOwnPool();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible != _tabVisible) {
      _tabVisible = visible;
      _reconcilePlayback();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed != _appResumed) {
      _appResumed = resumed;
      _reconcilePlayback();
    }
  }

  @override
  void didUpdateWidget(ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.playbackController != widget.playbackController) {
      if (oldWidget.playbackController?._onToggle == _togglePlayPause) {
        oldWidget.playbackController?._onToggle = null;
      }
      widget.playbackController?._onToggle = _togglePlayPause;
    }

    final source = resolveReelPlayback(widget.reel);
    if (!_sameSource(source, _source)) {
      _disposeNative();
      _source = source;
      _manuallyPaused = false;
      _initNative();
      _syncOwnPool();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) _manuallyPaused = false;

      // A reel that was only prefetching as a neighbour has no controller
      // yet; build one now that it is the reel on screen. By this point the
      // prefetch has usually landed, so this is a cache hit and starts
      // without touching the network.
      if (widget.isActive &&
          _source is NativeVideoSource &&
          _controller == null &&
          !_hasError) {
        unawaited(_initInstagramVideo());
      }
      _reconcilePlayback();
    }
  }

  static bool _sameSource(ReelPlaybackSource a, ReelPlaybackSource b) =>
      switch ((a, b)) {
        (
          NativeVideoSource(url: final urlA, cacheKey: final keyA),
          NativeVideoSource(url: final urlB, cacheKey: final keyB),
        ) =>
          urlA == urlB && keyA == keyB,
        (
          EmbedSource(
            platform: final platformA,
            externalId: final idA,
            permalink: final linkA,
          ),
          EmbedSource(
            platform: final platformB,
            externalId: final idB,
            permalink: final linkB,
          ),
        ) =>
          platformA == platformB && idA == idB && linkA == linkB,
        (
          ExternalOnlySource(permalink: final linkA),
          ExternalOnlySource(permalink: final linkB),
        ) =>
          linkA == linkB,
        _ => false,
      };

  void _initNative() {
    if (_source is! NativeVideoSource) return;
    // Only the reel actually on screen gets an ExoPlayer. The PageView
    // keeps both neighbours alive (allowImplicitScrolling), and three
    // simultaneous initialise() calls split the connection three ways —
    // starving the one the user is looking at. Neighbours warm the disk
    // cache instead, which is both cheaper and what makes the next swipe
    // start instantly.
    if (widget.isActive) {
      unawaited(_initInstagramVideo());
    } else {
      unawaited(_prefetchInstagramVideo());
    }
  }

  /// Outside a feed, an embedded reel gets a player of its own.
  void _syncOwnPool() {
    final source = _source;
    if (source is! EmbedSource || _scopePool != null) {
      final stale = _ownPool;
      _ownPool = null;
      // Disposed after this frame, once the surface using it has let go.
      if (stale != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => stale.dispose());
      }
      return;
    }
    final pool = _ownPool ??= EmbedPlayerPool(slotCount: 1);
    pool
      ..setWindow(active: EmbedRequest(source))
      ..setHostActive(_shouldPlay);
  }

  /// Downloads the neighbour's video bytes, then — the part that actually
  /// removes the swipe-to-play delay — builds and `initialize()`s a real
  /// (paused, muted) controller from the now-local file. `initialize()`
  /// (codec/decoder setup + first-frame decode) is usually slower than the
  /// download itself, so doing it only when the reel becomes active meant
  /// every swipe still showed a spinner even on a full cache hit.
  ///
  /// This does NOT reintroduce the network-contention problem the
  /// single-active-controller design exists to avoid: by the time
  /// `initialize()` runs here the bytes are already on disk
  /// (`VideoPlayerController.file`), so it costs CPU/decoder time, not a
  /// second connection racing the active reel's stream.
  bool _shouldStartPreloadInit(NativeVideoSource source) =>
      mounted &&
      identical(_source, source) &&
      !widget.isActive &&
      _controller == null &&
      _preloadController == null;

  Future<void> _prefetchInstagramVideo() async {
    final source = _source;
    if (source is! NativeVideoSource) return;
    await ReelVideoCache.instance.prefetch(
      cacheKey: source.cacheKey,
      url: source.url,
    );
    if (!_shouldStartPreloadInit(source)) return;

    final cached = await ReelVideoCache.instance.peek(source.cacheKey);
    if (cached == null) return;
    if (!_shouldStartPreloadInit(source)) return;

    try {
      final controller = VideoPlayerController.file(cached);
      _preloadController = controller;
      final initFuture = controller.initialize();
      _preloadInitFuture = initFuture;
      await initFuture;
      if (_preloadController != controller) {
        // Superseded (reel changed, or already adopted while we were
        // awaiting) — dispose the orphan rather than leaking a decoder.
        unawaited(controller.dispose());
        return;
      }
      if (!mounted) return;
      await controller.setLooping(true);
      await controller.setVolume(0);
    } on Exception {
      // A preload failure just means this neighbour falls back to the
      // normal on-activate path — never worth surfacing.
      if (_preloadController != null) {
        final stale = _preloadController;
        _preloadController = null;
        _preloadInitFuture = null;
        unawaited(stale?.dispose() ?? Future<void>.value());
      }
    }
  }

  Future<void> _initInstagramVideo() async {
    final source = _source;
    if (source is! NativeVideoSource) return;

    // Adopt an already-initialised (or still-initialising) preload instead
    // of building fresh — this is the swipe-feels-instant path. If the
    // preload hasn't finished yet (user swiped faster than it could
    // complete), await the same in-flight initialize() rather than
    // starting a second, redundant one.
    final preloaded = _preloadController;
    if (preloaded != null) {
      try {
        await (_preloadInitFuture ?? Future<void>.value());
      } on Exception {
        // Preload failed — fall through to the normal path below.
      }
      if (mounted &&
          _preloadController == preloaded &&
          preloaded.value.isInitialized) {
        _preloadController = null;
        _preloadInitFuture = null;
        _controller = preloaded;
        _playingFromCache = true;
        // The preload was built silent; hand it whatever the viewer chose.
        await _applyNativeVolume();
        setState(() => _initialized = true);
        _reconcilePlayback();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reconcilePlayback();
        });
        return;
      }
      // Preload didn't pan out (failed / disposed) — clear it and fall
      // through to build a fresh controller below.
      if (_preloadController == preloaded) {
        _preloadController = null;
        _preloadInitFuture = null;
      }
    }

    // Cache hit plays from disk: no network, no rebuffering, and it works
    // offline. A miss streams straight from the network rather than waiting
    // for a full download, so first view is never slower than before.
    final cached = await ReelVideoCache.instance.peek(source.cacheKey);
    if (!mounted || !identical(_source, source)) return;
    // The user may have already swiped past this reel while the cache
    // lookup was in flight (common on a fast rapid-swipe burst) — starting
    // a full decoder initialise() for a reel that's no longer active just
    // burns CPU/network that the reel actually on screen needs, which is
    // exactly what makes a rapid-swipe burst feel sluggish afterwards.
    if (!widget.isActive) return;

    try {
      final controller = cached != null
          ? VideoPlayerController.file(cached)
          : VideoPlayerController.networkUrl(Uri.parse(source.url));
      _controller = controller;
      _playingFromCache = cached != null;

      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      if (!mounted) return;
      await _applyNativeVolume();
      if (!mounted) return;

      setState(() => _initialized = true);

      // Reconcile now (controller ready) and again on the next frame so
      // _tabVisible / _appResumed have settled before we decide to play.
      _reconcilePlayback();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reconcilePlayback();
      });
    } on Exception catch (_) {
      // A cached file that will not open is a truncated or corrupt download.
      // Drop it and retry once over the network so one bad entry cannot
      // wedge the reel permanently.
      if (_playingFromCache) {
        await ReelVideoCache.instance.evict(source.cacheKey);
        if (!mounted) return;
        _playingFromCache = false;
        unawaited(_controller?.dispose() ?? Future<void>.value());
        _controller = null;
        await _initInstagramVideoFromNetwork(source.url);
        return;
      }
      // An expired or refused media URL: show the poster and the
      // can't-play note.
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _initInstagramVideoFromNetwork(String url) async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      await controller.setLooping(true);
      if (!mounted) return;
      await _applyNativeVolume();
      if (!mounted) return;
      setState(() => _initialized = true);
      _reconcilePlayback();
    } on Exception catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _reconcilePlayback() {
    _ownPool?.setHostActive(_shouldPlay);
    final controller = _controller;
    if (controller == null || !_initialized) return;
    if (_shouldPlay && !controller.value.isPlaying) {
      unawaited(controller.play());
    } else if (!_shouldPlay && controller.value.isPlaying) {
      unawaited(controller.pause());
    }
  }

  void _disposeNative() {
    final controller = _controller;
    _controller = null;
    _initialized = false;
    _playingFromCache = false;
    _hasError = false;
    unawaited(controller?.dispose() ?? Future<void>.value());

    final preload = _preloadController;
    _preloadController = null;
    _preloadInitFuture = null;
    unawaited(preload?.dispose() ?? Future<void>.value());
  }

  @override
  void dispose() {
    if (widget.playbackController?._onToggle == _togglePlayPause) {
      widget.playbackController?._onToggle = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _disposeNative();
    _ownPool?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    final source = _source;
    // A reel that cannot play here has nothing to pause, and nothing to open.
    if (source is ExternalOnlySource ||
        (source is NativeVideoSource && _hasError)) {
      return;
    }
    if (source is EmbedSource) {
      final key = EmbedRequest(source).key;
      final scope = _scopePool;
      if (scope != null) {
        if (!scope.hasGivenUp(key) && scope.activeKey == key) {
          scope.togglePause();
        }
        return;
      }
      if (_ownPool?.hasGivenUp(key) ?? false) return;
    }
    setState(() => _manuallyPaused = !_manuallyPaused);
    _reconcilePlayback();
  }

  /// The pool this player's sound setting lives in, or null on the native
  /// path. Its own pool when it has one, otherwise the feed's.
  EmbedPlayerPool? get _soundPool => _ownPool ?? _scopePool;

  /// Applies [_nativeMuted] to the live controller. Called after every
  /// controller is built, because a fresh [VideoPlayerController] starts at
  /// full volume regardless of what the viewer last chose.
  Future<void> _applyNativeVolume() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.setVolume(_nativeMuted ? 0 : 1);
    } on Exception {
      // A disposed or not-yet-ready controller; the next init applies it.
    }
  }

  void _toggleMuted() {
    final pool = _source is EmbedSource ? _soundPool : null;
    if (pool != null) {
      pool.setMuted(!pool.muted);
      return;
    }
    setState(() => _nativeMuted = !_nativeMuted);
    unawaited(_applyNativeVolume());
  }

  /// Whether there is any sound to control yet. Hidden over a poster, a
  /// loader or a reel that cannot play at all, where the control would do
  /// nothing.
  bool get _soundControlVisible {
    if (!widget.showSoundControl) return false;
    final source = _source;
    switch (source) {
      case NativeVideoSource():
        return _initialized && !_hasError;
      case EmbedSource():
        final pool = _soundPool;
        // A reel that gave up shows the "can't play here" poster; offering
        // to turn its sound on would be offering nothing.
        return pool != null && !pool.hasGivenUp(EmbedRequest(source).key);
      case ExternalOnlySource():
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    final layer = switch (source) {
      NativeVideoSource() =>
        _hasError ? _buildUnavailableLayer() : _buildNativeLayer(),
      EmbedSource() => _buildEmbedLayer(source),
      ExternalOnlySource() => _buildUnavailableLayer(),
    };
    if (!_soundControlVisible) return layer;

    final pool = source is EmbedSource ? _soundPool : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        layer,
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: pool == null
                ? ReelSoundButton(muted: _nativeMuted, onTap: _toggleMuted)
                : ListenableBuilder(
                    listenable: pool,
                    builder: (context, _) => ReelSoundButton(
                      muted: pool.muted,
                      onTap: _toggleMuted,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNativeLayer() {
    final controller = _controller;
    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized && controller != null)
            // A vertical reel (up to 3:4) fills the whole page with no bars;
            // a square or landscape video shows whole, the way it was made
            // (owner decision, 2026-09-13; same rule as
            // EmbedLayoutPolicy.fillsScreen).
            FittedBox(
              fit: controller.value.aspectRatio <= 3 / 4
                  ? BoxFit.cover
                  : BoxFit.contain,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            ReelPoster(reel: widget.reel),
          if (!_initialized) const SmPageLoader(),
          if (_manuallyPaused && _initialized)
            const Center(child: ReelPlayIndicator()),
        ],
      ),
    );
  }

  Widget _buildEmbedLayer(EmbedSource source) {
    final pool = _scopePool ?? _ownPool;
    if (pool == null) return ReelPoster(reel: widget.reel);
    return EmbedReelSurface(
      pool: pool,
      request: EmbedRequest(source),
      ownsPlayer: _scopePool == null,
      poster: ReelPoster(reel: widget.reel),
      fallback: _buildUnavailableLayer(),
    );
  }

  /// The poster with a short note. Deliberately not interactive: a reel that
  /// cannot play here is never handed off to its platform.
  Widget _buildUnavailableLayer() {
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelPoster(reel: widget.reel),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: DesignTokens.baseBlack.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s8,
                ),
                child: Text(
                  ReelPlayer.unavailableMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.iconWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
