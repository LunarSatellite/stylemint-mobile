import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class _Creator {
  final String name;
  final String handle;
  final String category;
  final String description;
  final String rating;
  final String followers;
  const _Creator(this.name, this.handle, this.category, this.description,
      this.rating, this.followers);
}

/// Follow Creators — pixel-matched to Figma frame `9383:4993`
/// (card component `9383:2095`).
///
/// Title + subtitle → scrollable list of creator cards (avatar, name/handle,
/// Follow toggle, category, description, rating/followers) → sticky Continue /
/// Skip bottom bar.
class FollowCreatorsScreen extends StatefulWidget {
  const FollowCreatorsScreen({super.key});

  @override
  State<FollowCreatorsScreen> createState() => _FollowCreatorsScreenState();
}

class _FollowCreatorsScreenState extends State<FollowCreatorsScreen> {
  // TODO: source creators from the API; placeholder set for now.
  static const List<_Creator> _creators = [
    _Creator('Shree Teen', '@alieen.ace43', 'Travel & Skincare',
        'Get Personalized recommendations from creators in Fashion, Beauty, and Fitness', '4.9', '52.3k'),
    _Creator('Maya Lume', '@maya.lume', 'Fashion & Lifestyle',
        'Daily fits, styling hacks and the latest drops curated for you', '4.8', '128k'),
    _Creator('Ravi Kit', '@ravikit', 'Tech & Gadgets',
        'Hands-on reviews and honest takes on the gear worth your money', '4.7', '87.1k'),
    _Creator('Nina Bloom', '@ninabloom', 'Beauty & Skincare',
        'Clean beauty routines and product breakdowns for every skin type', '5.0', '203k'),
    _Creator('Theo Run', '@theoruns', 'Fitness & Wellness',
        'Workouts, recovery tips and gear to keep you moving', '4.6', '64.8k'),
  ];

  final Set<String> _following = {};

  void _toggleFollow(String handle) {
    setState(() {
      if (_following.contains(handle)) {
        _following.remove(handle);
      } else {
        _following.add(handle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, 0),
              child: _Header(),
            ),
            const SizedBox(height: DesignTokens.s24),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16),
                itemCount: _creators.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: DesignTokens.s20),
                itemBuilder: (_, i) {
                  final c = _creators[i];
                  return _CreatorCard(
                    creator: c,
                    following: _following.contains(c.handle),
                    onFollow: () => _toggleFollow(c.handle),
                  );
                },
              ),
            ),
            SmStickyBottomBar(
              primaryLabel: 'Continue',
              onPrimary: () => context.go(RouteNames.home),
              secondaryLabel: 'Skip',
              onSecondary: () => context.go(RouteNames.home),
              showTopDivider: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Follow Creators You Love', style: DesignTokens.titleMedium),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Get Personalized recommendations from creators in Fashion, Beauty, and Fitness',
          style: DesignTokens.bodyText,
        ),
      ],
    );
  }
}

/// Creator card — Figma `9383:2095` (#18181B fill, 16px radius).
class _CreatorCard extends StatelessWidget {
  final _Creator creator;
  final bool following;
  final VoidCallback onFollow;

  const _CreatorCard({
    required this.creator,
    required this.following,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name/handle + Follow
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: DesignTokens.bgAppBodyLight,
                child: Icon(Icons.person,
                    color: DesignTokens.textMuted, size: 22),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(creator.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.oneLinerSemibold),
                    const SizedBox(height: DesignTokens.s4),
                    Text(creator.handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              _FollowButton(following: following, onTap: onFollow),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Category + description
          Text(creator.category,
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.textWhite, fontSize: 12)),
          const SizedBox(height: DesignTokens.s4),
          Text(creator.description,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight)),
          const SizedBox(height: DesignTokens.s12),
          // Stats
          Row(
            children: [
              _Stat(
                  icon: Icons.star_rounded,
                  value: creator.rating,
                  label: 'Stars'),
              const SizedBox(width: DesignTokens.s16),
              _Stat(
                  icon: Icons.person,
                  value: creator.followers,
                  label: 'Followers'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;
  const _FollowButton({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: following ? DesignTokens.primaryGreen : DesignTokens.buttonGrayFill,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
          child: Text(
            following ? 'Following' : 'Follow',
            style: DesignTokens.smallRegular.copyWith(
              fontWeight: FontWeight.w600,
              color: following
                  ? DesignTokens.buttonPrimaryText
                  : DesignTokens.buttonGrayText,
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: DesignTokens.iconSmall, color: DesignTokens.textLight),
        const SizedBox(width: DesignTokens.s4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                  text: '$value ',
                  style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite)),
              TextSpan(
                  text: label,
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textLight)),
            ],
          ),
        ),
      ],
    );
  }
}
