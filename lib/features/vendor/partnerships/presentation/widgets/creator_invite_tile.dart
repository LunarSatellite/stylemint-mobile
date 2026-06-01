import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorInviteTile extends StatelessWidget {
  const CreatorInviteTile({
    super.key,
    required this.invite,
    required this.isInviting,
    this.onInvite,
  });

  final CreatorInvite invite;
  final bool isInviting;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final alreadyInvited = onInvite == null;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s4,
      ),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(invite.creatorAvatarUrl),
            backgroundColor: DesignTokens.bgAppBodyLight,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.creatorName, style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '@${invite.creatorHandle}  ·  ${invite.creatorCategory}  ·  ${_formatFollowers(invite.followersCount)}',
                  style: DesignTokens.tiny,
                ),
              ],
            ),
          ),
          if (alreadyInvited)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s8,
                vertical: DesignTokens.s6,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              child: Text(
                'Invited',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: isInviting ? null : onInvite,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.textDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s6,
                ),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                ),
              ),
              child: Text(
                isInviting ? '...' : 'Invite',
                style: DesignTokens.tiny.copyWith(color: DesignTokens.textDark),
              ),
            ),
        ],
      ),
    );
  }

  String _formatFollowers(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
