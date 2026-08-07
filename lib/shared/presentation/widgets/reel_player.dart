import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Lets an ancestor (e.g. a full-screen tap layer) toggle the player's
/// play/pause state without owning the underlying controller.
class ReelPlaybackController {
  VoidCallback? _onToggle;

  /// Toggle play/pause on the attached [ReelPlayer]; no-op if none attached.
  void toggle() => _onToggle?.call();
}

/// Inline video player for a reel. Shared across features (customer feed,
/// creator reel details). Renders the right player for the source platform:
///
/// - **Instagram** → [video_player] using the resolved mp4 URL
///   (refreshed by the BE's `ReelVideoUrlRefreshJob`).
/// - **YouTube** → [youtube_player_flutter] using the platform video ID
///   parsed from the permalink. No API key needed for playback (only for
///   quota-protected metadata).
/// - **TikTok / Facebook** → static thumbnail + a "Watch on {Platform}"]
///   button that opens the reel in the platform's native app via
///   [url_launcher]. The TikTok/Facebook embed surface is too inconsistent
///   across iOS / Android to warrant an in-app WebView.
///
/// Plays when [isActive] is true; pauses when it's false (e.g. a reel
/// scrolled off-screen in the customer feed).
class ReelPlayer extends StatefulWidget {
  const ReelPlayer({
    required this.reel,
    required this.isActive,
    this.playbackController,
    super.key,
  });

  /// Media meta extracted from the reel entity. See [ReelMedia].
  final ReelMedia reel;

  /// Whether the reel is currently the visible one in the viewport. Only the
  /// active reel auto-plays; the rest stay paused.
  final bool isActive;

  /// Optional handle so an ancestor can toggle play/pause on tap.
  final ReelPlaybackController? playbackController;

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer>
    with WidgetsBindingObserver {
  // Direct .mp4 playback (Instagram).
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;

  // YouTube playback.
  YoutubePlayerController? _ytController;

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
    _initForPlatform();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

    if (oldWidget.reel.permalink != widget.reel.permalink ||
        oldWidget.reel.videoUrl != widget.reel.videoUrl ||
        oldWidget.reel.platform != widget.reel.platform) {
      _disposeAll();
      _initForPlatform();
      return;
    }

    if (oldWidget.isActive != widget.isActive) {
      if (!widget.isActive) _manuallyPaused = false;
      _reconcilePlayback();
    }
  }

  void _initForPlatform() {
    final platform = widget.reel.platform ?? SocialPlatform.instagram;
    switch (platform) {
      case SocialPlatform.instagram:
        _initInstagramVideo();
      case SocialPlatform.youtube:
        _initYouTube();
      case SocialPlatform.tiktok:
      case SocialPlatform.facebook:
        // No in-app player; thumbnail + open-in-app button.
        break;
    }
  }

  Future<void> _initInstagramVideo() async {
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

      _reconcilePlayback();
    } on Exception catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _initYouTube() {
    final videoId = widget.reel.platformVideoId;
    if (videoId == null || videoId.isEmpty) return;

    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        loop: true,
        disableDragSeek: false,
        enableCaption: false,
      ),
    );
  }

  void _reconcilePlayback() {
    if (!_shouldPlay) {
      if (_controller != null && _initialized && _controller!.value.isPlaying) {
        unawaited(_controller!.pause());
      }
      if (_ytController != null && _ytController!.value.isPlaying) {
        _ytController!.pause();
      }
      return;
    }

    if (_controller != null && _initialized && !_controller!.value.isPlaying) {
      unawaited(_controller!.play());
    }
    if (_ytController != null && !_ytController!.value.isPlaying) {
      _ytController!.play();
    }
  }

  void _disposeAll() {
    final c = _controller;
    _controller = null;
    _initialized = false;
    _hasError = false;
    unawaited(c?.dispose() ?? Future<void>.value());

    final yt = _ytController;
    _ytController = null;
    yt?.dispose();
  }

  @override
  void dispose() {
    if (widget.playbackController?._onToggle == _togglePlayPause) {
      widget.playbackController?._onToggle = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _disposeAll();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() => _manuallyPaused = !_manuallyPaused);
    _reconcilePlayback();
  }

  Future<void> _openExternally() async {
    final url = Uri.tryParse(widget.reel.permalink);
    if (url == null) return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final platform = widget.reel.platform ?? SocialPlatform.instagram;

    switch (platform) {
      case SocialPlatform.instagram:
        return _buildInstagramLayer();
      case SocialPlatform.youtube:
        return _buildYouTubeLayer();
      case SocialPlatform.tiktok:
      case SocialPlatform.facebook:
        return _buildExternalLayer(platform);
    }
  }

  Widget _buildInstagramLayer() {
    final hasVideo = (widget.reel.videoUrl ?? '').isNotEmpty;

    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_initialized && _controller != null)
            FittedBox(
              fit: _controller!.value.aspectRatio < 1
                  ? BoxFit.cover
                  : BoxFit.contain,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            )
          else if ((widget.reel.thumbnailUrl ?? '').isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.reel.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: DesignTokens.bgAppBodyLight),
              errorWidget: (_, _, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),

          if (hasVideo && !_initialized && !_hasError)
            const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
                strokeWidth: 2,
              ),
            ),

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
    );
  }

  Widget _buildYouTubeLayer() {
    final controller = _ytController;
    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            YoutubePlayer(
              controller: controller,
              showVideoProgressIndicator: true,
              progressIndicatorColor: DesignTokens.primaryGreen,
              progressColors: ProgressBarColors(
                playedColor: DesignTokens.primaryGreen,
                handleColor: DesignTokens.primaryGreen,
              ),
            )
          else if ((widget.reel.thumbnailUrl ?? '').isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.reel.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: DesignTokens.bgAppBodyLight),
              errorWidget: (_, _, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExternalLayer(SocialPlatform platform) {
    return ColoredBox(
      color: DesignTokens.baseBlack,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((widget.reel.thumbnailUrl ?? '').isNotEmpty)
            CachedNetworkImage(
              imageUrl: widget.reel.thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  const ColoredBox(color: DesignTokens.bgAppBodyLight),
              errorWidget: (_, _, _) => const ColoredBox(
                color: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
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
                const SizedBox(height: DesignTokens.s12),
                TextButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: DesignTokens.iconWhite,
                  ),
                  label: Text(
                    'Watch on ${platform.displayName}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      color: DesignTokens.iconWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
