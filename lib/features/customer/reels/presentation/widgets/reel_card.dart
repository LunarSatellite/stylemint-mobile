import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_layout_policy.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_scope.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where the player sits on a feed page of size [page]: a YouTube player is
/// sized to a Short at the page's width, so the video shows whole without
/// zooming; other players fill the page. The feed places its shared players
/// with the same rectangle.
Rect reelPlayerRect(Reel reel, Size page) {
  final source = resolveReelPlayback(reel);
  return EmbedLayoutPolicy.playerRect(
    platform: source is EmbedSource ? source.platform : null,
    page: page,
    aspectRatio: EmbedLayoutPolicy.shortsAspectRatio,
  );
}

/// A single full-screen reel: inline video background with a gradient
/// scrim, creator info + caption, right-rail actions and tagged products.
///
/// [isActive] must be true for the reel currently visible in the viewport
/// so that [ReelPlayer] auto-plays it and pauses all others.
class ReelCard extends StatefulWidget {
  const ReelCard({required this.reel, required this.isActive, super.key});

  final Reel reel;
  final bool isActive;

  @override
  State<ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<ReelCard> {
  final _playback = ReelPlaybackController();

  @override
  Widget build(BuildContext context) {
    final source = resolveReelPlayback(widget.reel);
    final embed = source is EmbedSource ? EmbedRequest(source) : null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final player = reelPlayerRect(widget.reel, constraints.biggest);
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fromRect(
              rect: player,
              child: ReelPlayer(
                reel: widget.reel,
                isActive: widget.isActive,
                playbackController: _playback,
              ),
            ),

            // Full-screen tap target for play/pause. Sits above the video but
            // below the interactive controls, so a tap anywhere toggles
            // playback while the buttons below still receive their own taps.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _playback.toggle,
              ),
            ),

            // Bottom scrim so overlaid text stays legible over any video.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
            ),

            if (embed != null)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(DesignTokens.s12),
                    child: _SoundOffButton(embed: embed),
                  ),
                ),
              ),

            // Right-rail actions (like / comment / share / wishlist / cart) —
            // pulled down so the rail sits near the creator/follow row instead
            // of floating high above it.
            Positioned(
              right: DesignTokens.s12,
              bottom: 180,
              child: ReelActions(reel: widget.reel),
            ),

            // Creator info, caption and tagged products pinned to the bottom.
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 72),
                    child: CreatorInfo(reel: widget.reel),
                  ),
                  if (widget.reel.taggedProducts.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s12),
                    TaggedProductsSection(
                      products: widget.reel.taggedProducts,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.s16),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Appears when a platform only allowed the reel to play without sound.
/// A tap turns sound on for the rest of the session.
class _SoundOffButton extends StatelessWidget {
  const _SoundOffButton({required this.embed});

  final EmbedRequest embed;

  @override
  Widget build(BuildContext context) {
    final pool = EmbedPlayerScope.maybeOf(context);
    if (pool == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) {
        if (pool.activeKey != embed.key || !pool.muted) {
          return const SizedBox.shrink();
        }
        return Semantics(
          button: true,
          label: 'Turn sound on',
          child: GestureDetector(
            onTap: () => pool.setMuted(false),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DesignTokens.baseBlack.withValues(alpha: 0.45),
              ),
              child: const Icon(
                Icons.volume_off_rounded,
                size: 20,
                color: DesignTokens.iconWhite,
              ),
            ),
          ),
        );
      },
    );
  }
}
