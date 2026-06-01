import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FriendTile extends StatelessWidget {
  const FriendTile({required this.friend, this.onUnfriend, super.key});

  final Friend friend;
  final VoidCallback? onUnfriend;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: DesignTokens.avatarMedium / 2,
        backgroundImage: NetworkImage(friend.avatarUrl),
      ),
      title: Text(
        friend.displayName,
        style: DesignTokens.mediumSemibold,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '@${friend.handle}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          if (friend.mutualFriends > 0)
            Text(
              '${friend.mutualFriends} mutual friends',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.primaryGreen,
                fontSize: 11,
              ),
            ),
        ],
      ),
      trailing: onUnfriend != null
          ? TextButton(
            onPressed: onUnfriend,
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
              ),
            ),
            child: const Text('Unfriend'),
          )
          : null,
    );
  }
}
