import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/creator_chip_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_sticky_bottom_bar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Follow Creators (onboarding step). Real suggestions from
/// `GET /api/v1/customer/feed/creators-you-may-like`, Follow toggle calls the
/// real follow graph via [followNotifierProvider] — same data source as the
/// [FollowCreatorsDiscoveryScreen] used elsewhere in the app. Previously a
/// static list of 5 fake creators whose Follow button only flipped local
/// state and never called any API.
final _suggestedCreatorsProvider =
    FutureProvider.autoDispose<List<CreatorChipDto>>((ref) async {
  final ApiClient api = ref.watch(apiClientProvider);
  final res = await api.get(
    '/api/v1/customer/feed/creators-you-may-like',
    queryParameters: {'limit': 20},
  );
  final map = res as Map<String, dynamic>;
  final items = (map['items'] as List<dynamic>? ?? const <dynamic>[]);
  return items
      .whereType<Map<String, dynamic>>()
      .map(CreatorChipDto.fromJson)
      .toList(growable: false);
});

class FollowCreatorsScreen extends ConsumerStatefulWidget {
  const FollowCreatorsScreen({super.key});

  @override
  ConsumerState<FollowCreatorsScreen> createState() =>
      _FollowCreatorsScreenState();
}

class _FollowCreatorsScreenState extends ConsumerState<FollowCreatorsScreen> {
  Future<void> _toggle(String accountId) async {
    try {
      await ref.read(followNotifierProvider.notifier).toggle(accountId);
    } catch (_) {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_suggestedCreatorsProvider);
    final followed = ref.watch(followNotifierProvider);

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
              child: async.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: DesignTokens.primaryGreen)),
                error: (_, _e) => Center(
                  child: Text("Couldn't load creators.",
                      style: DesignTokens.bodyText),
                ),
                data: (creators) => creators.isEmpty
                    ? Center(
                        child: Text('No suggestions right now.',
                            style: DesignTokens.bodyText),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16),
                        itemCount: creators.length,
                        separatorBuilder: (_, _i) =>
                            const SizedBox(height: DesignTokens.s20),
                        itemBuilder: (_, i) {
                          final c = creators[i];
                          return _CreatorCard(
                            creator: c,
                            following: followed.contains(c.creatorProfileId),
                            onFollow: () => _toggle(c.creatorProfileId),
                          );
                        },
                      ),
              ),
            ),
            SmStickyBottomBar(
              primaryLabel: 'Proceed',
              primaryTrailing: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: DesignTokens.buttonPrimaryText, // #06190E
              ),
              onPrimary: () => context.go(RouteNames.followBrands),
              secondaryLabel: 'Skip',
              onSecondary: () => context.go(RouteNames.followBrands),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Follow Creators You Love',
          textAlign: TextAlign.center,
          style: DesignTokens.titleMedium,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'Get Personalized recommendations from creators in Fashion, Beauty, and Fitness',
          textAlign: TextAlign.center,
          style: DesignTokens.bodyText,
        ),
      ],
    );
  }
}

/// Creator card — Figma `9383:2095` (#18181B fill, 16px radius).
class _CreatorCard extends StatelessWidget {
  final CreatorChipDto creator;
  final bool following;
  final VoidCallback onFollow;

  const _CreatorCard({
    required this.creator,
    required this.following,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = creator.avatarUrl;
    final name = creator.displayName.isEmpty
        ? '@${creator.handle}'
        : creator.displayName;
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
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: (avatar == null || avatar.isEmpty)
                      ? const ColoredBox(
                          color: DesignTokens.bgAppBodyLight,
                          child: Icon(Icons.person,
                              color: DesignTokens.textMuted, size: 22),
                        )
                      : Image.network(avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _e, _s) => const ColoredBox(
                              color: DesignTokens.bgAppBodyLight,
                              child: Icon(Icons.person,
                                  color: DesignTokens.textMuted, size: 22))),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.oneLinerSemibold),
                    const SizedBox(height: DesignTokens.s4),
                    Text('@${creator.handle}',
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
          // Stats
          Row(
            children: [
              _Stat(
                  icon: Icons.person,
                  iconColor: const Color(0xFF9F9FA9), // Icon-Light
                  value: _compact(creator.followerCount),
                  label: 'Followers'),
              const SizedBox(width: DesignTokens.s16),
              _Stat(
                  icon: Icons.video_library_outlined,
                  iconColor: const Color(0xFF9F9FA9),
                  value: '${creator.reelCount}',
                  label: 'Reels'),
            ],
          ),
        ],
      ),
    );
  }

  String _compact(int n) {
    if (n < 1000) return '$n';
    final k = n / 1000;
    return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
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
  final Color iconColor;
  final String value;
  final String label;
  const _Stat({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: DesignTokens.iconSmall, color: iconColor),
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
