import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The ring on a story bubble: brand gradient for something new to watch, a
/// thin grey line once it has all been seen.
enum StoryRing { unwatched, watched, none }

/// Brand mint running into the warm accents — the "new story" ring.
const LinearGradient storyRingGradient = LinearGradient(
  begin: Alignment.bottomLeft,
  end: Alignment.topRight,
  colors: [
    DesignTokens.primaryGreen,
    DesignTokens.secondaryYellow,
    DesignTokens.colorError,
  ],
);

/// A round avatar inside a story ring.
///
/// The avatar keeps the same size whatever the ring, so bubbles line up in a
/// row where some are new and some are seen. The gap between ring and avatar
/// is left unpainted, which keeps it right over a playing reel as well as on
/// an app surface.
class StoryRingAvatar extends StatelessWidget {
  const StoryRingAvatar({
    required this.avatarUrl,
    required this.diameter,
    this.name = '',
    this.ring = StoryRing.unwatched,
    this.watchedRingColor = DesignTokens.sectionOnBase,
    super.key,
  });

  final String avatarUrl;

  /// Outer size, ring included.
  final double diameter;

  /// Used for the initial when there is no avatar.
  final String name;
  final StoryRing ring;
  final Color watchedRingColor;

  static const double _unwatchedStroke = 2.6;
  static const double _watchedStroke = 1.2;
  static const double _gap = 2.6;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: diameter,
      child: CustomPaint(
        painter: _StoryRingPainter(ring: ring, watchedColor: watchedRingColor),
        child: Padding(
          padding: const EdgeInsets.all(_unwatchedStroke + _gap),
          child: ClipOval(child: _avatar()),
        ),
      ),
    );
  }

  Widget _avatar() {
    final fallback = _InitialAvatar(name: name);
    if (avatarUrl.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: avatarUrl,
      fit: BoxFit.cover,
      fadeInDuration: DesignTokens.motionFast,
      placeholder: (_, _) => const ColoredBox(color: DesignTokens.bgAppBodyLight),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty
        ? null
        : name.trim().characters.first.toUpperCase();
    return ColoredBox(
      color: DesignTokens.bgAppBodyLight,
      child: Center(
        child: initial == null
            ? const Icon(Icons.person, color: DesignTokens.iconLight)
            : Text(
                initial,
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
      ),
    );
  }
}

class _StoryRingPainter extends CustomPainter {
  const _StoryRingPainter({required this.ring, required this.watchedColor});

  final StoryRing ring;
  final Color watchedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (ring == StoryRing.none) return;
    final unwatched = ring == StoryRing.unwatched;
    final stroke = unwatched
        ? StoryRingAvatar._unwatchedStroke
        : StoryRingAvatar._watchedStroke;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..isAntiAlias = true;
    if (unwatched) {
      paint.shader = storyRingGradient.createShader(rect);
    } else {
      paint.color = watchedColor;
    }
    // The watched line sits on the outer edge, where the gradient ring would.
    canvas.drawCircle(rect.center, size.shortestSide / 2 - stroke / 2, paint);
  }

  @override
  bool shouldRepaint(_StoryRingPainter oldDelegate) =>
      oldDelegate.ring != ring || oldDelegate.watchedColor != watchedColor;
}
