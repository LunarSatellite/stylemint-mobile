import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Profile header: avatar, name, email and an edit button.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.summary,
    required this.onEdit,
    required this.onNotifications,
    super.key,
  });

  final ProfileSummary summary;
  final VoidCallback onEdit;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: [
          CircleAvatar(
            // Figma's profile-header avatar is 64x64, distinct from the
            // shared avatarLarge (56) token used elsewhere — sized locally
            // rather than changing that shared constant.
            radius: 32,
            backgroundColor: DesignTokens.bgAppBodyLight,
            backgroundImage:
                summary.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(summary.avatarUrl)
                    : null,
            child:
                summary.avatarUrl.isEmpty
                    ? const Icon(Icons.person, color: DesignTokens.iconLight)
                    : null,
          ),
          const SizedBox(width: DesignTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.displayName,
                  // Figma spec is 20/600 for the profile-header name,
                  // distinct from the shared sectionInnerTitle (18/600)
                  // token used elsewhere — overridden locally.
                  style: DesignTokens.sectionInnerTitle.copyWith(
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  summary.email,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            style: IconButton.styleFrom(
              backgroundColor: DesignTokens.bgAppBodyLight,
            ),
            icon: const Icon(
              Icons.notifications_none_rounded,
              size: DesignTokens.iconSmall,
              color: DesignTokens.iconWhite,
            ),
          ),
          IconButton(
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: DesignTokens.bgAppBodyLight,
            ),
            icon: const Icon(
              Icons.edit_outlined,
              size: DesignTokens.iconSmall,
              color: DesignTokens.iconWhite,
            ),
          ),
        ],
      ),
    );
  }
}
