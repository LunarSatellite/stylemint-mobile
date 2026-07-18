import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_comments_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

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
            child: CircularProgressIndicator(color: DesignTokens.primaryGreen)),
        error: (_, _e) => const Center(
          child: Text(
            "Couldn't load this reel.",
            style: DesignTokens.bodyText,
          ),
        ),
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
          videoUrl: reel.videoUrl,
          thumbnailUrl: reel.thumbnailUrl ?? '',
          isActive: true,
          playbackController: _playback,
        ),

        // Full-screen tap target for play/pause, below the interactive
        // controls so their own taps still register.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _playback.toggle,
          ),
        ),

        // Bottom scrim so overlaid text stays legible over any video.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
                stops: [0.45, 1.0],
              ),
            ),
          ),
        ),

        // Transparent top bar over the video.
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      size: 18, color: DesignTokens.textWhite),
                  onPressed: () => context.pop(),
                ),
                const Text('Reel Details', style: DesignTokens.sectionInnerTitle),
              ],
            ),
          ),
        ),

        // Right-rail read-only analytics — same visual language as the
        // Home feed's ReelActions right rail.
        Positioned(
          right: DesignTokens.s12,
          bottom: 220,
          child: _AnalyticsRail(reel: reel),
        ),

        // Bottom info block: platform/source/music chip row + tap-to-expand
        // caption, then the tagged-products strip — same structure as
        // CreatorInfo + TaggedProductsSection on the Home feed.
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 72, left: DesignTokens.s12),
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
  bool _captionExpanded = false;

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
                onTap: () => launchUrl(
                  Uri.parse(reel.sourceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Icon(Icons.open_in_new,
                    size: 16, color: DesignTokens.textLight),
              ),
            ],
          ],
        ),
        if (reel.musicLabel != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Row(
            children: [
              const Icon(Icons.music_note,
                  size: DesignTokens.iconSmall, color: DesignTokens.textLight),
              const SizedBox(width: DesignTokens.s4),
              Expanded(
                child: Text(reel.musicLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textLight)),
              ),
            ],
          ),
        ],
        if (reel.caption != null && reel.caption!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          // Collapsed by default (stays docked at the bottom); tapping
          // expands in place — same interaction as the Home feed's caption.
          GestureDetector(
            onTap: () => setState(() => _captionExpanded = !_captionExpanded),
            child: Text(reel.caption!,
                maxLines: _captionExpanded ? null : 3,
                overflow: _captionExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                  color: DesignTokens.textWhite,
                )),
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
      children: [
        _RailStat(icon: Icons.remove_red_eye_outlined, value: reel.views),
        const SizedBox(height: DesignTokens.s12),
        _RailStat(icon: Icons.favorite_outline, value: reel.likes),
        const SizedBox(height: DesignTokens.s12),
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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          // Trimmed down from the design-spec's 16px padding / 24px icon —
          // that read as oversized/cluttered on-device; this keeps the same
          // pill look at a tighter, more standard reel-rail size.
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: DesignTokens.s8,
              horizontal: DesignTokens.s8,
            ),
            decoration: const BoxDecoration(
              color: Color(0x99333333),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: DesignTokens.iconWhite, size: 20),
                const SizedBox(height: 2),
                Text(
                  _formatCount(value),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ],
            ),
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
          horizontal: DesignTokens.s12, vertical: 6),
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
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: (img == null || img.isEmpty)
                      ? const ColoredBox(color: DesignTokens.bgAppBodyLight)
                      : Image.network(img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _e, _s) => const ColoredBox(
                              color: DesignTokens.bgAppBodyLight)),
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
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.textWhite),
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
