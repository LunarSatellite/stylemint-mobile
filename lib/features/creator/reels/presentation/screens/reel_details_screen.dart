import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/presentation/notifiers/creator_reel_actions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_creator_strip.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Single-reel detail (creator) — same full-screen layout as the Home feed's
/// [ReelCard]/[CreatorInfo]/[TaggedProductsSection] (Figma-designed), reused
/// here rather than re-invented: full-screen video, a right-rail (styled
/// like ReelActions) for the read-only view/like/comment counts, and a
/// bottom info block (styled like CreatorInfo) with a tap-to-expand caption
/// followed by the tagged-products strip.
///
/// Backend: `GET /v1/public/reels/{id}` → ReelDto (caption, metrics, tagged
/// products). Video is external — the source opens via [CreatorReelDetail.sourceUrl].
class ReelDetailsScreen extends ConsumerWidget {
  const ReelDetailsScreen({required this.reelId, super.key});

  final String reelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(creatorReelDetailProvider(reelId));
    return Scaffold(
      backgroundColor: DesignTokens.baseBlack,
      extendBodyBehindAppBar: true,
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        error: (err, _) {
          if (err is NetworkExceptions && err.isNotFound) {
            return const _ReelUnavailableView();
          }
          final message = err is NetworkExceptions
              ? NetworkExceptions.getMessage(err)
              : err.toString();
          return _ReelErrorView(reelId: reelId, message: message);
        },
        data: (reel) => _Body(reel: reel),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.reel});

  final CreatorReelDetail reel;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _playback = ReelPlaybackController();

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelPlayer(
          reel: reel,
          isActive: true,
          playbackController: _playback,
          // Single reel on screen, no bandwidth competition from siblings —
          // opt into autoplay so the user lands on playback immediately.
          autoplay: true,
        ),

        // Full-screen tap target for play/pause, below the interactive
        // controls so their own taps still register.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _playback.toggle,
          ),
        ),

        // Combined top + bottom scrim so the top bar (top ~22%) and
        // the bottom info block (bottom ~55%) stay legible over any video,
        // while leaving the middle of the frame fully visible.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0xDD000000),
                ],
                stops: [0.0, 0.22, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // Top bar: circular back button on the left, popup-menu actions on the
        // right. Backdrop keeps the back button legible over any video frame.
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
              child: Row(
                children: [
                  Material(
                    color: DesignTokens.baseBlack.withValues(alpha: 0.45),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.pop(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          size: 18,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _ReelActionsMenu(reel: reel),
                ],
              ),
            ),
          ),
        ),
        // Right-rail read-only analytics — same visual language as the
        // Home feed's ReelActions right rail.
        Positioned(
          right: DesignTokens.s12,
          bottom: 320,
          child: _AnalyticsRail(reel: reel),
        ),

        // Bottom info block: creator strip (avatar + @handle + Subscribe +
        // caption) on top, then the chip/music meta row, then the tagged-
        // products strip. The right-edge padding (72) leaves room for the
        // analytics rail above this block.
        SafeArea(
          top: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 72),
                child: ReelCreatorStrip(
                  creatorId: reel.creatorId,
                  creatorHandle: reel.creatorHandle,
                  creatorDisplayName: reel.creatorDisplayName,
                  creatorAvatarUrl: reel.creatorAvatarUrl,
                  caption: reel.caption,
                  initialFollowing: reel.isCreatorFollowed,
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              Padding(
                padding: const EdgeInsets.only(
                  right: 72,
                  left: DesignTokens.s12,
                ),
                child: _ReelInfo(reel: reel),
              ),
              if (reel.taggedProducts.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s12),
                _TaggedProductsStrip(products: reel.taggedProducts),
              ],
              const SizedBox(height: DesignTokens.s16),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReelInfo extends StatefulWidget {
  const _ReelInfo({required this.reel});
  final CreatorReelDetail reel;

  @override
  State<_ReelInfo> createState() => _ReelInfoState();
}

class _ReelInfoState extends State<_ReelInfo> {
  static const _externalLauncher = ReelExternalLauncher();

  Future<void> _openSource() async {
    final source = Uri.tryParse(widget.reel.sourceUrl);
    if (source == null || !source.hasScheme) return;
    await _externalLauncher.open(source);
  }

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Chip(icon: Icons.public, label: reel.platformLabel),
            if (reel.sourceUrl.isNotEmpty) ...[
              const SizedBox(width: DesignTokens.s8),
              GestureDetector(
                onTap: _openSource,
                child: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: DesignTokens.textLight,
                ),
              ),
            ],
          ],
        ),
        if (reel.musicLabel != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Row(
            children: [
              const Icon(
                Icons.music_note,
                size: DesignTokens.iconSmall,
                color: DesignTokens.textLight,
              ),
              const SizedBox(width: DesignTokens.s4),
              Expanded(
                child: Text(
                  reel.musicLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AnalyticsRail extends StatelessWidget {
  const _AnalyticsRail({required this.reel});
  final CreatorReelDetail reel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RailStat(icon: Icons.remove_red_eye_outlined, value: reel.views),
        const SizedBox(height: DesignTokens.s28),
        _RailStat(icon: Icons.favorite_outline, value: reel.likes),
        const SizedBox(height: DesignTokens.s28),
        _RailStat(
          icon: Icons.chat_bubble_outline,
          value: reel.comments,
          onTap: () => showReelCommentsSheet(context, reel.id),
        ),
      ],
    );
  }
}

class _RailStat extends StatelessWidget {
  const _RailStat({required this.icon, required this.value, this.onTap});
  final IconData icon;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 56,
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.s12,
            horizontal: DesignTokens.s4,
          ),
          decoration: const BoxDecoration(
            color: Color(0xCC333333),
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DesignTokens.iconWhite, size: 26),
              Text(
                _formatCount(value),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  height: 1,
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DesignTokens.textLight),
          const SizedBox(width: DesignTokens.s4),
          Text(label, style: DesignTokens.smallRegular),
        ],
      ),
    );
  }
}

/// Horizontal strip of tagged products — same visual style as the Home
/// feed's TaggedProductsSection, but showing commission (creator-relevant)
/// instead of an Add to Cart action.
class _TaggedProductsStrip extends StatelessWidget {
  const _TaggedProductsStrip({required this.products});
  final List<ReelTaggedProduct> products;

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width - 24;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
        itemCount: products.length,
        separatorBuilder: (_, _i) => const SizedBox(width: DesignTokens.s12),
        itemBuilder: (_, i) =>
            _ProductTile(product: products[i], width: cardWidth),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.width});
  final ReelTaggedProduct product;
  final double width;

  @override
  Widget build(BuildContext context) {
    final img = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(DesignTokens.s8),
          decoration: BoxDecoration(
            color: const Color(0xFF333333).withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s8),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: (img == null || img.isEmpty)
                      ? const ColoredBox(color: DesignTokens.bgAppBodyLight)
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _e, _s) => const ColoredBox(
                            color: DesignTokens.bgAppBodyLight,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name ?? 'Product',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      '${product.priceLabel} · ${product.commissionPercent.toStringAsFixed(0)}% commission',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
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

/// Write-side controls for the creator's own reel: publish/unpublish and
/// tagged-product management. Sits in the top bar's trailing slot, which
/// previously held a spacer that balanced the back button.
///
/// The backend reel projection carries no explicit status flag, so
/// `publishedAtUtc` stands in for it: a reel that has never been published
/// has no publish timestamp. If that proxy is ever wrong the opposite action
/// is still reachable — both calls are idempotent server-side.
class _ReelActionsMenu extends ConsumerWidget {
  const _ReelActionsMenu({required this.reel});

  final CreatorReelDetail reel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy =
        ref.watch(creatorReelActionsNotifierProvider)
            is CreatorReelActionInProgress;

    ref.listen<CreatorReelActionState>(
      creatorReelActionsNotifierProvider,
      (_, next) {
        final message = switch (next) {
          CreatorReelActionSucceeded(:final message) => message,
          CreatorReelActionFailed(:final message) => message,
          _ => null,
        };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        ref.read(creatorReelActionsNotifierProvider.notifier).reset();
      },
    );

    final isPublished = reel.publishedAtUtc != null;

    return Material(
      color: DesignTokens.baseBlack.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: SizedBox(
        width: 40,
        height: 40,
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(11),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.textWhite,
                ),
              )
            : PopupMenuButton<_ReelAction>(
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: DesignTokens.textWhite,
                ),
                tooltip: 'Reel actions',
                onSelected: (action) =>
                    _onSelected(context, ref, action, isPublished),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: isPublished
                        ? _ReelAction.unpublish
                        : _ReelAction.publish,
                    child: Text(isPublished ? 'Unpublish' : 'Publish'),
                  ),
                  const PopupMenuItem(
                    value: _ReelAction.manageTags,
                    child: Text('Manage tagged products'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _ReelAction action,
    bool isPublished,
  ) async {
    final notifier = ref.read(creatorReelActionsNotifierProvider.notifier);
    switch (action) {
      case _ReelAction.publish:
        if (await notifier.publish(reel.id)) {
          ref.invalidate(creatorReelDetailProvider(reel.id));
        }
      case _ReelAction.unpublish:
        if (await notifier.unpublish(reel.id)) {
          ref.invalidate(creatorReelDetailProvider(reel.id));
        }
      case _ReelAction.manageTags:
        if (!context.mounted) return;
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: DesignTokens.baseBlack,
          isScrollControlled: true,
          builder: (_) => _TaggedProductsSheet(reelId: reel.id),
        );
    }
  }
}

enum _ReelAction { publish, unpublish, manageTags }

/// Lists the reel's tags from the creator-scoped management endpoint (which,
/// unlike the public projection embedded in the reel, carries each tag's own
/// id and commission snapshot) and lets the creator remove one.
class _TaggedProductsSheet extends ConsumerWidget {
  const _TaggedProductsSheet({required this.reelId});

  final String reelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reelTaggedProductsProvider(reelId));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: async.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(DesignTokens.s24),
            child: Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(DesignTokens.s24),
            child: Text(
              '$e'.replaceFirst('Exception: ', ''),
              style: DesignTokens.bodyText,
            ),
          ),
          data: (tags) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tagged products',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s12),
              if (tags.isEmpty)
                const Text(
                  'No products tagged on this reel yet.',
                  style: DesignTokens.bodyText,
                )
              else
                ...tags.map(
                  (tag) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: tag.productImageUrl == null
                        ? null
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              tag.productImageUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _e, _s) =>
                                  const SizedBox(width: 44, height: 44),
                            ),
                          ),
                    title: Text(
                      tag.productName ?? 'Product',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.bodyText,
                    ),
                    subtitle: Text(
                      '${tag.priceLabel}  ·  '
                      '${tag.commissionPercent.toStringAsFixed(0)}% '
                      '(${tag.commissionPerSaleLabel})',
                      style: DesignTokens.bodyText,
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: DesignTokens.textLight,
                      ),
                      tooltip: 'Remove tag',
                      onPressed: () async {
                        final ok = await ref
                            .read(creatorReelActionsNotifierProvider.notifier)
                            .untagProduct(reelId, tag.id);
                        if (ok) {
                          ref
                            ..invalidate(reelTaggedProductsProvider(reelId))
                            ..invalidate(creatorReelDetailProvider(reelId));
                        }
                      },
                    ),
                  ),
                ),
              const SizedBox(height: DesignTokens.s8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the public reels endpoint returns 404 (the most common cause:
/// the reel is unpublished/deleted but still appears in this creator's
/// top-performing analytics, so the public catalog legitimately has no record
/// of it). Clear messaging + a back button so the creator is never stranded.
class _ReelUnavailableView extends StatelessWidget {
  const _ReelUnavailableView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.movie_filter_outlined,
                size: 56,
                color: DesignTokens.iconLight,
              ),
              const SizedBox(height: DesignTokens.s16),
              const Text(
                'This reel is no longer available',
                textAlign: TextAlign.center,
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                "It may have been unpublished or removed. It will drop off your "
                "top-performing list once analytics refresh.",
                textAlign: TextAlign.center,
                style: DesignTokens.bodyText.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Back to top reels'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Generic fallback for any non-404 error (network, server, parsing). Keeps
/// the user on the screen with a retry instead of dumping them back to the
/// list and forcing a full re-navigation.
class _ReelErrorView extends ConsumerWidget {
  const _ReelErrorView({required this.reelId, required this.message});

  final String reelId;
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: DesignTokens.iconLight,
              ),
              const SizedBox(height: DesignTokens.s16),
              const Text(
                "Couldn't load this reel",
                textAlign: TextAlign.center,
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: DesignTokens.bodyText.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: DesignTokens.borderDefault),
                      foregroundColor: DesignTokens.textWhite,
                      minimumSize: const Size(0, DesignTokens.buttonHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          DesignTokens.buttonRadius,
                        ),
                      ),
                    ),
                    child: const Text('Back'),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(creatorReelDetailProvider(reelId)),
                    style: DesignTokens.primaryButtonStyle(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
