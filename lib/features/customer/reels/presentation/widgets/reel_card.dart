import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

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
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelPlayer(
          videoUrl: widget.reel.videoUrl,
          thumbnailUrl: widget.reel.thumbnailUrl,
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
}
