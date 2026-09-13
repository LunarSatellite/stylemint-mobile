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
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_play_indicator.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where the player sits on a feed page of size [page]: a rectangle of its
/// own for a YouTube reel (see [EmbedLayoutPolicy]), otherwise the whole
/// page. The feed places its shared players with the same rectangle.
Rect reelPlayerRect(Reel reel, Size page, EdgeInsets padding) {
  final source = resolveReelPlayback(reel);
  return EmbedLayoutPolicy.playerRect(
    platform: source is EmbedSource ? source.platform : null,
    page: page,
    topInset: padding.top,
    panelHeight: EmbedLayoutPolicy.panelHeight(
      hasProducts: reel.taggedProducts.isNotEmpty,
      bottomInset: padding.bottom,
    ),
  );
}

/// A single full-screen reel page.
///
/// Most reels play full-bleed with a gradient scrim, creator info, caption,
/// right-rail actions and tagged products drawn over the video. Nothing may
/// be drawn over a YouTube player, so a YouTube reel plays in its own
/// rectangle with the actions beside it and the rest below.
///
/// [isActive] must be true for the reel currently visible in the viewport
/// so that [ReelPlayer] plays it and pauses all others.
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
    if (source is! EmbedSource) return _buildOverPlayer(null);
    final embed = EmbedRequest(source);
    return EmbedLayoutPolicy.reservesPlayerRect(source.platform)
        ? _buildBesidePlayer(embed)
        : _buildOverPlayer(embed);
  }

  Widget _buildOverPlayer(EmbedRequest? embed) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelPlayer(
          reel: widget.reel,
          isActive: widget.isActive,
          playbackController: _playback,
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
                TaggedProductsSection(products: widget.reel.taggedProducts),
              ],
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBesidePlayer(EmbedRequest embed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = MediaQuery.paddingOf(context);
        final player = reelPlayerRect(
          widget.reel,
          constraints.biggest,
          padding,
        );
        return Stack(
          children: [
            Positioned.fromRect(
              rect: player,
              child: ReelPlayer(
                reel: widget.reel,
                isActive: widget.isActive,
                playbackController: _playback,
              ),
            ),

            // Tap target for play/pause. It draws nothing, so the player
            // stays unobstructed.
            Positioned.fromRect(
              rect: player,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _playback.toggle,
              ),
            ),

            Positioned(
              left: player.right,
              top: player.top,
              right: 0,
              height: player.height,
              child: Column(
                children: [
                  const SizedBox(height: DesignTokens.s8),
                  _PausedMark(embed: embed),
                  _SoundOffButton(embed: embed),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ReelActions(reel: widget.reel),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                ],
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              top: player.bottom,
              bottom: 0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: DesignTokens.s12,
                  bottom: padding.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CreatorInfo(reel: widget.reel),
                    if (widget.reel.taggedProducts.isNotEmpty) ...[
                      const SizedBox(height: DesignTokens.s12),
                      TaggedProductsSection(
                        products: widget.reel.taggedProducts,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shown beside a YouTube player while the viewer has it paused.
class _PausedMark extends StatelessWidget {
  const _PausedMark({required this.embed});

  final EmbedRequest embed;

  @override
  Widget build(BuildContext context) {
    final pool = EmbedPlayerScope.maybeOf(context);
    if (pool == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: pool,
      builder: (context, _) {
        if (pool.activeKey != embed.key || !pool.userPaused) {
          return const SizedBox.shrink();
        }
        return const Padding(
          padding: EdgeInsets.only(bottom: DesignTokens.s8),
          child: ReelPlayIndicator(size: 40),
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
