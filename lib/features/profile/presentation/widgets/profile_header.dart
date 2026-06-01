import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Profile header: avatar, name, email and an edit button.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({required this.summary, required this.onEdit, super.key});

  final ProfileSummary summary;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: [
          CircleAvatar(
            radius: DesignTokens.avatarLarge / 2,
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
                  style: DesignTokens.sectionInnerTitle,
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
