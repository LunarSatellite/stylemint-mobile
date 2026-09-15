import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_layout_policy.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_player_scope.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/embed_slot.dart';
import 'package:stylemint_mobile_frontend/shared/playback/embed/reel_shapes.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_resolver.dart';
import 'package:stylemint_mobile_frontend/shared/playback/reel_playback_source.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where the player sits on a feed page of size [page]. A vertical reel fills
/// the whole page with no bars: its player takes the reel's shape and covers
/// the page, which clips the overflow. A square or landscape video shows
/// whole, the way it was made: its player fills the page and the platform fits
/// the picture inside. Reels are vertical (9:16) unless [ReelShapes] learns a
/// YouTube video's real shape. A native video fills the page and follows the
/// same rule itself. The feed places its shared players with the same
/// rectangle. [topInset] is the status bar's height: a TikTok player starts
/// below it (see [EmbedLayoutPolicy.keepsClearOfStatusBar]).
Rect reelPlayerRect(Reel reel, Size page, {double topInset = 0}) {
  final source = resolveReelPlayback(reel);
  if (source is! EmbedSource) return Offset.zero & page;
  final aspect =
      ReelShapes.instance.aspectOf(reel) ?? EmbedLayoutPolicy.shortsAspectRatio;
  if (topInset > 0 &&
      EmbedLayoutPolicy.keepsClearOfStatusBar(source.platform)) {
    return EmbedLayoutPolicy.fillsScreen(aspect)
        ? EmbedLayoutPolicy.coverRectBelow(
            page: page,
            aspectRatio: aspect,
            topInset: topInset,
          )
        : Rect.fromLTRB(
            0,
            topInset.clamp(0.0, page.height),
            page.width,
            page.height,
          );
  }
  return EmbedLayoutPolicy.fillsScreen(aspect)
      ? EmbedLayoutPolicy.coverRect(page: page, aspectRatio: aspect)
      : Offset.zero & page;
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
  void initState() {
    super.initState();
    unawaited(ReelShapes.instance.learnReel(widget.reel));
  }

  @override
  void didUpdateWidget(ReelCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.reel, widget.reel)) {
      unawaited(ReelShapes.instance.learnReel(widget.reel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = resolveReelPlayback(widget.reel);
    final embed = source is EmbedSource ? EmbedRequest(source) : null;
    final topInset = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: ReelShapes.instance,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final player = reelPlayerRect(
            widget.reel,
            constraints.biggest,
            topInset: topInset,
          );
          return Stack(
            fit: StackFit.expand,
            // The player can be larger than the page; the page clips it.
            clipBehavior: Clip.hardEdge,
            children: [
              // Behind the status bar, above a player that starts below it:
              // plain black, beside the player rather than over it.
              if (player.top > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  height: player.top,
                  child: const ColoredBox(color: DesignTokens.baseBlack),
                ),
              Positioned.fromRect(
                rect: player,
                child: ReelPlayer(
                  reel: widget.reel,
                  isActive: widget.isActive,
                  playbackController: _playback,
                ),
              ),

              // Full-screen tap target for play/pause. Sits above the video
              // but below the interactive controls, so a tap anywhere toggles
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

              // Right rail (creator + follow, like, comments, share, tagged
              // product or cart), drawn over the video for every platform —
              // pulled down so it sits near the creator row instead of
              // floating high above it.
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
                      // The rail carries follow; this row keeps name + track.
                      child: CreatorInfo(reel: widget.reel, showFollow: false),
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
      ),
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
