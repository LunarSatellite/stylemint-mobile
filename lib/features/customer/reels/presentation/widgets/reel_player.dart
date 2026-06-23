import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:video_player/video_player.dart';

/// Inline video player for a reel.
///
/// Plays the MP4 pointed to by [Reel.videoUrl] when [isActive] is true,
/// and pauses it when [isActive] is false (reel scrolled off-screen).
///
/// Falls back to a static thumbnail + play-button when [Reel.videoUrl] is null.
class ReelPlayer extends StatefulWidget {
  const ReelPlayer({
    required this.reel,
    required this.isActive,
    super.key,
  });

  final Reel reel;
  final bool isActive;

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  /// User explicitly tapped to pause. Reset whenever this reel scrolls
  /// off-screen so it auto-plays again next time it becomes active.
  bool _manuallyPaused = false;

  /// False while this tab branch is offscreen (go_router wraps inactive
  /// shell branches in `TickerMode(enabled: false)`) — used to pause the
  /// video when the user switches to another bottom tab.
  bool _tabVisible = true;

  /// The video should play only when it's the active reel, its tab is
  /// visible, the app is foregrounded, and the user hasn't paused it.
  bool get _shouldPlay =>
      widget.isActive && _tabVisible && !_manuallyPaused && _appResumed;

  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initVideo());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TickerMode flips to false when this shell branch (bottom tab) is
    // hidden. React to tab switches here.
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

    if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
      _disposeController();
      unawaited(_initVideo());
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      // Scrolling a reel off-screen clears any manual pause so it resumes
      // auto-play when it next becomes the active reel.
      if (!widget.isActive) _manuallyPaused = false;
      _reconcilePlayback();
    }
  }

  Future<void> _initVideo() async {
    final url = widget.reel.videoUrl;
    if (url == null || url.isEmpty) return;

    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = controller;

      await controller.initialize();
      if (!mounted) return;

      await controller.setLooping(true);
      if (!mounted) return;

      setState(() => _initialized = true);

      // Reconcile against whatever state the parent/app/tab has settled
      // into by the time init finished.
      _reconcilePlayback();
    } on Exception catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  /// Single source of truth: drive the controller to match [_shouldPlay].
  void _reconcilePlayback() {
    final c = _controller;
    if (c == null || !_initialized) return;
    if (_shouldPlay) {
      if (!c.value.isPlaying) unawaited(c.play());
    } else {
      if (c.value.isPlaying) unawaited(c.pause());
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    _initialized = false;
    _hasError = false;
    unawaited(c?.dispose() ?? Future<void>.value());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  void _onTap() {
    if (_controller == null || !_initialized) return;
    setState(() => _manuallyPaused = !_manuallyPaused);
    _reconcilePlayback();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = widget.reel.videoUrl != null;

    return GestureDetector(
      onTap: hasVideo && !_hasError ? _onTap : null,
      child: ColoredBox(
        color: DesignTokens.baseBlack,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video layer
            if (_initialized && _controller != null)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            else if (widget.reel.thumbnailUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.reel.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder:
                    (_, _) =>
                        const ColoredBox(color: DesignTokens.bgAppBodyLight),
                errorWidget:
                    (_, _, _) => const ColoredBox(
                      color: DesignTokens.bgAppBodyLight,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: DesignTokens.iconLight,
                      ),
                    ),
              ),

            // Loading spinner while the controller initialises
            if (hasVideo && !_initialized && !_hasError)
              const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                  strokeWidth: 2,
                ),
              ),

            // Manual-pause overlay — a play affordance that stays until the
            // user taps anywhere to resume.
            if (_manuallyPaused && _initialized)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.baseBlack.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: DesignTokens.iconLarge,
                    color: DesignTokens.iconWhite,
                  ),
                ),
              ),

            // Static play-button for thumbnail-only or error fallback
            if (!hasVideo || _hasError)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.baseBlack.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: DesignTokens.iconLarge,
                    color: DesignTokens.iconWhite,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
