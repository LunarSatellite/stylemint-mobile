import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Facebook-style action row under a post: Like, Comment and Share as
/// three equal-width buttons, each an icon and a label. Counts are not drawn
/// here — the card's summary line above carries "N likes" and "N comments".
///
/// A liked post shows a filled red heart and a red "Like" label.
class PostActionBar extends StatelessWidget {
  const PostActionBar({
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    super.key,
  });

  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : DesignTokens.motionFast;
    // Transparent Material so the ripples have somewhere to paint even when
    // the bar is used outside a card.
    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              key: const Key('post-action-like'),
              semanticLabel: isLiked ? 'Unlike post' : 'Like post',
              label: 'Like',
              labelColor: isLiked
                  ? DesignTokens.accentHeart
                  : DesignTokens.textLight,
              onTap: onLike,
              icon: AnimatedSwitcher(
                duration: motion,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey<bool>(isLiked),
                  size: DesignTokens.iconMedium,
                  color: isLiked
                      ? DesignTokens.accentHeart
                      : DesignTokens.iconWhite,
                ),
              ),
            ),
          ),
          Expanded(
            child: _ActionButton(
              key: const Key('post-action-comment'),
              semanticLabel: 'Comment on post',
              label: 'Comment',
              onTap: onComment,
              icon: const Icon(
                Icons.mode_comment_outlined,
                size: DesignTokens.iconMedium,
                color: DesignTokens.iconWhite,
              ),
            ),
          ),
          Expanded(
            child: _ActionButton(
              key: const Key('post-action-share'),
              semanticLabel: 'Share post',
              label: 'Share',
              onTap: onShare,
              // A paper plane tilted up, like Instagram's share glyph.
              icon: Transform.rotate(
                angle: -math.pi / 9,
                child: const Icon(
                  Icons.send_outlined,
                  size: DesignTokens.iconMedium,
                  color: DesignTokens.iconWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.semanticLabel,
    required this.label,
    required this.onTap,
    required this.icon,
    this.labelColor = DesignTokens.textLight,
    super.key,
  });

  final String semanticLabel;
  final String label;
  final VoidCallback onTap;
  final Widget icon;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          child: SizedBox(
            height: DesignTokens.minTouchTarget,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: DesignTokens.s6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
