import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FollowingScreen extends ConsumerStatefulWidget {
  const FollowingScreen({super.key});

  @override
  ConsumerState<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends ConsumerState<FollowingScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(followingNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Following', style: DesignTokens.sectionInnerTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              0,
              DesignTokens.s16,
              DesignTokens.s12,
            ),
            child: TextFormField(
              controller: _searchCtrl,
              style: const TextStyle(color: DesignTokens.textWhite),
              decoration: DesignTokens.inputDecoration(
                hintText: 'Search following...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: DesignTokens.inputFieldPlaceholder,
                  size: 20,
                ),
              ),
              onChanged: (value) =>
                  ref.read(followingNotifierProvider.notifier).load(search: value),
            ),
          ),
          Expanded(
            child: state.when(
              initial: _loadingBody,
              loadInProgress: _loadingBody,
              loadFailure: (failure) => Center(
                child: Text(
                  'Failed to load following.',
                  style: DesignTokens.smallRegular,
                ),
              ),
              loadSuccess: (users) {
                if (users.isEmpty) {
                  return const SmEmptyState(
                    message: 'You are not following anyone yet.',
                    icon: Icons.group_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.s16,
                    0,
                    DesignTokens.s16,
                    DesignTokens.s16,
                  ),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: DesignTokens.s16),
                  itemBuilder: (_, i) => _FollowingCard(user: users[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingBody() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _FollowingCard extends ConsumerWidget {
  const _FollowingCard({required this.user});
  final FollowingUser user;

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + name/handle + button ─────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: DesignTokens.bgAppBodyLight,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(user.avatarUrl)
                    : null,
                child: user.avatarUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: DesignTokens.iconLight,
                        size: 26,
                      )
                    : null,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.oneLinerSemibold,
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      '@${user.handle}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              _FollowToggleButton(
                isFollowing: user.isFollowing,
                onTap: () => ref
                    .read(followingNotifierProvider.notifier)
                    .unfollow(user.id),
              ),
            ],
          ),

          // ── Category ──────────────────────────────────────────────────
          if (user.category != null) ...[
            const SizedBox(height: DesignTokens.s12),
            Text(
              user.category!,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
                fontSize: 12,
              ),
            ),
          ],

          // ── Bio / description ─────────────────────────────────────────
          if (user.bio != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              user.bio!,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight),
            ),
          ],

          // ── Stats ─────────────────────────────────────────────────────
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: DesignTokens.textMuted,
              ),
              const SizedBox(width: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_fmt(user.followerCount)} ',
                      style: DesignTokens.smallRegular.copyWith(
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    TextSpan(
                      text: 'Followers',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Follow / Following toggle button ─────────────────────────────────────────

class _FollowToggleButton extends StatelessWidget {
  const _FollowToggleButton({
    required this.isFollowing,
    required this.onTap,
  });
  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isFollowing
          ? DesignTokens.primaryGreen
          : DesignTokens.buttonGrayFill,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s8,
          ),
          child: Text(
            isFollowing ? 'Following' : 'Follow',
            style: DesignTokens.smallRegular.copyWith(
              fontWeight: FontWeight.w600,
              color: isFollowing
                  ? DesignTokens.buttonPrimaryText
                  : DesignTokens.buttonGrayText,
            ),
          ),
        ),
      ),
    );
  }
}
