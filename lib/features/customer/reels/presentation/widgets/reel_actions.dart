import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Right-rail reel actions: like, comment, share, wishlist, cart.
/// Interactive actions are gated through the shared [ensureAuth] — an inline,
/// fingerprint-first prompt for guests.
class ReelActions extends ConsumerStatefulWidget {
  const ReelActions({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends ConsumerState<ReelActions> {
  late bool _isLiked = widget.reel.isLikedByUser ?? false;
  late bool _isWishlisted = widget.reel.isWishlistedByUser ?? false;
  late int _likeCount = widget.reel.likeCount;

  /// Runs [action] only once the user is authenticated; otherwise shows the
  /// inline fingerprint-first auth prompt (contextual to [reason]).
  Future<void> _requireAuth(AuthReason reason, VoidCallback action) async {
    if (await ensureAuth(context, ref, reason: reason)) action();
  }

  void _toggleLike() {
    _requireAuth(AuthReason.like, () {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    });
  }

  void _toggleWishlist() {
    _requireAuth(AuthReason.save, () {
      setState(() => _isWishlisted = !_isWishlisted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          icon: _isLiked ? Icons.favorite : Icons.favorite_outline,
          label: _formatCount(_likeCount),
          color: _isLiked ? DesignTokens.colorError : DesignTokens.iconWhite,
          onTap: _toggleLike,
        ),
        const SizedBox(height: DesignTokens.s16),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(reel.commentCount),
          onTap: () => _requireAuth(
            AuthReason.comment,
            () => context.push('/reels/${reel.id}/comments'),
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        _ActionButton(
          icon: Icons.share_outlined,
          label: _formatCount(reel.shareCount),
          onTap: () => _requireAuth(AuthReason.share, () {}),
        ),
        const SizedBox(height: DesignTokens.s16),
        _ActionButton(
          icon: _isWishlisted ? Icons.bookmark : Icons.bookmark_outline,
          color: _isWishlisted
              ? DesignTokens.secondaryYellow
              : DesignTokens.iconWhite,
          onTap: _toggleWishlist,
        ),
        const SizedBox(height: DesignTokens.s16),
        _ActionButton(
          icon: Icons.shopping_cart_outlined,
          label: reel.taggedProducts.isEmpty
              ? null
              : '${reel.taggedProducts.length}',
          onTap: () => _requireAuth(AuthReason.addToCart, () {}),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.label,
    this.color = DesignTokens.iconWhite,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: DesignTokens.avatarMedium,
            height: DesignTokens.avatarMedium,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignTokens.baseBlack.withValues(alpha: 0.3),
            ),
            child: Icon(icon, color: color, size: DesignTokens.iconMedium),
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              label!,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textWhite),
            ),
          ],
        ],
      ),
    );
  }
}
