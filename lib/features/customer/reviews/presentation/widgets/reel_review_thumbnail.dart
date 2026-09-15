import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/shared/playback/linked_reel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_playback_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_poster.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

typedef ReelReviewPlayCallback =
    void Function(BuildContext context, LinkedReel reel);

/// A reel review's tile in a product's review grid.
///
/// When the review's link resolves to a reel StyleMint can play in the
/// platform's official embedded player (YouTube, TikTok, Facebook with a
/// readable video id), a tap plays it in-app ([showReelPlaybackSheet]).
/// Otherwise the tile is shown but not tappable. It never opens the platform.
class ReelReviewThumbnail extends StatelessWidget {
  const ReelReviewThumbnail({
    required this.review,
    this.compact = false,
    this.onPlay,
    super.key,
  });

  final Review review;

  /// Smaller icon and label, for the product page's 3-column preview grid.
  final bool compact;

  /// Plays the reel. Defaults to [showReelPlaybackSheet].
  final ReelReviewPlayCallback? onPlay;

  static void _playInSheet(BuildContext context, LinkedReel reel) =>
      unawaited(showReelPlaybackSheet(context, reel));

  @override
  Widget build(BuildContext context) {
    final url = review.reelSourceUrl;
    final reel = LinkedReel.playable(url: url, platform: review.reelPlatform);
    final platform =
        SocialPlatform.tryParseWire(review.reelPlatform) ??
        LinkedReel.platformOfLink(url ?? '');
    final label = platform?.displayName ?? 'Reel';
    final play = onPlay ?? _playInSheet;
    final onTap = reel == null ? null : () => play(context, reel);
    final inset = compact ? 4.0 : 6.0;

    return Semantics(
      container: true,
      button: onTap != null,
      label: onTap == null ? '$label reel review' : 'Play $label reel review',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: DesignTokens.bgAppBodyLight,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (reel != null && ReelPoster.urlFor(reel) != null)
                ReelPoster(reel: reel),
              if (reel != null)
                Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white70,
                    size: compact ? 26 : 32,
                  ),
                ),
              Positioned(
                left: inset,
                right: inset,
                bottom: inset,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    color: Colors.white,
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Color(0x80000000), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
