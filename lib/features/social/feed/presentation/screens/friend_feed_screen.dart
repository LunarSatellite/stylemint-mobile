import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_posts_sliver.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/widgets/stories_tray.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The friend feed on its own: stories along the top, then posts, Instagram
/// style. The Community home shows the same feed inline (see
/// [FeedPostsSliver]).
class FriendFeedScreen extends ConsumerWidget {
  const FriendFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Friend Feed', style: DesignTokens.titleLarge),
        backgroundColor: DesignTokens.bgAppFoundation,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            key: const Key('friend-feed-create-post'),
            tooltip: 'Create Post',
            icon: const Icon(
              Icons.add_box_outlined,
              color: DesignTokens.textWhite,
            ),
            // Uses the registered /feed/create route so the composer is
            // deep-linkable and keeps the router's auth guard.
            onPressed: () => context.push(RouteNames.feedCreatePost),
          ),
          IconButton(
            key: const Key('friend-feed-stories'),
            tooltip: 'Stories',
            icon: const Icon(
              Icons.auto_stories_outlined,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => context.push(RouteNames.stories),
          ),
        ],
      ),
      body: FeedPagingListener(
        child: RefreshIndicator(
          color: DesignTokens.primaryGreen,
          backgroundColor: DesignTokens.bgAppBody,
          onRefresh: () => refreshFeedAndStories(ref),
          child: const CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: StoriesTray()),
              SliverToBoxAdapter(
                child: Divider(
                  height: DesignTokens.s16,
                  thickness: 0.5,
                  color: DesignTokens.borderDefault,
                ),
              ),
              FeedPostsSliver(),
              SliverToBoxAdapter(child: SizedBox(height: DesignTokens.s48)),
            ],
          ),
        ),
      ),
    );
  }
}
