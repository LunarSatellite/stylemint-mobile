import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/creator_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A single full-screen reel: video pointer background with a gradient
/// scrim, creator info + caption, right-rail actions and tagged products.
class ReelCard extends StatelessWidget {
  const ReelCard({required this.reel, super.key});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tap-to-open external video (IG / TikTok / YouTube / FB).
        ReelPlayer(reel: reel),

        // Bottom scrim so overlaid text stays legible over any thumbnail.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.45, 1.0],
            ),
          ),
        ),

        // Right-rail actions (like / comment / share / wishlist / cart).
        Positioned(
          right: DesignTokens.s12,
          bottom: 220,
          child: ReelActions(reel: reel),
        ),

        // Creator info, caption and tagged products pinned to the bottom.
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 72),
                child: CreatorInfo(reel: reel),
              ),
              if (reel.taggedProducts.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                TaggedProductsSection(products: reel.taggedProducts),
              ],
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        ),
      ],
    );
  }
}
