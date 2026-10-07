import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:video_player/video_player.dart';

/// "0:42" / "1:00" — a clip length the way Instagram labels it.
String formatClipDuration(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

/// A post video, filling its box (cover). Nothing loads until it is tapped:
/// a feed of videos must not start a download per card. Tap plays (looping),
/// tap again pauses; the speaker button mutes.
///
/// There is no server-side poster frame yet, so until it plays it shows a
/// dark tile with a play button, a video badge and, when known, the length.
class PostVideoView extends StatefulWidget {
  const PostVideoView.network(String this.url, {this.duration, super.key})
    : filePath = null;

  const PostVideoView.file(String this.filePath, {this.duration, super.key})
    : url = null;

  final String? url;
  final String? filePath;

  /// Length to show before the clip is loaded (e.g. from the picker).
  final Duration? duration;

  @override
  State<PostVideoView> createState() => _PostVideoViewState();
}

class _PostVideoViewState extends State<PostVideoView> {
  VideoPlayerController? _controller;
  bool _loading = false;
  bool _failed = false;
  bool _muted = false;

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    final controller = _controller;
    if (_loading) return;
    if (controller == null || _failed) return _start();
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> _start() async {
    unawaited(_controller?.dispose());
    final url = widget.url;
    final controller = url != null
        ? VideoPlayerController.networkUrl(Uri.parse(url))
        : VideoPlayerController.file(File(widget.filePath!));
    setState(() {
      _controller = controller;
      _loading = true;
      _failed = false;
    });
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(_muted ? 0 : 1);
      await controller.play();
    } on Object {
      _failed = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleMute() async {
    setState(() => _muted = !_muted);
    await _controller?.setVolume(_muted ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(_toggle()),
      child: ColoredBox(
        color: DesignTokens.baseBlack,
        child: controller == null
            ? _overlay(playing: false, length: widget.duration)
            : ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final ready = value.isInitialized && !_failed;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      if (ready)
                        FittedBox(
                          fit: BoxFit.cover,
                          clipBehavior: Clip.hardEdge,
                          child: SizedBox(
                            width: value.size.width,
                            height: value.size.height,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      _overlay(
                        playing: value.isPlaying,
                        length: ready ? value.duration : widget.duration,
                        showMute: ready,
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _overlay({
    required bool playing,
    Duration? length,
    bool showMute = false,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
          )
        else if (_failed)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: DesignTokens.iconLight,
                  size: DesignTokens.iconMedium,
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  "Couldn't play this video. Tap to try again.",
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
            ),
          )
        else if (!playing)
          Center(
            child: Container(
              key: const Key('post-video-play'),
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.baseBlack.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        Positioned(
          top: DesignTokens.s12,
          left: DesignTokens.s12,
          child: _Badge(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.videocam_rounded,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.textWhite,
                ),
                if (length != null && length > Duration.zero) ...[
                  const SizedBox(width: DesignTokens.s4),
                  Text(
                    formatClipDuration(length),
                    key: const Key('post-video-duration'),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showMute)
          Positioned(
            right: DesignTokens.s8,
            bottom: DesignTokens.s8,
            child: IconButton(
              key: const Key('post-video-mute'),
              tooltip: _muted ? 'Unmute' : 'Mute',
              onPressed: () => unawaited(_toggleMute()),
              icon: _Badge(
                child: Icon(
                  _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.baseBlack.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: child,
    );
  }
}
