import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/presentation/follow_notifier.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/platform_avatar_carousel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_rail_icons.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';

/// Right-hand rail on a feed reel ("A · Studio", approved 2026-09-14), top to
/// bottom: the creator (profile + follow), like, comments, share, and the
/// first tagged product — or the cart when nothing is tagged.
///
/// Comments are native Style Mint interactions. A reel's likes are owned by
/// its source platform, so the heart hands off to that provider instead of
/// showing a misleading local-only toggle. Follow, share and cart are
/// authenticated.
class ReelActions extends ConsumerStatefulWidget {
  const ReelActions({required this.reel, super.key});

  final Reel reel;

  @override
  ConsumerState<ReelActions> createState() => _ReelActionsState();
}

class _ReelActionsState extends ConsumerState<ReelActions> {
  static const _externalLauncher = ReelExternalLauncher();

  // Optimistic local override — reel.commentCount is a frozen snapshot from
  // the feed fetch that nothing else refreshes, so a successful post has to
  // update this directly or the count never reflects it.
  late int _commentCount = widget.reel.commentCount;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _seedFollow();
  }

  @override
  void didUpdateWidget(ReelActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.id != widget.reel.id) {
      _commentCount = widget.reel.commentCount;
      _seedFollow();
    }
  }

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

  Future<void> _likeOnProvider() async {
    final url = Uri.tryParse(widget.reel.sourceUrl);
    if (url == null || !url.hasScheme) {
      _showProviderUnavailable();
      return;
    }
    final opened = await _externalLauncher.open(url);
    if (mounted && !opened) _showProviderUnavailable();
  }

  void _showProviderUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open the source reel.')),
    );
  }

  void _openComments() {
    showReelCommentsSheet(
      context,
      widget.reel.id,
      onCommentPosted: () => setState(() => _commentCount++),
    );
  }

  Future<void> _share() async {
    final reel = widget.reel;
    if (await ensureAuth(context, ref, reason: AuthReason.share)) {
      unawaited(
        SharePlus.instance.share(
          ShareParams(
            text:
                "${reel.caption}\n\nWatch ${reel.creatorName}'s reel "
                'on Style Mint: ${reel.sourceUrl}',
          ),
        ),
      );
    }
  }

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
    final products = reel.taggedProducts;
    final product = products.isEmpty ? null : products.first;
    final productName = product == null || product.name.trim().isEmpty
        ? 'product'
        : product.name.trim();
    // Cart badge — so "did my add-to-cart tap do anything?" has a visible
    // answer right on the rail. Only watched while the cart is on the rail.
    final cartItemCount = product != null
        ? 0
        : ref.watch(
            cartNotifierProvider.select(
              (state) => state.maybeWhen(
                loadSuccess: (cart) =>
                    cart.items.fold<int>(0, (sum, i) => sum + i.quantity),
                orElse: () => 0,
              ),
            ),
          );

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
                icon: ReelRailIcons.heart,
                label: 'Like',
                hint: 'Opens the source reel',
                count: formatRailCount(reel.likeCount),
                popOnTap: true,
                onTap: _likeOnProvider,
              ),
              ReelRailButton(
                icon: ReelRailIcons.comment,
                label: 'Comments',
                count: formatRailCount(_commentCount),
                onTap: _openComments,
              ),
              ReelRailButton(
                icon: ReelRailIcons.share,
                label: 'Share',
                count: formatRailCount(reel.shareCount),
                onTap: _share,
              ),
              if (product != null)
                ReelRailProductTile(
                  imageUrl: product.imageUrl,
                  priceLabel: formatMoneyCompact(product.price),
                  label:
                      'Shop $productName, '
                      '${formatMoney(product.price, decimalDigits: 0)}',
                  onTap: () => _openProduct(product),
                )
              else
                ReelRailCartDisc(itemCount: cartItemCount, onTap: _openCart),
            ],
          ),
        ),
      ),
    );
  }
}
