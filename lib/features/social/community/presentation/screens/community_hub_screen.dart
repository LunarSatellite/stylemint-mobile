import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  static const _destinations = <_CommunityDestination>[
    _CommunityDestination(
      title: 'Friend Feed',
      subtitle: 'Posts and product finds from people you follow',
      icon: Icons.dynamic_feed_outlined,
      route: RouteNames.feed,
    ),
    _CommunityDestination(
      title: 'Style & Professional Circles',
      subtitle: 'Find communities around shared interests and professions',
      icon: Icons.groups_outlined,
      route: RouteNames.groups,
    ),
    _CommunityDestination(
      title: 'Recommendations',
      subtitle: 'Ask the community for product recommendations',
      icon: Icons.recommend_outlined,
      route: RouteNames.recommendations,
    ),
    _CommunityDestination(
      title: 'Live Drop Parties',
      subtitle: 'Join live shopping events and invite-only drops',
      icon: Icons.celebration_outlined,
      route: RouteNames.dropPartiesList,
    ),
    _CommunityDestination(
      title: 'Group Carts',
      subtitle: 'Shop, compare, and vote together',
      icon: Icons.shopping_cart_outlined,
      route: RouteNames.groupCartsList,
    ),
    _CommunityDestination(
      title: 'Tips',
      subtitle: 'Support creators and review your tip history',
      icon: Icons.volunteer_activism_outlined,
      route: RouteNames.tips,
    ),
    _CommunityDestination(
      title: 'Friends',
      subtitle: 'Manage friends and connection requests',
      icon: Icons.people_outline,
      route: RouteNames.friends,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text(
          'Community & Social',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: SafeArea(
        key: const Key('community-hub-safe-area'),
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.all(DesignTokens.s16),
          itemCount: _destinations.length,
          separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s12),
          itemBuilder: (context, index) {
            final destination = _destinations[index];
            return Material(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                leading: Icon(
                  destination.icon,
                  color: DesignTokens.primaryGreen,
                ),
                title: Text(
                  destination.title,
                  style: DesignTokens.mediumSemibold,
                ),
                subtitle: Text(
                  destination.subtitle,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: DesignTokens.iconLight,
                ),
                onTap: () => context.push(destination.route),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommunityDestination {
  const _CommunityDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
