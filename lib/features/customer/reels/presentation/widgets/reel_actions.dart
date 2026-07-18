import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Right-rail reel actions: like, comment, share, cart (Design Spec Doc —
/// Home Page Reel.pdf, "Reel Interactions" §1-4).
///
/// Like and comment work without authentication (optimistic local state).
/// Share and cart are gated through [ensureAuth].
class ReelActions extends ConsumerStatefulWidget {
  const ReelActions({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends ConsumerState<ReelActions> {
  late bool _isLiked = widget.reel.isLikedByUser ?? false;
  late int _likeCount = widget.reel.likeCount;

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _openComments() {
    showReelCommentsSheet(context, widget.reel.id);
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
        const SizedBox(height: DesignTokens.s20),
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(reel.commentCount),
          onTap: _openComments,
        ),
        const SizedBox(height: DesignTokens.s20),
        _ActionButton(
          icon: Icons.share_outlined,
          label: _formatCount(reel.shareCount),
          onTap: () async {
            if (await ensureAuth(context, ref, reason: AuthReason.share)) {
              // share action
            }
          },
        ),
        const SizedBox(height: DesignTokens.s20),
        _ActionButton(
          icon: Icons.shopping_cart_outlined,
          onTap: () async {
            if (await ensureAuth(context, ref, reason: AuthReason.addToCart)) {
              if (context.mounted) await context.push('/cart');
            }
          },
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          // Spec: "Reel Interaction Container" — radius 20, blur(20px),
          // padding 16px, gap 4px, icon 24x24, count 10/600/100%.
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.s16),
            decoration: BoxDecoration(
              color: const Color(0x99333333),
              borderRadius: BorderRadius.circular(20),
            ),
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
                      height: 1,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
