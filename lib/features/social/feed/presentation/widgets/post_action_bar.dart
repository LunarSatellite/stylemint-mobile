import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The Instagram-style action row under a post: like, comment and share on
/// the left. Counts are not drawn here — the card prints "N likes" and
/// "View all N comments" underneath, as Instagram does.
///
/// [indicator] sits centred in the row; the card passes its carousel dots.
class PostActionBar extends StatelessWidget {
  const PostActionBar({
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    this.indicator,
    super.key,
  });

  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final Widget? indicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DesignTokens.s48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (indicator != null) indicator!,
          Row(
            children: [
              _ActionButton(
                key: const Key('post-action-like'),
                semanticLabel: isLiked ? 'Unlike post' : 'Like post',
                onTap: onLike,
                child: AnimatedSwitcher(
                  duration: DesignTokens.motionFast,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(isLiked),
                    size: 26,
                    color: isLiked
                        ? DesignTokens.accentHeart
                        : DesignTokens.iconWhite,
                  ),
                ),
              ),
              _ActionButton(
                key: const Key('post-action-comment'),
                semanticLabel: 'Comment on post',
                onTap: onComment,
                child: const Icon(
                  Icons.mode_comment_outlined,
                  size: DesignTokens.iconMedium,
                  color: DesignTokens.iconWhite,
                ),
              ),
              _ActionButton(
                key: const Key('post-action-share'),
                semanticLabel: 'Share post',
                onTap: onShare,
                // A paper plane tilted up, like Instagram's share glyph.
                child: Transform.rotate(
                  angle: -math.pi / 9,
                  child: const Icon(
                    Icons.send_outlined,
                    size: DesignTokens.iconMedium,
                    color: DesignTokens.iconWhite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: DesignTokens.minTouchTarget,
            height: DesignTokens.minTouchTarget,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
