import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/domain/entities/group.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/presentation/notifiers/groups_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/groups/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _postController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(groupsNotifierProvider.notifier)
          .loadGroup(widget.groupId);
    });
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(groupsNotifierProvider);
    final detailState = viewState.detailState;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: detailState.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (group, posts, _, __) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: DesignTokens.bgAppFoundation,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        group.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: DesignTokens.bgAppBodyLight,
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.4, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: DesignTokens.s16,
                        left: DesignTokens.s16,
                        right: DesignTokens.s16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              group.name,
                              style: DesignTokens.titleLarge,
                            ),
                            const SizedBox(height: DesignTokens.s4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: DesignTokens.iconSmall,
                                  color: DesignTokens.textLight,
                                ),
                                const SizedBox(width: DesignTokens.s4),
                                Text(
                                  '${group.memberCount} members',
                                  style: DesignTokens.smallRegular.copyWith(
                                    color: DesignTokens.textLight,
                                  ),
                                ),
                                if (group.isPrivate)
                                  const Padding(
                                    padding: EdgeInsets.only(
                                      left: DesignTokens.s8,
                                    ),
                                    child: Icon(
                                      Icons.lock_outline,
                                      size: DesignTokens.iconSmall,
                                      color: DesignTokens.textLight,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: DesignTokens.s16),
                    child: ElevatedButton(
                      onPressed: () {
                        if (group.isJoined) {
                          ref
                              .read(groupsNotifierProvider.notifier)
                              .leave(widget.groupId);
                        } else {
                          ref
                              .read(groupsNotifierProvider.notifier)
                              .join(widget.groupId);
                        }
                      },
                      style: group.isJoined
                          ? DesignTokens.outlinedButtonStyle()
                          : DesignTokens.primaryButtonStyle(),
                      child: Text(group.isJoined ? 'Leave' : 'Join'),
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.description, style: DesignTokens.bodyText),
                      const SizedBox(height: DesignTokens.s4),
                      Chip(
                        label: Text(
                          group.category,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        backgroundColor: DesignTokens.primaryGreenLight,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (group.topProducts.isNotEmpty) ...[
                        const SizedBox(height: DesignTokens.s20),
                        Text(
                          'Top Products',
                          style: DesignTokens.sectionInnerTitle,
                        ),
                        const SizedBox(height: DesignTokens.s12),
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: group.topProducts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: DesignTokens.s12),
                            itemBuilder: (_, index) {
                              final product = group.topProducts[index];
                              return Container(
                                width: 140,
                                decoration: DesignTokens.cardDecoration(),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(
                                          DesignTokens.cardRadius,
                                        ),
                                      ),
                                      child: Image.network(
                                        product.imageUrl,
                                        height: 100,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          height: 100,
                                          color: DesignTokens.bgAppBodyLight,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(
                                        DesignTokens.s8,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.productName,
                                            style:
                                                DesignTokens
                                                    .smallRegular
                                                    .copyWith(
                                                      color:
                                                          DesignTokens
                                                              .textWhite,
                                                    ),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(
                                            height: DesignTokens.s4,
                                          ),
                                          Text(
                                            formatMoney(product.price),
                                            style:
                                                DesignTokens
                                                    .smallRegular
                                                    .copyWith(
                                                      color:
                                                          DesignTokens
                                                              .primaryGreen,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: DesignTokens.s24),
                      Text(
                        'Feed',
                        style: DesignTokens.sectionInnerTitle,
                      ),
                      const SizedBox(height: DesignTokens.s12),
                    ],
                  ),
                ),
              ),
              if (posts.isEmpty)
                SliverToBoxAdapter(
                  child: const SmEmptyState(
                    message: 'No posts yet. Start the conversation!',
                    icon: Icons.forum_outlined,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, index) => _buildPostCard(posts[index]),
                    childCount: posts.length,
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
        loadFailure:
            (failure) => SmErrorView(
              message: 'Failed to load group.',
              onRetry: () =>
                  ref
                      .read(groupsNotifierProvider.notifier)
                      .loadGroup(widget.groupId),
            ),
      ),
      floatingActionButton: detailState.maybeWhen(
        loadSuccess: (group, _, __, ___) {
          if (!group.isJoined) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: DesignTokens.primaryGreen,
            onPressed: () => _showCreatePostSheet(group.name),
            child: const Icon(Icons.edit, color: DesignTokens.textWhite),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildPostCard(GroupPost post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s12,
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(post.userAvatarUrl),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        style: DesignTokens.mediumSemibold,
                      ),
                      Text(
                        _formatDate(post.createdAt),
                        style: DesignTokens.smallRegular,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(post.content, style: DesignTokens.bodyText),
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.images.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: DesignTokens.s8),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s8),
                    child: Image.network(
                      post.images[index],
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140,
                        color: DesignTokens.bgAppBodyLight,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: DesignTokens.s4),
                Text(
                  '${post.likeCount}',
                  style: DesignTokens.smallRegular,
                ),
                const SizedBox(width: DesignTokens.s16),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: DesignTokens.s4),
                Text(
                  '${post.commentCount}',
                  style: DesignTokens.smallRegular,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostSheet(String groupName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.cardRadius),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            MediaQuery.of(context).viewInsets.bottom + DesignTokens.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Post in $groupName',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s16),
              TextField(
                controller: _postController,
                maxLines: 3,
                style: DesignTokens.bodyText,
                decoration: DesignTokens.inputDecoration(
                  hintText: "What's on your mind?",
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final content = _postController.text.trim();
                    if (content.isEmpty) return;
                    ref.read(groupsNotifierProvider.notifier).createPost(
                      groupId: widget.groupId,
                      content: content,
                    );
                    _postController.clear();
                    Navigator.of(context).pop();
                  },
                  style: DesignTokens.primaryButtonStyle(),
                  child: const Text('Post'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}
