import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/reel_share.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reel_like_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_share_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/platform_avatar_carousel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What the rail shows of the cart: its item count (null until the cart has
/// loaded) and whether the reel's first tagged product is in it.
typedef _RailCart = ({int? count, bool inCart});

const _RailCart _unknownCart = (count: null, inCart: false);

/// Right-hand rail on a feed reel ("A · Studio", approved 2026-09-14), top to
/// bottom: the creator (profile + follow), like, comments, share, and the
/// first tagged product — or the cart when nothing is tagged. The last item
/// reacts when something is added to the cart, from anywhere.
///
/// Nothing on the rail leaves StyleMint (owner decisions, 2026-09-14/15):
/// like and comments are native StyleMint interactions, and share opens
/// StyleMint's own sheet to copy a StyleMint link — never another app.
/// Follow, like, share and cart are authenticated.
class ReelActions extends ConsumerStatefulWidget {
  const ReelActions({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends ConsumerState<ReelActions> {
  // Optimistic local override — reel.commentCount is a frozen snapshot from
  // the feed fetch that nothing else refreshes, so a successful post has to
  // update this directly or the count never reflects it.
  late int _commentCount = widget.reel.commentCount;
  bool _followBusy = false;

  /// The last settled view of the cart; see [_railCart].
  _RailCart _cart = _unknownCart;

  @override
  void initState() {
    super.initState();
    _seedFollow();
    _seedLike();
  }

  @override
  void didUpdateWidget(ReelActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.id != widget.reel.id) {
      _commentCount = widget.reel.commentCount;
      _cart = _unknownCart;
      _seedFollow();
      _seedLike();
    }
  }

  /// The rail's view of [state] for the tagged [productId]. Null while a cart
  /// request is in flight or has failed: the rail then holds its last view,
  /// so an add (loaded → in progress → loaded) reads as the count rising
  /// rather than dropping to nothing and back.
  static _RailCart? _railCart(CartState state, String? productId) =>
      state.maybeWhen(
        initial: () => _unknownCart,
        loadSuccess: (cart) => (
          count: cart.items.fold<int>(0, (sum, item) => sum + item.quantity),
          inCart:
              productId != null &&
              cart.items.any((item) => item.productId == productId),
        ),
        orElse: () => null,
      );

  /// Seeds shared follow state from the reel's isCreatorFollowed flag after
  /// the first frame (a provider must not change during build). A no-op once
  /// the creator was seeded or toggled this session.
  void _seedFollow() {
    final reel = widget.reel;
    final seed = reel.isCreatorFollowed;
    if (reel.creatorId.isEmpty || seed == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(followNotifierProvider.notifier)
            .seed(reel.creatorId, following: seed);
      }
    });
  }

  /// Seeds shared like state from the reel's isLikedByMe flag (null for
  /// guests) after the first frame. Ignored once the reel was toggled.
  void _seedLike() {
    final reel = widget.reel;
    final liked = reel.isLikedByMe;
    if (reel.id.isEmpty || liked == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(reelLikeNotifierProvider.notifier)
            .seed(reel.id, liked: liked, count: reel.likeCount);
      }
    });
  }

  static ReelLikeState _likeSnapshot(Reel reel) =>
      ReelLikeState(liked: reel.isLikedByMe ?? false, count: reel.likeCount);

  /// Same follow flow as `CreatorInfo`: auth gate, then the optimistic
  /// one-way follow toggle (POST/DELETE /v1/follows/{creatorId}).
  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    if (!await ensureAuth(context, ref, reason: AuthReason.follow)) return;
    final id = widget.reel.creatorId;
    if (!mounted || id.isEmpty) return;
    _followBusy = true;
    try {
      await ref.read(followNotifierProvider.notifier).toggle(id);
    } on Object {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't update follow. Please try again.");
      }
    } finally {
      _followBusy = false;
    }
  }

  /// Native StyleMint like: auth gate, then the optimistic toggle
  /// (POST/DELETE /v1/customer/reels/{reelId}/like), rolled back on failure.
  Future<void> _toggleLike() async {
    if (!await ensureAuth(context, ref, reason: AuthReason.like)) return;
    final reel = widget.reel;
    if (!mounted || reel.id.isEmpty) return;
    final failure = await ref
        .read(reelLikeNotifierProvider.notifier)
        .toggle(reel.id, fallback: _likeSnapshot(reel));
    if (failure != null && mounted) {
      SmSnackbar.error(context, "Couldn't update your like. Please try again.");
    }
  }

  void _openProfile() {
    final reel = widget.reel;
    final avatarUrl = reel.creatorAvatarUrl.trim();
    unawaited(
      context.push(
        RouteNames.creatorProfile.replaceFirst(':accountId', reel.creatorId),
        extra: CreatorProfileArgs(
          accountId: reel.creatorId,
          displayName: reel.creatorName,
          handle: reel.creatorName,
          avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
        ),
      ),
    );
  }

  /// Same destination as tapping a product in the feed's tagged-products
  /// strip (`TaggedProductsSection`): the product detail page.
  void _openProduct(TaggedProductEntity product) {
    unawaited(
      context.push(
        RouteNames.productDetail.replaceFirst(':productId', product.id),
      ),
    );
  }

  void _openComments() {
    showReelCommentsSheet(
      context,
      widget.reel.id,
      onCommentPosted: () => setState(() => _commentCount++),
    );
  }

  /// Opens StyleMint's share sheet for the reel's StyleMint link
  /// (`/reels/{reelId}`) — never the platform URL. The viewer can send it to
  /// an app of their choice or copy it.
  Future<void> _share() async {
    final reel = widget.reel;
    if (!await ensureAuth(context, ref, reason: AuthReason.share)) return;
    if (!mounted) return;
    final outcome = await showReelShareSheet(
      context,
      link: ReelShare.link(reel.id),
      message: ReelShare.text(
        reelId: reel.id,
        caption: reel.caption,
        creatorName: reel.creatorName,
      ),
    );
    if (!mounted) return;
    switch (outcome) {
      case ReelShareOutcome.copied:
        SmSnackbar.success(context, ReelShareSheet.copiedMessage);
      case ReelShareOutcome.failed:
        SmSnackbar.error(context, ReelShareSheet.failedMessage);
      case ReelShareOutcome.sent:
      case ReelShareOutcome.dismissed:
        break;
    }
  }

  /// A feed count, hidden until there is something to count: a column of
  /// zeros under every icon reads as an empty reel.
  static String? _visibleCount(int count) =>
      count > 0 ? formatRailCount(count) : null;

  Future<void> _openCart() async {
    if (await ensureAuth(context, ref, reason: AuthReason.addToCart)) {
      if (mounted) await context.push(RouteNames.cart);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final creatorId = reel.creatorId;
    final hasCreator = creatorId.isNotEmpty;
    final creatorName = reel.creatorName.trim().isEmpty
        ? 'creator'
        : reel.creatorName.trim();
    final isFollowing = ref.watch(
      followNotifierProvider.select(
        (ids) => hasCreator && ids.contains(creatorId),
      ),
    );
    final like =
        ref.watch(reelLikeNotifierProvider.select((likes) => likes[reel.id])) ??
        _likeSnapshot(reel);
    final products = reel.taggedProducts;
    final product = products.isEmpty ? null : products.first;
    final productName = product == null || product.name.trim().isEmpty
        ? 'product'
        : product.name.trim();
    // So "did my add-to-cart tap do anything?" has a visible answer right on
    // the rail, whichever button added it. Selected down to a count and a
    // flag so cart edits elsewhere don't rebuild every rail in the feed.
    final productId = product?.id;
    final cart = _cart =
        ref.watch(
          cartNotifierProvider.select((state) => _railCart(state, productId)),
        ) ??
        _cart;

    return RepaintBoundary(
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: SizedBox(
          width: ReelRailStyle.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReelRailAvatar(
                creatorName: creatorName,
                imageUrls: PlatformAvatarCarousel.resolveUrls(
                  reel.creatorAvatarUrls,
                  reel.creatorAvatarUrl,
                ),
                isFollowing: isFollowing,
                onOpenProfile: hasCreator ? _openProfile : null,
                onToggleFollow: hasCreator ? _toggleFollow : null,
              ),
              ReelRailButton(
                icon: like.liked
                    ? ReelRailIcons.heartFilled
                    : ReelRailIcons.heart,
                iconColor: like.liked
                    ? ReelRailStyle.liked
                    : DesignTokens.textWhite,
                label: like.liked ? 'Liked' : 'Like',
                count: _visibleCount(like.count),
                popOnTap: true,
                onTap: _toggleLike,
              ),
              ReelRailButton(
                icon: ReelRailIcons.comment,
                label: 'Comments',
                count: _visibleCount(_commentCount),
                onTap: _openComments,
              ),
              ReelRailButton(
                icon: ReelRailIcons.share,
                label: 'Share',
                count: _visibleCount(reel.shareCount),
                onTap: _share,
              ),
              if (product != null)
                ReelRailProductTile(
                  // A different product is a fresh tile, never a celebration.
                  key: ValueKey('rail-product-${product.id}'),
                  imageUrl: product.imageUrl,
                  priceLabel: formatMoneyCompact(product.price),
                  label:
                      'Shop $productName, '
                      '${formatMoney(product.price, decimalDigits: 0)}',
                  inCart: cart.inCart,
                  cartCount: cart.count,
                  onTap: () => _openProduct(product),
                )
              else
                ReelRailCartDisc(itemCount: cart.count, onTap: _openCart),
            ],
          ),
        ),
      ),
    );
  }
}
