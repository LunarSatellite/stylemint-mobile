import 'dart:ui' show ImageFilter;

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
    // Spec: single glassmorphic interaction pill (radius 20, rgba(51,51,51,0.6),
    // blur 20, padding 16, gap 4) — not separate per-icon circles.
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: const Color(0xFF333333).withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_outline,
                label: _formatCount(_likeCount),
                color: _isLiked
                    ? DesignTokens.colorError
                    : DesignTokens.iconWhite,
                onTap: _toggleLike,
              ),
              const SizedBox(height: DesignTokens.s4),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: _formatCount(reel.commentCount),
                onTap: () => _requireAuth(
                  AuthReason.comment,
                  () => context.push('/reels/${reel.id}/comments'),
                ),
              ),
              const SizedBox(height: DesignTokens.s4),
              _ActionButton(
                icon: Icons.share_outlined,
                label: _formatCount(reel.shareCount),
                onTap: () => _requireAuth(AuthReason.share, () {}),
              ),
              const SizedBox(height: DesignTokens.s4),
              _ActionButton(
                icon: _isWishlisted ? Icons.bookmark : Icons.bookmark_outline,
                color: _isWishlisted
                    ? DesignTokens.secondaryYellow
                    : DesignTokens.iconWhite,
                onTap: _toggleWishlist,
              ),
            ],
          ),
        ),
      ),
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
          Icon(icon, color: color, size: 24),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              label!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: DesignTokens.textWhite,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
