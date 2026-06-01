import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/entities/group.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({
    required this.group,
    required this.onTap,
    required this.onJoin,
    super.key,
  });

  final StyleGroup group;
  final VoidCallback onTap;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: DesignTokens.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Image.network(
                    group.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: DesignTokens.bgAppBodyLight,
                      child: const Icon(
                        Icons.group_outlined,
                        color: DesignTokens.textMuted,
                        size: DesignTokens.iconLarge,
                      ),
                    ),
                  ),
                ),
                if (group.isPrivate)
                  Positioned(
                    top: DesignTokens.s8,
                    right: DesignTokens.s8,
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.s4),
                      decoration: BoxDecoration(
                        color: DesignTokens.baseBlack.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.s4,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: DesignTokens.textWhite,
                        size: DesignTokens.iconSmall,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    group.description,
                    style: DesignTokens.smallRegular,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: DesignTokens.iconSmall,
                        color: DesignTokens.textMuted,
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        '${group.memberCount}',
                        style: DesignTokens.smallRegular,
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          group.category,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                            fontSize: 10,
                          ),
                        ),
                        backgroundColor: DesignTokens.primaryGreenLight,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onJoin,
                      style: group.isJoined
                          ? DesignTokens.outlinedButtonStyle().copyWith(
                            minimumSize: WidgetStateProperty.all(
                              const Size(0, 32),
                            ),
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                          )
                          : DesignTokens.primaryButtonStyle().copyWith(
                            minimumSize: WidgetStateProperty.all(
                              const Size(0, 32),
                            ),
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                          ),
                      child: Text(
                        group.isJoined ? 'Joined' : 'Join',
                        style: DesignTokens.smallRegular.copyWith(
                          color: group.isJoined
                              ? DesignTokens.textWhite
                              : DesignTokens.buttonPrimaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
