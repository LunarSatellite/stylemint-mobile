import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/screens/story_viewer_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/story_circle_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class StoriesScreen extends ConsumerWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storiesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Stories')),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (groups) {
          if (groups.isEmpty) {
            return SmEmptyState(
              icon: Icons.auto_stories_outlined,
              message: 'No active stories yet.',
              actionLabel: 'Add Story',
              onAction: () => _showCreationComingSoon(context),
            );
          }
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s8,
                ),
                itemCount: groups.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: DesignTokens.s12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StoryCircleAvatar(
                      userName: 'My Story',
                      avatarUrl: '',
                      hasUnwatched: false,
                      isMyStory: true,
                      onTap: () => _showCreationComingSoon(context),
                    );
                  }
                  final group = groups[index - 1];
                  return StoryCircleAvatar(
                    userName: group.userName,
                    avatarUrl: group.userAvatarUrl,
                    hasUnwatched: group.hasUnwatched,
                    isMyStory: false,
                    onTap: () {
                      unawaited(
                        Navigator.of(context).push<void>(
                          PageRouteBuilder<void>(
                            opaque: false,
                            barrierColor: DesignTokens.baseBlack,
                            pageBuilder: (_, _, _) => StoryViewerScreen(
                              userId: group.userId,
                              stories: group.stories,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load stories.',
          onRetry: () =>
              ref.read(storiesNotifierProvider.notifier).loadStoryGroups(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(
      color: DesignTokens.primaryGreen,
      strokeWidth: 2,
    ),
  );

  void _showCreationComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Posting a story is coming soon.')),
    );
  }
}
