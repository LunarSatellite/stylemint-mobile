import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PostActionBar extends StatelessWidget {
  const PostActionBar({
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    super.key,
  });

  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
      child: Row(
        children: [
          _ActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_outline,
            label: _formatCount(likeCount),
            color: isLiked ? DesignTokens.colorError : DesignTokens.iconLight,
            onTap: onLike,
          ),
          const SizedBox(width: DesignTokens.s16),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(commentCount),
            onTap: onComment,
          ),
          const Spacer(),
          _ActionButton(
            icon: Icons.share_outlined,
            label: _formatCount(shareCount),
            onTap: onShare,
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count > 0 ? '$count' : '';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.color = DesignTokens.iconLight,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: DesignTokens.iconMedium, color: color),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(width: DesignTokens.s4),
            Text(
              label!,
              style: DesignTokens.smallRegular.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
