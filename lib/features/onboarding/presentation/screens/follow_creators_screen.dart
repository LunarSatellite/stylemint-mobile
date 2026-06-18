import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/models/creator_dto.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Follow Creators — pixel-matched to Figma frame `9383:4993`
/// (card component `9383:2095`).
///
/// Title + subtitle → scrollable list of creator cards (avatar, name/handle,
/// Follow toggle, category, description, rating/followers) → sticky Continue /
/// Skip bottom bar.
class FollowCreatorsScreen extends ConsumerStatefulWidget {
  const FollowCreatorsScreen({super.key});

  @override
  ConsumerState<FollowCreatorsScreen> createState() =>
      _FollowCreatorsScreenState();
}

class _FollowCreatorsScreenState extends ConsumerState<FollowCreatorsScreen> {
  final Set<String> _following = {};

  @override
  void initState() {
    super.initState();
    unawaited(Future.microtask(
      () => ref.read(fetchCreatorsProvider.notifier).fetch(),
    ));
  }

  void _toggleFollow(String id) {
    setState(() {
      if (_following.contains(id)) {
        _following.remove(id);
      } else {
        _following.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fetchState = ref.watch(fetchCreatorsProvider);

    ref.listen(followCreatorsProvider, (_, next) {
      if (next.saved) context.go(RouteNames.home);
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save. Please try again.'),
          ),
        );
      }
    });

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
            Expanded(child: _buildBody(fetchState)),
            Consumer(
              builder: (context, ref, _) {
                final followState = ref.watch(followCreatorsProvider);
                return SmStickyBottomBar(
                  primaryLabel: followState.isLoading ? 'Saving...' : 'Continue',
                  onPrimary: followState.isLoading
                      ? null
                      : () {
                          if (_following.isEmpty) {
                            context.go(RouteNames.home);
                          } else {
                            ref
                                .read(followCreatorsProvider.notifier)
                                .follow(_following.toList());
                          }
                        },
                  secondaryLabel: 'Skip',
                  onSecondary: () => context.go(RouteNames.home),
                  showTopDivider: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FetchCreatorsState state) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
    }

    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load creators', style: DesignTokens.bodyText),
            const SizedBox(height: DesignTokens.s16),
            TextButton(
              onPressed: () {
                unawaited(
                  ref.read(fetchCreatorsProvider.notifier).fetch(),
                );
              },
              child: const Text('Retry',
                  style: TextStyle(color: DesignTokens.primaryGreen)),
            ),
          ],
        ),
      );
    }

    if (state.creators.isEmpty) {
      return Center(
        child: Text('No creators found', style: DesignTokens.bodyText),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      itemCount: state.creators.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s20),
      itemBuilder: (_, i) {
        final c = state.creators[i];
        return _CreatorCard(
          creator: c,
          following: _following.contains(c.id),
          onFollow: () => _toggleFollow(c.id),
        );
      },
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
  final CreatorDto creator;
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
              _Avatar(avatarUrl: creator.avatarUrl),
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
                  value: creator.formattedRating,
                  label: 'Stars'),
              const SizedBox(width: DesignTokens.s16),
              _Stat(
                  icon: Icons.person,
                  value: creator.formattedFollowers,
                  label: 'Followers'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  const _Avatar({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(avatarUrl!),
        backgroundColor: DesignTokens.bgAppBodyLight,
      );
    }
    return const CircleAvatar(
      radius: 20,
      backgroundColor: DesignTokens.bgAppBodyLight,
      child: Icon(Icons.person, color: DesignTokens.textMuted, size: 22),
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
