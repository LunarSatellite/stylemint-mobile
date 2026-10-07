import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/providers/feed_viewer_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_posts_sliver.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The social home, laid out the way Instagram and Facebook lay theirs out:
/// stories along the top, a "What's new?" composer, a row of shortcuts to
/// every community surface, then the friend feed itself, inline and endless.
class CommunityHubScreen extends ConsumerWidget {
  const CommunityHubScreen({super.key});

  /// Every community surface stays one tap away. The friend feed and stories
  /// are not in this list — they are the page itself.
  static const _shortcuts = <_CommunityShortcut>[
    _CommunityShortcut(
      id: 'circles',
      label: 'Circles',
      icon: Icons.groups_outlined,
      route: RouteNames.groups,
    ),
    _CommunityShortcut(
      id: 'live',
      label: 'Live Shopping',
      icon: Icons.live_tv_outlined,
      route: RouteNames.liveSessions,
    ),
    _CommunityShortcut(
      id: 'drops',
      label: 'Drop Parties',
      icon: Icons.celebration_outlined,
      route: RouteNames.dropPartiesList,
    ),
    _CommunityShortcut(
      id: 'co-watch',
      label: 'Co-Watch',
      icon: Icons.groups_2_outlined,
      route: RouteNames.coWatch,
    ),
    _CommunityShortcut(
      id: 'group-carts',
      label: 'Group Carts',
      icon: Icons.shopping_cart_outlined,
      route: RouteNames.groupCartsList,
    ),
    _CommunityShortcut(
      id: 'recommendations',
      label: 'Recommendations',
      icon: Icons.recommend_outlined,
      route: RouteNames.recommendations,
    ),
    _CommunityShortcut(
      id: 'friends',
      label: 'Friends',
      icon: Icons.people_outline,
      route: RouteNames.friends,
    ),
    _CommunityShortcut(
      id: 'invite',
      label: 'Invite Friends',
      icon: Icons.group_add_outlined,
      route: RouteNames.referrals,
    ),
    _CommunityShortcut(
      id: 'tips',
      label: 'Tips',
      icon: Icons.volunteer_activism_outlined,
      route: RouteNames.tips,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          'Community',
          style: DesignTokens.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            key: const Key('community-hub-create-post'),
            tooltip: 'Create post',
            icon: const Icon(
              Icons.add_box_outlined,
              color: DesignTokens.iconWhite,
            ),
            onPressed: () => context.push(RouteNames.feedCreatePost),
          ),
          IconButton(
            key: const Key('community-hub-friends'),
            tooltip: 'Friends',
            icon: const Icon(
              Icons.people_alt_outlined,
              color: DesignTokens.iconWhite,
            ),
            onPressed: () => context.push(RouteNames.friends),
          ),
          const SizedBox(width: DesignTokens.s4),
        ],
      ),
      body: SafeArea(
        key: const Key('community-hub-safe-area'),
        top: false,
        child: FeedPagingListener(
          child: RefreshIndicator(
            color: DesignTokens.primaryGreen,
            backgroundColor: DesignTokens.bgAppBody,
            onRefresh: () => refreshFeedAndStories(ref),
            child: CustomScrollView(
              key: const Key('community-hub-scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(
                  child: StoriesTray(style: StoriesTrayStyle.surface),
                ),
                const SliverToBoxAdapter(child: _ThinDivider()),
                const SliverToBoxAdapter(child: _ComposerRow()),
                const SliverToBoxAdapter(child: _ThinDivider()),
                SliverToBoxAdapter(
                  child: _ShortcutRow(shortcuts: _shortcuts),
                ),
                // A Facebook-style band separates the "chrome" from the feed.
                const SliverToBoxAdapter(
                  child: ColoredBox(
                    color: DesignTokens.bgAppBody,
                    child: SizedBox(
                      height: DesignTokens.s8,
                      width: double.infinity,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.s4),
                ),
                FeedPostsSliver(
                  emptyBuilder: (_) => const _NewUserEmptyState(),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.s32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: DesignTokens.borderDefault,
    );
  }
}

/// Facebook's "What's on your mind?" row: your photo and a rounded prompt that
/// opens the post composer, with a photo shortcut on the right.
class _ComposerRow extends ConsumerWidget {
  const _ComposerRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(feedViewerProvider);
    final firstName = viewer?.firstName ?? '';
    final prompt = firstName.isEmpty
        ? "What's new?"
        : "What's new, $firstName?";

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s8,
        DesignTokens.s12,
      ),
      child: Row(
        children: [
          FeedAvatar(url: viewer?.avatarUrl, size: DesignTokens.avatarMedium),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Material(
              color: DesignTokens.bgAppBody,
              shape: const StadiumBorder(
                side: BorderSide(color: DesignTokens.borderDefault),
              ),
              child: InkWell(
                key: const Key('community-hub-composer'),
                customBorder: const StadiumBorder(),
                onTap: () => context.push(RouteNames.feedCreatePost),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s12,
                  ),
                  child: Text(
                    prompt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textMuted,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            key: const Key('community-hub-composer-photo'),
            tooltip: 'Post a photo',
            onPressed: () => context.push(RouteNames.feedCreatePost),
            icon: const Icon(
              Icons.photo_library_outlined,
              color: DesignTokens.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// A swipeable row of rounded shortcut chips, one per community surface.
class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.shortcuts});

  final List<_CommunityShortcut> shortcuts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        key: const Key('community-hub-shortcuts'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        itemCount: shortcuts.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s8),
        itemBuilder: (context, index) =>
            _ShortcutChip(shortcut: shortcuts[index]),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({required this.shortcut});

  final _CommunityShortcut shortcut;

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder(
      side: BorderSide(color: DesignTokens.borderDefault),
    );
    return Material(
      color: DesignTokens.bgAppBody,
      shape: shape,
      child: InkWell(
        key: Key('community-shortcut-${shortcut.id}'),
        customBorder: shape,
        onTap: () => context.push(shortcut.route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                shortcut.icon,
                size: 18,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s6),
              Text(shortcut.label, style: DesignTokens.mediumSemibold),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a brand-new member sees instead of an empty list: what the feed is for,
/// and the two things that fill it.
class _NewUserEmptyState extends StatelessWidget {
  const _NewUserEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('community-hub-empty'),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s24,
        vertical: DesignTokens.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Three overlapping faces: the people this feed will be made of.
          SizedBox(
            width: 132,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(left: 0, child: _Face(tone: 0)),
                const Positioned(right: 0, child: _Face(tone: 2)),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DesignTokens.primaryGreenLight,
                    border: Border.all(
                      color: DesignTokens.bgAppFoundation,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: DesignTokens.primaryGreen,
                    size: DesignTokens.iconLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          const Text(
            'Your feed is waiting',
            textAlign: TextAlign.center,
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Follow friends and creators to see their posts',
            textAlign: TextAlign.center,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          ElevatedButton.icon(
            key: const Key('community-hub-empty-find-friends'),
            style: DesignTokens.primaryButtonStyle(width: 240, height: 48),
            onPressed: () => context.push(RouteNames.friends),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
            label: const Text('Find friends'),
          ),
          const SizedBox(height: DesignTokens.s12),
          OutlinedButton.icon(
            key: const Key('community-hub-empty-create-post'),
            style: DesignTokens.outlinedButtonStyle().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size(240, 48)),
            ),
            onPressed: () => context.push(RouteNames.feedCreatePost),
            icon: const Icon(Icons.add_a_photo_outlined, size: 20),
            label: const Text('Create your first post'),
          ),
        ],
      ),
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({required this.tone});

  final int tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone == 0
            ? DesignTokens.bgAppBodyLight
            : DesignTokens.infoFillDark,
        border: Border.all(color: DesignTokens.bgAppFoundation, width: 3),
      ),
      child: const Icon(
        Icons.person,
        color: DesignTokens.textMuted,
        size: 28,
      ),
    );
  }
}

class _CommunityShortcut {
  const _CommunityShortcut({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
}
