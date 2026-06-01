import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/post_action_bar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    required this.post,
    required this.index,
    required this.onLikeToggle,
    required this.onComment,
    required this.onShare,
    required this.onTaggedProductTap,
    super.key,
  });

  final FeedPost post;
  final int index;
  final VoidCallback onLikeToggle;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final void Function(String productId) onTaggedProductTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s6,
      ),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserHeader(post: post),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                0,
                DesignTokens.s16,
                DesignTokens.s12,
              ),
              child: Text(
                post.content,
                style: DesignTokens.mediumRegular,
              ),
            ),
          if (post.images.isNotEmpty)
            _ImageCarousel(images: post.images),
          if (post.taggedProducts.isNotEmpty)
            _TaggedProductsRow(
              products: post.taggedProducts,
              onTap: onTaggedProductTap,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            child: PostActionBar(
              isLiked: post.isLiked,
              likeCount: post.likeCount,
              commentCount: post.commentCount,
              shareCount: post.shareCount,
              onLike: onLikeToggle,
              onComment: onComment,
              onShare: onShare,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Row(
        children: [
          CircleAvatar(
            radius: DesignTokens.avatarSmall / 2,
            backgroundColor: DesignTokens.bgAppBodyLight,
            backgroundImage:
                post.userAvatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(post.userAvatarUrl)
                    : null,
            child:
                post.userAvatarUrl.isEmpty
                    ? const Icon(Icons.person, color: DesignTokens.iconLight, size: DesignTokens.iconSmall)
                    : null,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: DesignTokens.mediumSemibold,
                ),
                Text(
                  _timeAgo(post.createdAt),
                  style: DesignTokens.tiny,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _ImageCarousel extends StatelessWidget {
  const _ImageCarousel({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      height: 280,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (_, index) => CachedNetworkImage(
          imageUrl: images[index],
          fit: BoxFit.cover,
          placeholder: (_, __) => const ColoredBox(
            color: DesignTokens.bgAppBodyLight,
          ),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: DesignTokens.bgAppBodyLight,
            child: Icon(Icons.broken_image, color: DesignTokens.iconLight),
          ),
        ),
      ),
    );
  }
}

class _TaggedProductsRow extends StatelessWidget {
  const _TaggedProductsRow({required this.products, required this.onTap});

  final List<FeedTaggedProduct> products;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        0,
        DesignTokens.s16,
        DesignTokens.s12,
      ),
      child: Wrap(
        spacing: DesignTokens.s8,
        runSpacing: DesignTokens.s8,
        children: products.map((p) => _TaggedProductChip(product: p, onTap: onTap)).toList(),
      ),
    );
  }
}

class _TaggedProductChip extends StatelessWidget {
  const _TaggedProductChip({required this.product, required this.onTap});

  final FeedTaggedProduct product;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(product.productId),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8,
          vertical: DesignTokens.s4,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(color: DesignTokens.chipsDefaultBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s4),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: DesignTokens.bgAppBody,
                  ),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s4),
            MoneyText(
              product.price,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.chipsDefaultText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
