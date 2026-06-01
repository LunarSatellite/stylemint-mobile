import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FriendRequestTile extends StatelessWidget {
  const FriendRequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    super.key,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Row(
        children: [
          CircleAvatar(
            radius: DesignTokens.avatarMedium / 2,
            backgroundImage: NetworkImage(request.senderAvatarUrl),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.senderName,
                  style: DesignTokens.mediumSemibold,
                ),
                Text(
                  '@${request.senderHandle}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                if (request.mutualFriends > 0)
                  Text(
                    '${request.mutualFriends} mutual friends',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDecline,
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.textMuted,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
              ),
            ),
            child: const Text('Decline'),
          ),
          const SizedBox(width: DesignTokens.s4),
          ElevatedButton(
            onPressed: onAccept,
            style: DesignTokens.primaryButtonStyle().copyWith(
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
              ),
              minimumSize: WidgetStateProperty.all(
                const Size(0, 36),
              ),
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
