import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/entities/story.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_viewer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_age.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_composer_launcher.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_ring_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The standalone Stories page: the tray on top, then everyone's latest story
/// as a tile. Pull to refresh; "+" adds to your story.
class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storiesNotifierProvider);
    final me = ref.watch(storiesCurrentUserProvider);
    final notifier = ref.read(storiesNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        actions: [
          IconButton(
            key: const Key('stories-add'),
            tooltip: 'Add to your story',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => unawaited(startStoryComposer(context)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: DesignTokens.primaryGreen,
        onRefresh: notifier.loadStoryGroups,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: StoriesTray()),
            ...state.when<List<Widget>>(
              // The tray's placeholders already show it is loading.
              initial: () => const <Widget>[],
              loadInProgress: () => const <Widget>[],
              loadSuccess: (groups) {
                if (groups.isEmpty) {
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: SmEmptyState(
                        icon: Icons.auto_stories_outlined,
                        message: 'No active stories yet.',
                        actionLabel: 'Add Story',
                        onAction: () => unawaited(startStoryComposer(context)),
                      ),
                    ),
                  ];
                }
                final playlist = storyPlaylist(groups, me);
                return [
                  SliverPadding(
                    padding: const EdgeInsets.all(
                      DesignTokens.appHorizontalPadding,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: DesignTokens.s12,
                            crossAxisSpacing: DesignTokens.s12,
                            childAspectRatio: 9 / 14,
                          ),
                      itemCount: playlist.length,
                      itemBuilder: (context, index) {
                        final group = playlist[index];
                        return _StoryPreviewTile(
                          key: ValueKey('stories-tile-${group.userId}'),
                          group: group,
                          isMine: me.owns(group.userId),
                          onTap: () => unawaited(
                            StoryViewerScreen.open(
                              context,
                              groups: playlist,
                              initialGroupIndex: index,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ];
              },
              loadFailure: (_) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SmErrorView(
                    message: 'Failed to load stories.',
                    onRetry: () => unawaited(notifier.loadStoryGroups()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One person's latest story as a tall card: the picture, their avatar in its
/// ring, their name and how long ago.
class _StoryPreviewTile extends StatelessWidget {
  const _StoryPreviewTile({
    required this.group,
    required this.isMine,
    required this.onTap,
    super.key,
  });

  final StoryGroup group;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latest = group.stories.last;
    final name = isMine ? 'Your story' : group.userName;

    return Semantics(
      button: true,
      label: '$name, ${storyAge(latest.postedAt)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: DesignTokens.bgAppBodyLight),
              if (!latest.isVideo && latest.mediaUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: latest.mediaUrl,
                  fit: BoxFit.cover,
                  fadeInDuration: DesignTokens.motionFast,
                  errorWidget: (_, _, _) => const SizedBox.shrink(),
                ),
              if (latest.isVideo)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline,
                    color: DesignTokens.iconWhite,
                    size: DesignTokens.iconXLarge,
                  ),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: DesignTokens.imageScrim),
              ),
              Positioned(
                top: DesignTokens.s8,
                left: DesignTokens.s8,
                child: StoryRingAvatar(
                  avatarUrl: group.userAvatarUrl,
                  name: group.userName,
                  diameter: 40,
                  ring: group.hasUnwatched || isMine
                      ? StoryRing.unwatched
                      : StoryRing.watched,
                  watchedRingColor: DesignTokens.textLight,
                ),
              ),
              Positioned(
                left: DesignTokens.s12,
                right: DesignTokens.s12,
                bottom: DesignTokens.s12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    Text(
                      group.stories.length == 1
                          ? storyAge(latest.postedAt)
                          : '${group.stories.length} stories · '
                                '${storyAge(latest.postedAt)}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
