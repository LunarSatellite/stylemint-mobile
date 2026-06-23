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

class _ReelPlayerState extends State<ReelPlayer> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _showPauseIcon = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initVideo());
  }

  @override
  void didUpdateWidget(ReelPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.reel.videoUrl != widget.reel.videoUrl) {
      _disposeController();
      unawaited(_initVideo());
      return;
    }

    if (oldWidget.isActive != widget.isActive && _initialized) {
      // Only act when the controller is ready. If _initVideo is still
      // running it reads widget.isActive at the end and calls play/pause
      // itself — so we must not race it here.
      if (widget.isActive) {
        unawaited(_controller?.play() ?? Future<void>.value());
        setState(() => _showPauseIcon = false);
      } else {
        unawaited(_controller?.pause() ?? Future<void>.value());
        setState(() => _showPauseIcon = false);
      }
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

      // widget.isActive is read here — after all the awaits — so it reflects
      // whatever state the parent has settled into by the time init finishes.
      if (widget.isActive) {
        await controller.play();
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _hasError = true);
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
    _disposeController();
    super.dispose();
  }

  void _onTap() {
    final c = _controller;
    if (c == null || !_initialized) return;
    if (c.value.isPlaying) {
      unawaited(c.pause());
      setState(() => _showPauseIcon = true);
    } else {
      unawaited(c.play());
      setState(() => _showPauseIcon = false);
    }
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

            // Pause icon — stays until user taps to resume
            if (_showPauseIcon)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.baseBlack.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  child: const Icon(
                    Icons.pause_rounded,
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
