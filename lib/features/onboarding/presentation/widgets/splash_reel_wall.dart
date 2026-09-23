import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Slow-drifting columns of reel-shaped cards behind the splash logo.
///
/// The splash used to be a logo on a flat background for its whole hold, which
/// said nothing about what the app is. This hints at the reels wall the user
/// is about to land on while the session bootstraps.
///
/// Deliberately built from assets already in the bundle — these are decorative
/// stand-ins, not real reels. Nothing is fetched: the splash runs before the
/// session resolves, so there is no feed to read and no time to wait for one.
/// Swap [_tiles] for real poster URLs only if the splash ever gains something
/// to read them from.
///
/// Purely decorative: it ignores pointers and is hidden from screen readers,
/// and it renders nothing at all when the platform asks for reduced motion.
class SplashReelWall extends StatelessWidget {
  const SplashReelWall({required this.drift, required this.fade, super.key});

  /// Repeating 0→1; drives the vertical scroll.
  final Animation<double> drift;

  /// The wall's opacity, so it can come up with the rest of the screen.
  final Animation<double> fade;

  /// Bundled images used as stand-in reel posters.
  static const List<String> _tiles = [
    'assets/images/product_nike_air_max.png',
    'assets/images/onboarding/ecommerce_campaign.png',
    'assets/images/sample_shoe2.png',
    'assets/images/mission-concierge-editorial.png',
    'assets/images/sample_shoe3.png',
    'assets/images/onboarding/group-discussion.png',
  ];

  static const double _cardHeight = 190;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    // A moving backdrop is exactly what "reduce motion" is asking us not to
    // draw, and a still one behind a logo is just clutter.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: ExcludeSemantics(
        child: FadeTransition(
          opacity: fade,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Three columns across whatever width there is, so the wall fills
              // a phone and a tablet alike without a breakpoint.
              const columns = 3;
              final width =
                  (constraints.maxWidth - _gap * (columns + 1)) / columns;
              return ClipRect(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < columns; i++)
                      SizedBox(
                        width: width,
                        height: constraints.maxHeight,
                        child: _Column(
                          drift: drift,
                          width: width,
                          // Alternate direction, and start each column at a
                          // different point so they never line up in a grid.
                          up: i.isEven,
                          phase: i / columns,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({
    required this.drift,
    required this.width,
    required this.up,
    required this.phase,
  });

  final Animation<double> drift;
  final double width;
  final bool up;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final tiles = SplashReelWall._tiles;
    const cardHeight = SplashReelWall._cardHeight;
    const gap = SplashReelWall._gap;

    // One full pass is the height of a single run of tiles. Two runs are laid
    // out and the offset wraps within one, so the seam never comes on screen.
    final run = (cardHeight + gap) * tiles.length;

    return AnimatedBuilder(
      animation: drift,
      builder: (context, child) {
        final t = (drift.value + phase) % 1.0;
        final offset = up ? -t * run : t * run - run;
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            maxHeight: double.infinity,
            child: Transform.translate(
              offset: Offset(0, offset),
              child: child,
            ),
          ),
        );
      },
      // The cards themselves never change, so they are built once and reused
      // across every frame of the drift rather than rebuilt 60 times a second.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < tiles.length * 2; i++) ...[
            _Card(asset: tiles[i % tiles.length], width: width),
            const SizedBox(height: gap),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.asset, required this.width});

  final String asset;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      child: SizedBox(
        width: width,
        height: SplashReelWall._cardHeight,
        child: ColoredBox(
          color: DesignTokens.bgAppBody,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            // A missing or undecodable asset must never take the splash down
            // with it — the card just stays the flat card colour.
            errorBuilder: (_, _e, _s) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
