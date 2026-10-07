import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/feed_post.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_avatar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/feed_formatters.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/post_action_bar.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/widgets/post_video_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One post in the friend feed, as its own raised card so neighbouring posts
/// never run together. Top to bottom: header (ringed avatar, name, age, post
/// kind, ⋯), full-bleed media (swipeable when there are several photos) or,
/// for a text-only post, the words on a brand gradient panel; a likes /
/// comments summary; Like · Comment · Share; caption; "View all N comments";
/// and a "Shop this post" strip for any tagged products.
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

  /// The card's edge: a hairline that keeps it distinct from the darker page
  /// even where the shadow is lost against a dark photo.
  static final ShapeBorder _cardShape = RoundedRectangleBorder(
    borderRadius: const BorderRadius.all(
      Radius.circular(DesignTokens.cardRadius),
    ),
    side: BorderSide(
      color: DesignTokens.borderDefault.withValues(alpha: 0.6),
      width: 0.5,
    ),
  );

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
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s12,
        0,
        DesignTokens.s12,
        DesignTokens.s16,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(DesignTokens.cardRadius),
          ),
          boxShadow: DesignTokens.shadowCard,
        ),
        // The card is the Material the buttons inside ripple on, and it clips
        // full-bleed media to its rounded corners.
        child: Material(
          key: Key('feed-post-card-${_post.id}'),
          color: DesignTokens.surfaceRaised,
          shape: _cardShape,
          clipBehavior: Clip.antiAlias,
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
                // A text-only post reads like a Facebook status: the words are
                // the media, so they take the media's place (and its
                // double-tap) on a panel of their own.
                _DoubleTapHeart(
                  onDoubleTap: _likeFromDoubleTap,
                  child: _TextPanel(
                    child: _ExpandableText(
                      span: TextSpan(
                        text: _post.content,
                        style: _post.content.length <= 120
                            ? DesignTokens.sectionInnerTitle.copyWith(
                                height: 1.4,
                              )
                            : DesignTokens.bodyText.copyWith(
                                color: DesignTokens.textWhite,
                              ),
                      ),
                      maxLines: 6,
                      expanded: _expanded,
                      onExpand: () => setState(() => _expanded = true),
                    ),
                  ),
                ),
              _EngagementSummary(
                likeCount: _post.likeCount,
                commentCount: _post.commentCount,
                onComments: widget.onComment,
              ),
              const Divider(
                height: 1,
                thickness: 0.5,
                indent: DesignTokens.s12,
                endIndent: DesignTokens.s12,
                color: DesignTokens.borderDefault,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s4,
                  vertical: DesignTokens.s4,
                ),
                child: PostActionBar(
                  isLiked: _post.isLiked,
                  onLike: widget.onLikeToggle,
                  onComment: widget.onComment,
                  onShare: widget.onShare,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s12,
                  0,
                  DesignTokens.s12,
                  DesignTokens.s8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasMedia && hasText)
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
                    _CommentsLink(
                      commentCount: _post.commentCount,
                      onTap: widget.onComment,
                    ),
                  ],
                ),
              ),
              if (_post.taggedProducts.isNotEmpty)
                _ShopStrip(
                  products: _post.taggedProducts,
                  onTap: widget.onTaggedProductTap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a post is, shown as a small chip beside its age. A plain text post
/// gets none.
enum _PostKind {
  photo('Photo', Icons.photo_outlined),
  video('Video', Icons.videocam_outlined),
  shopTheLook('Shop the look', Icons.shopping_bag_outlined);

  const _PostKind(this.label, this.icon);

  final String label;
  final IconData icon;

  static _PostKind? of(FeedPost post) {
    if (post.taggedProducts.isNotEmpty) return _PostKind.shopTheLook;
    if (post.images.any(isVideoMediaUrl)) return _PostKind.video;
    if (post.images.isNotEmpty) return _PostKind.photo;
    return null;
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post, required this.onMore});

  final FeedPost post;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final kind = _PostKind.of(post);
    final isNew =
        DateTime.now().difference(post.createdAt) < const Duration(hours: 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s12,
        DesignTokens.s12,
        DesignTokens.s4,
        DesignTokens.s12,
      ),
      child: Row(
        children: [
          _RingedAvatar(url: post.userAvatarUrl),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.userName,
                        style: DesignTokens.mediumSemibold.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isNew) ...[
                      const SizedBox(width: DesignTokens.s6),
                      const _NewBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: [
                    Text(
                      feedTimeAgo(post.createdAt),
                      key: const Key('feed-post-time'),
                      style: DesignTokens.smallRegular,
                    ),
                    if (kind != null) ...[
                      const _DotSeparator(),
                      Flexible(child: _KindChip(kind: kind)),
                    ],
                  ],
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

/// The author's photo inside a thin brand-gradient ring, story-bubble style.
class _RingedAvatar extends StatelessWidget {
  const _RingedAvatar({required this.url});

  final String url;

  static const _ring = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [DesignTokens.primaryGreen, DesignTokens.secondaryYellow],
  );

  @override
  Widget build(BuildContext context) {
    // 2px ring + 2px gap around the 32px avatar = avatarMedium.
    return Container(
      width: DesignTokens.avatarMedium,
      height: DesignTokens.avatarMedium,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: _ring),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: DesignTokens.surfaceRaised,
        ),
        child: FeedAvatar(url: url),
      ),
    );
  }
}

/// A slim mint pill on posts less than an hour old.
class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('feed-post-new'),
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s6),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(
        'New',
        style: DesignTokens.tiny.copyWith(
          color: DesignTokens.buttonPrimaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s6),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.dotSeparator,
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.kind});

  final _PostKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('feed-post-kind'),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s6,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kind.icon, size: 11, color: DesignTokens.primaryGreen),
          const SizedBox(width: DesignTokens.s4),
          Flexible(
            child: Text(
              kind.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-bleed 4:5 media. One photo is shown as-is; several become a swipeable
/// carousel with a "2/3" counter top-right and dots along the bottom.
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
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: DesignTokens.s12,
                  child: IgnorePointer(
                    child: Center(
                      child: _CarouselDots(count: images.length, page: page),
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

/// The stage for a text-only post: the words set large on a soft mint-to-
/// charcoal gradient, so a status reads as deliberately as a photo does.
class _TextPanel extends StatelessWidget {
  const _TextPanel({required this.child});

  final Widget child;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      DesignTokens.primaryGreenLight,
      DesignTokens.primaryGreenDark,
      DesignTokens.bgAppBodyLight,
    ],
    stops: [0, 0.45, 1],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('feed-post-text-panel'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s20,
        DesignTokens.s16,
        DesignTokens.s20,
        DesignTokens.s24,
      ),
      decoration: const BoxDecoration(gradient: _gradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            size: DesignTokens.iconLarge,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(height: DesignTokens.s4),
          child,
        ],
      ),
    );
  }
}

/// Wraps post media so a double-tap likes it and pops a big heart over it.
/// With reduced motion the heart simply appears and goes, without the pop.
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
                const heart = Icon(
                  Icons.favorite,
                  key: Key('feed-post-heart-pop'),
                  size: 96,
                  color: DesignTokens.textWhite,
                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 24)],
                );
                if (reduceMotion) return heart;
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(scale: _scale.value, child: heart),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Carousel position, on a small dark pill so it reads over any photo.
class _CarouselDots extends StatelessWidget {
  const _CarouselDots({required this.count, required this.page});

  final int count;
  final int page;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : DesignTokens.motionFast;
    return Container(
      key: const Key('feed-post-dots'),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s6,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.baseBlack.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final active = index == page;
          return AnimatedContainer(
            duration: duration,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: active ? 7 : 6,
            height: active ? 7 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textWhite.withValues(alpha: 0.5),
            ),
          );
        }),
      ),
    );
  }
}

/// "♥ 12 likes" on the left, "3 comments" on the right — the at-a-glance
/// engagement line between the media and the action buttons.
class _EngagementSummary extends StatelessWidget {
  const _EngagementSummary({
    required this.likeCount,
    required this.commentCount,
    required this.onComments,
  });

  final int likeCount;
  final int commentCount;
  final VoidCallback onComments;

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
          if (likeCount > 0) ...[
            const _HeartBadge(),
            const SizedBox(width: DesignTokens.s6),
          ],
          Expanded(child: _LikesLine(likeCount: likeCount)),
          if (commentCount > 0)
            InkWell(
              key: const Key('feed-post-comment-count'),
              onTap: onComments,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                  vertical: DesignTokens.s4,
                ),
                child: Text(
                  '${feedCount(commentCount)} '
                  '${commentCount == 1 ? 'comment' : 'comments'}',
                  style: DesignTokens.smallRegular,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A small filled heart disc, Facebook reaction-badge style.
class _HeartBadge extends StatelessWidget {
  const _HeartBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: DesignTokens.accentHeart,
      ),
      child: const Icon(
        Icons.favorite,
        size: 11,
        color: DesignTokens.iconWhite,
      ),
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
    return InkWell(
      key: const Key('feed-post-view-comments'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
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

/// Tagged products as the card's footer: a "Shop this post" title over a
/// swipeable row of mint product chips.
class _ShopStrip extends StatelessWidget {
  const _ShopStrip({required this.products, required this.onTap});

  final List<FeedTaggedProduct> products;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final count = products.length;
    return DecoratedBox(
      key: const Key('feed-post-shop-strip'),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: DesignTokens.iconSmall,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: DesignTokens.s6),
                  Expanded(
                    child: Text(
                      'Shop this post',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                  Text(
                    '$count ${count == 1 ? 'item' : 'items'}',
                    style: DesignTokens.smallRegular,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            SizedBox(
              height: DesignTokens.minTouchTarget,
              child: ListView.separated(
                key: const Key('feed-post-shop-row'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                ),
                itemCount: count,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: DesignTokens.s8),
                itemBuilder: (_, index) =>
                    _ShopChip(product: products[index], onTap: onTap),
              ),
            ),
          ],
        ),
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
      side: BorderSide(color: DesignTokens.chipsSelectedBorder, width: 0.5),
    );
    return Material(
      color: DesignTokens.primaryGreenLight,
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
              // Video-first: a product glyph, never the product's photograph
              // (owner directive, 2026-09-16).
              Container(
                width: DesignTokens.avatarSmall,
                height: DesignTokens.avatarSmall,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.primaryGreenDark,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.primaryGreen,
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
