import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class PlatformCard extends StatelessWidget {
  const PlatformCard({
    super.key,
    required this.account,
    required this.onConnect,
    required this.onDisconnect,
  });

  final SocialAccount account;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: account.platform.color.withValues(alpha: 0.15),
            radius: DesignTokens.iconMedium,
            child: Icon(
              account.platform.icon,
              color: account.platform.color,
              size: DesignTokens.iconMedium,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.platform.displayName,
                  style: DesignTokens.oneLinerSemibold,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  account.isConnected
                      ? '@${account.handle}  ·  ${_formatCount(account.followerCount)} followers'
                      : 'Not connected',
                  style: DesignTokens.smallRegular,
                ),
              ],
            ),
          ),
          if (account.isConnected)
            TextButton(
              onPressed: onDisconnect,
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.colorError,
              ),
              child: const Text('Disconnect'),
            )
          else
            ElevatedButton(
              onPressed: onConnect,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.textDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
              ),
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
