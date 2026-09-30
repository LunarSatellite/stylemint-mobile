import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A short looping clip for one onboarding slide, with the slide's still image
/// underneath it at every stage.
///
/// ## Why self-hosted clips and not reels
///
/// Reels were the obvious idea and the wrong one. Thirty of this catalogue's
/// thirty-three published reels have no video file at all — they play by
/// booting the platform's own embed player in a WebView, which measures five
/// to fifteen seconds before a first frame and depends on TikTok or Instagram
/// answering at all. Onboarding is the first screen a new user ever sees, so
/// it is the worst possible place to inherit that. These clips ship with the
/// app instead: a bundled asset needs no network, cannot expire, and cannot be
/// rate-limited.
///
/// ## The image is not a placeholder, it is the floor
///
/// [imagePath] is painted first and stays painted until a clip has actually
/// produced frames, and it comes back permanently if the clip fails. So the
/// slide is never empty, never a spinner, and never worse than it was before
/// clips existed — including when a clip file is missing, which is the state
/// this widget ships in until the clips are added.
///
/// ## Muted, looping, no controls
///
/// Onboarding audio is an ambush: the user has not asked for sound and may be
/// anywhere. Volume is zero and looping is on, so a four-second clip reads as
/// a moving illustration rather than a video the user has to manage. There is
/// deliberately no play button — nothing here is worth a tap.
class OnboardingClip extends StatefulWidget {
  const OnboardingClip({
    required this.clipPath,
    required this.imagePath,
    this.size = 240,
    super.key,
  });

  /// Bundled asset path, e.g. `assets/videos/onboarding/discover.mp4`. Null
  /// means this slide has no clip yet and should simply show its image.
  final String? clipPath;

  /// Shown until the clip has frames, and permanently if it never does.
  final String? imagePath;

  final double size;

  @override
  State<OnboardingClip> createState() => _OnboardingClipState();
}

class _OnboardingClipState extends State<OnboardingClip> {
  VideoPlayerController? _controller;

  /// True once the clip has frames worth showing. Until then, and forever
  /// after a failure, the image is what gets painted.
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(OnboardingClip old) {
    super.didUpdateWidget(old);
    // Slides are built by a PageView.builder, which may reuse this element for
    // a different slide. Without this the second slide would keep playing the
    // first one's clip.
    if (old.clipPath != widget.clipPath) {
      _disposeController();
      setState(() => _ready = false);
      _start();
    }
  }

  Future<void> _start() async {
    final path = widget.clipPath;
    if (path == null || path.isEmpty) return;

    final controller = VideoPlayerController.asset(path);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      // A missing or unplayable asset is not an error worth showing anyone:
      // the image is already on screen and stays there. Swallowed on purpose
      // — this is the state the widget ships in before the clips are added.
      await controller.dispose();
      if (_controller == controller) _controller = null;
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    c?.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final image = widget.imagePath;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.asset(
                image,
                fit: BoxFit.contain,
                // The illustration is the floor; if it is also missing there
                // is nothing left to draw, and an empty box beats an error
                // glyph on a first-run screen.
                errorBuilder: (_, _e, _s) => const SizedBox.shrink(),
              ),
            if (_ready && controller != null)
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
