import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_formatters.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/post_action_bar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/post_video_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One post in the friend feed, laid out the way Instagram lays out a post:
/// header, full-bleed media (swipeable when there are several photos), action
/// row, "N likes", caption, "View all N comments", and a "Shop" row for any
/// tagged products.
///
/// Double-tapping the media likes the post with a heart pop. Like Instagram it
/// only ever likes — double-tapping a post you already like does nothing more
/// than replay the heart.
class FeedPostCard extends StatefulWidget {
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
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  int _page = 0;
  bool _expanded = false;

  FeedPost get _post => widget.post;

  void _likeFromDoubleTap() {
    if (!_post.isLiked) widget.onLikeToggle();
  }

  Future<void> _openMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLarge),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            ListTile(
              leading: const Icon(
                Icons.send_outlined,
                color: DesignTokens.iconWhite,
              ),
              title: const Text('Share', style: DesignTokens.mediumSemibold),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onShare();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.mode_comment_outlined,
                color: DesignTokens.iconWhite,
              ),
              title: const Text(
                'View comments',
                style: DesignTokens.mediumSemibold,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onComment();
              },
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _post.images;
    final hasMedia = images.isNotEmpty;
    final hasText = _post.content.trim().isNotEmpty;

    return Padding(
      key: Key('feed-post-${_post.id}'),
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostHeader(post: _post, onMore: _openMenu),
          if (hasMedia)
            _DoubleTapHeart(
              onDoubleTap: _likeFromDoubleTap,
              child: _PostMedia(
                postId: _post.id,
                images: images,
                page: _page,
                onPageChanged: (page) => setState(() => _page = page),
              ),
            )
          else if (hasText)
            // A text-only post reads like a Facebook status: the words are the
            // media, so they take the media's place (and its double-tap).
            _DoubleTapHeart(
              onDoubleTap: _likeFromDoubleTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s4,
                  DesignTokens.s16,
                  DesignTokens.s4,
                ),
                child: _ExpandableText(
                  span: TextSpan(
                    text: _post.content,
                    style: DesignTokens.bodyText.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  maxLines: 6,
                  expanded: _expanded,
                  onExpand: () => setState(() => _expanded = true),
                ),
              ),
            ),
          if (_post.taggedProducts.isNotEmpty)
            _ShopRow(
              products: _post.taggedProducts,
              onTap: widget.onTaggedProductTap,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s4),
            child: PostActionBar(
              isLiked: _post.isLiked,
              onLike: widget.onLikeToggle,
              onComment: widget.onComment,
              onShare: widget.onShare,
              indicator: images.length > 1
                  ? _CarouselDots(count: images.length, page: _page)
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LikesLine(likeCount: _post.likeCount),
                if (hasMedia && hasText) ...[
                  const SizedBox(height: DesignTokens.s4),
                  _ExpandableText(
                    span: TextSpan(
                      children: [
                        TextSpan(
                          text: _post.userName,
                          style: DesignTokens.mediumSemibold,
                        ),
                        const TextSpan(text: '  '),
                        TextSpan(
                          text: _post.content,
                          style: DesignTokens.mediumRegular.copyWith(
                            color: DesignTokens.textLight,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    expanded: _expanded,
                    onExpand: () => setState(() => _expanded = true),
                  ),
                ],
                const SizedBox(height: DesignTokens.s4),
                _CommentsLink(
                  commentCount: _post.commentCount,
                  onTap: widget.onComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.onMore});

  final FeedPost post;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s12,
        DesignTokens.s8,
        DesignTokens.s4,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          FeedAvatar(url: post.userAvatarUrl),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    post.userName,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '  •  ${feedTimeAgo(post.createdAt)}',
                  style: DesignTokens.smallRegular,
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('feed-post-more-${post.id}'),
            tooltip: 'More options',
            onPressed: onMore,
            icon: const Icon(Icons.more_horiz, color: DesignTokens.iconWhite),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed 4:5 media. One photo is shown as-is; several become a swipeable
/// carousel with a "2/3" counter, and the dots live in the action row.
class _PostMedia extends StatelessWidget {
  const _PostMedia({
    required this.postId,
    required this.images,
    required this.page,
    required this.onPageChanged,
  });

  final String postId;
  final List<String> images;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: images.length == 1
          ? _PostImage(url: images.first)
          : Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  key: Key('feed-post-carousel-$postId'),
                  itemCount: images.length,
                  onPageChanged: onPageChanged,
                  itemBuilder: (_, index) => _PostImage(url: images[index]),
                ),
                Positioned(
                  top: DesignTokens.s12,
                  right: DesignTokens.s12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s8,
                      vertical: DesignTokens.s4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.baseBlack.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.chipRadius,
                      ),
                    ),
                    child: Text(
                      '${page + 1}/${images.length}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url});

  final String url;

  static const _placeholder = ColoredBox(color: DesignTokens.bgAppBody);

  @override
  Widget build(BuildContext context) {
    // Posts list their media as bare URLs; a video upload is stored as
    // .mp4/.mov, so the extension says which tile to draw.
    if (isVideoMediaUrl(url)) {
      return PostVideoView.network(url, key: const Key('feed-post-video'));
    }
    if (url.isEmpty) {
      return const ColoredBox(
        color: DesignTokens.bgAppBody,
        child: Center(
          child: Icon(Icons.image_outlined, color: DesignTokens.iconLight),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, _) => _placeholder,
      errorWidget: (_, _, _) => const ColoredBox(
        color: DesignTokens.bgAppBody,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: DesignTokens.iconLight,
          ),
        ),
      ),
    );
  }
}

/// Wraps post media so a double-tap likes it and pops a big heart over it.
class _DoubleTapHeart extends StatefulWidget {
  const _DoubleTapHeart({required this.onDoubleTap, required this.child});

  final VoidCallback onDoubleTap;
  final Widget child;

  @override
  State<_DoubleTapHeart> createState() => _DoubleTapHeartState();
}

class _DoubleTapHeartState extends State<_DoubleTapHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  // Pop in past full size, settle, hold, then shrink away while fading.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 0,
        end: 1.2,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.2,
        end: 1,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 40),
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0.6), weight: 20),
  ]).animate(_controller);

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween<double>(1), weight: 75),
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 25),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    widget.onDoubleTap();
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                if (!_controller.isAnimating) return const SizedBox.shrink();
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: const Icon(
                      Icons.favorite,
                      key: Key('feed-post-heart-pop'),
                      size: 96,
                      color: DesignTokens.textWhite,
                      shadows: [
                        Shadow(color: Color(0x66000000), blurRadius: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.page});

  final int count;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('feed-post-dots'),
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final active = index == page;
        return AnimatedContainer(
          duration: DesignTokens.motionFast,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: active ? 7 : 6,
          height: active ? 7 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? DesignTokens.primaryGreen
                : DesignTokens.textMuted.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }
}

class _LikesLine extends StatelessWidget {
  const _LikesLine({required this.likeCount});

  final int likeCount;

  @override
  Widget build(BuildContext context) {
    if (likeCount <= 0) {
      return const Text(
        'Be the first to like this',
        key: Key('feed-post-likes'),
        style: DesignTokens.smallRegular,
      );
    }
    return Text(
      '${feedCount(likeCount)} ${likeCount == 1 ? 'like' : 'likes'}',
      key: const Key('feed-post-likes'),
      style: DesignTokens.mediumSemibold,
    );
  }
}

class _CommentsLink extends StatelessWidget {
  const _CommentsLink({required this.commentCount, required this.onTap});

  final int commentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (commentCount) {
      <= 0 => 'Add a comment…',
      1 => 'View 1 comment',
      _ => 'View all ${feedCount(commentCount)} comments',
    };
    return GestureDetector(
      key: const Key('feed-post-view-comments'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s4),
        child: Text(
          label,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Text clamped to [maxLines] with a "more" link, Instagram-caption style. The
/// link only appears when the text actually overflows.
class _ExpandableText extends StatelessWidget {
  const _ExpandableText({
    required this.span,
    required this.maxLines,
    required this.expanded,
    required this.onExpand,
  });

  final TextSpan span;
  final int maxLines;
  final bool expanded;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    if (expanded) return Text.rich(span);
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: span,
          maxLines: maxLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        if (!overflows) return Text.rich(span);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onExpand,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                span,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'more',
                key: const Key('feed-post-caption-more'),
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tagged products as a compact, swipeable row of "Shop" chips.
class _ShopRow extends StatelessWidget {
  const _ShopRow({required this.products, required this.onTap});

  final List<FeedTaggedProduct> products;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        key: const Key('feed-post-shop-row'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s12,
          DesignTokens.s8,
          DesignTokens.s12,
          0,
        ),
        itemCount: products.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s8),
        itemBuilder: (_, index) {
          if (index == 0) {
            return const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.primaryGreen,
                ),
                SizedBox(width: DesignTokens.s4),
                Text(
                  'Shop',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ],
            );
          }
          final product = products[index - 1];
          return _ShopChip(product: product, onTap: onTap);
        },
      ),
    );
  }
}

class _ShopChip extends StatelessWidget {
  const _ShopChip({required this.product, required this.onTap});

  final FeedTaggedProduct product;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder(
      side: BorderSide(color: DesignTokens.chipsDefaultBorder),
    );
    return Material(
      color: DesignTokens.bgAppBody,
      shape: shape,
      child: InkWell(
        key: Key('feed-post-product-${product.productId}'),
        customBorder: shape,
        onTap: () => onTap(product.productId),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s4,
            DesignTokens.s4,
            DesignTokens.s12,
            DesignTokens.s4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Video-first: the tagged product's typographic ground, never its
              // photograph (owner directive, 2026-09-16).
              ClipOval(
                child: SizedBox.square(
                  dimension: DesignTokens.avatarSmall,
                  child: MallTypeGround(seed: product.productId),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product.productName.isNotEmpty)
                      Text(
                        product.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    MoneyText(
                      product.price,
                      maxLines: 1,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.chipsDefaultText,
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

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.sectionOnBase,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
