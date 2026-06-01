import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/profile_summary.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({
    required this.summary,
    super.key,
  });

  final ProfileSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.favorite_border_rounded,
              value: summary.savedItemsCount,
              label: 'Saved Items',
              onTap: () => context.push('${RouteNames.profile}/saved-items'),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: _StatCard(
              icon: Icons.group_outlined,
              value: summary.followingCount,
              label: 'Following',
              onTap: () => context.push('${RouteNames.profile}/following'),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: _StatCard(
              icon: Icons.inventory_2_outlined,
              value: summary.ordersCount,
              label: 'My Orders',
              badge: summary.ordersCount,
              onTap: () => context.go(RouteNames.orders),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: DesignTokens.iconWhite),
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.colorError,
                        borderRadius: BorderRadius.circular(DesignTokens.s8),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Text('$value', style: DesignTokens.sectionInnerTitle),
            const SizedBox(height: DesignTokens.s4),
            Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
