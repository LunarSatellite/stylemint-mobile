import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_post_card.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// The friend feed as slivers, shared by the Friend Feed screen and the
// Community home so both scroll, page and refresh the same way.

/// Pull-to-refresh for a feed surface: the posts and the stories tray above
/// them reload together.
Future<void> refreshFeedAndStories(WidgetRef ref) async {
  await Future.wait<void>([
    ref.read(feedNotifierProvider.notifier).refresh(),
    ref.read(storiesNotifierProvider.notifier).loadStoryGroups(),
  ]);
}

/// Asks the feed for its next page as the outer list nears its end. Wrap the
/// feed's [CustomScrollView] in this; horizontal rows and carousels inside it
/// are ignored.
class FeedPagingListener extends ConsumerWidget {
  const FeedPagingListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (notification.depth == 0 &&
            metrics.axis == Axis.vertical &&
            metrics.extentAfter < 600) {
          unawaited(ref.read(feedNotifierProvider.notifier).loadMore());
        }
        return false;
      },
      child: child,
    );
  }
}

/// The posts themselves, as one sliver: a loader while the first page loads,
/// [emptyBuilder] when there is nothing to show, the error view with a retry,
/// or the infinite list of [FeedPostCard]s, one card per post.
class FeedPostsSliver extends ConsumerWidget {
  const FeedPostsSliver({this.emptyBuilder, super.key});

  /// What to show when the feed has no posts. Defaults to a plain empty state.
  final WidgetBuilder? emptyBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedNotifierProvider);
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (posts, hasMore, _) {
        if (posts.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child:
                emptyBuilder?.call(context) ??
                const SmEmptyState(
                  message:
                      'No posts yet. Follow friends to see their posts here.',
                  icon: Icons.article_outlined,
                ),
          );
        }
        // Each post is its own card with its own margins; this only gives the
        // first one room to breathe below whatever sits above the feed.
        return SliverPadding(
          padding: const EdgeInsets.only(top: DesignTokens.s8),
          sliver: SliverList.builder(
            itemCount: posts.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= posts.length) return const _NextPageLoader();
              return FeedPostTile(
                key: ValueKey<String>(posts[index].id),
                post: posts[index],
                index: index,
              );
            },
          ),
        );
      },
      loadFailure: (_) => SliverFillRemaining(
        hasScrollBody: false,
        child: SmErrorView(
          message: 'Failed to load feed.',
          onRetry: () => ref.read(feedNotifierProvider.notifier).loadFeed(),
        ),
      ),
    );
  }

  Widget _loader() => const SliverFillRemaining(
    hasScrollBody: false,
    child: SmPageLoader(),
  );
}

/// A [FeedPostCard] wired to the feed: likes go through the notifier's
/// optimistic toggle, comments open the comments sheet, tagged products open
/// their product page.
class FeedPostTile extends ConsumerWidget {
  const FeedPostTile({required this.post, required this.index, super.key});

  final FeedPost post;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeedPostCard(
      post: post,
      index: index,
      onLikeToggle: () => unawaited(_toggleLike(context, ref)),
      onComment: () => unawaited(
        showFeedCommentsSheet(context, postId: post.id, postIndex: index),
      ),
      onShare: () => unawaited(
        ref.read(feedNotifierProvider.notifier).sharePost(post.id, index),
      ),
      onTaggedProductTap: (productId) => context.push(
        RouteNames.productDetail.replaceFirst(':productId', productId),
      ),
    );
  }

  /// The heart flips at once; if the server refuses, the notifier flips it
  /// back and this says so, rather than leaving a like that silently never
  /// existed.
  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(feedNotifierProvider.notifier);
    final wasLiked = post.isLiked;
    final result = wasLiked
        ? await notifier.unlikePost(post.id)
        : await notifier.likePost(post.id);
    if (result.isLeft() && context.mounted) {
      SmSnackbar.error(
        context,
        wasLiked
            ? 'Could not unlike the post. Please try again.'
            : 'Could not like the post. Please try again.',
      );
    }
  }
}

/// The spinner under the last post. Building it means the end of the list is
/// close, so it also asks for the next page — that covers a first page too
/// short to scroll.
class _NextPageLoader extends ConsumerStatefulWidget {
  const _NextPageLoader();

  @override
  ConsumerState<_NextPageLoader> createState() => _NextPageLoaderState();
}

class _NextPageLoaderState extends ConsumerState<_NextPageLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(feedNotifierProvider.notifier).loadMore());
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
      child: SmPageLoader(size: 40),
    );
  }
}
