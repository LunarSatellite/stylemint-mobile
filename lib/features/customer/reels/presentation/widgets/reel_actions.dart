import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Right-rail reel actions: like, comment, share, wishlist, cart.
/// Interactive actions require authentication — tapping triggers a sign-in
/// prompt for unauthenticated users.
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

  bool get _isAuthenticated {
    final session = ref.read(sessionControllerProvider);
    return session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );
  }

  void _requireAuth(VoidCallback action) {
    if (_isAuthenticated) {
      action();
      return;
    }
    _showSignInPrompt();
  }

  void _showSignInPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.s24),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s24,
          DesignTokens.s24,
          DesignTokens.s24,
          DesignTokens.s32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignTokens.s24),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: DesignTokens.primaryGreen, size: 32),
            ),
            const SizedBox(height: DesignTokens.s16),
            Text('Sign in to interact',
                style: DesignTokens.titleMedium.copyWith(
                    color: DesignTokens.textWhite)),
            const SizedBox(height: DesignTokens.s8),
            Text('Like, comment, share, and save products by signing in.',
                textAlign: TextAlign.center,
                style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted)),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(RouteNames.signInMethod);
                },
                child: const Text('Sign In',
                    style: TextStyle(fontFamily: DesignTokens.fontFamily,
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Maybe later',
                  style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike() {
    _requireAuth(() {
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    });
  }

  void _toggleWishlist() {
    _requireAuth(() {
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
          onTap: () => _requireAuth(() {}),
        ),
        const SizedBox(height: DesignTokens.s16),
        _ActionButton(
          icon: Icons.share_outlined,
          label: _formatCount(reel.shareCount),
          onTap: () => _requireAuth(() {}),
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
          onTap: () => _requireAuth(() {}),
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
