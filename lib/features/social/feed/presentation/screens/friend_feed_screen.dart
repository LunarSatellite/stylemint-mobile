import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/screens/create_post_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_post_card.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FriendFeedScreen extends ConsumerStatefulWidget {
  const FriendFeedScreen({super.key});

  @override
  ConsumerState<FriendFeedScreen> createState() => _FriendFeedScreenState();
}

class _FriendFeedScreenState extends ConsumerState<FriendFeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        title: const Text('Friend Feed', style: DesignTokens.titleLarge),
        backgroundColor: DesignTokens.bgAppFoundation,
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (posts, hasMore, _) {
          if (posts.isEmpty) {
            return const SmEmptyState(
              message: 'No posts yet. Follow friends to see their posts here.',
              icon: Icons.article_outlined,
            );
          }
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () => ref.read(feedNotifierProvider.notifier).loadFeed(),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: posts.length + (hasMore ? 1 : 0),
              padding: const EdgeInsets.only(
                top: DesignTokens.s8,
                bottom: DesignTokens.s48,
              ),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return _loader();
                }
                return FeedPostCard(
                  post: posts[index],
                  index: index,
                  onLikeToggle: () {
                    final notifier = ref.read(feedNotifierProvider.notifier);
                    if (posts[index].isLiked) {
                      notifier.unlikePost(posts[index].id, index);
                    } else {
                      notifier.likePost(posts[index].id, index);
                    }
                  },
                  onComment: () {
                    // navigate to comments
                  },
                  onShare: () {
                    ref.read(feedNotifierProvider.notifier).sharePost(
                      posts[index].id,
                      index,
                    );
                  },
                  onTaggedProductTap: (productId) {
                    Navigator.of(context).pushNamed(
                      RouteNames.productDetail.replaceFirst(':productId', productId),
                    );
                  },
                );
              },
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load feed.',
          onRetry: () => ref.read(feedNotifierProvider.notifier).loadFeed(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryGreen,
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add, color: DesignTokens.buttonPrimaryText),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
