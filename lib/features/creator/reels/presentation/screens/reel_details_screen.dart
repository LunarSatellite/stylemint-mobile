import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single-reel detail (creator) — full-screen Instagram-style viewer.
/// Video fills the whole screen; analytics sit in a vertical right-rail;
/// caption + tagged products live in a bottom panel that's collapsed to a
/// one-line preview until tapped, then expands to show everything.
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
  bool _detailsExpanded = false;

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
                stops: [0.5, 1.0],
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

        // Right-rail analytics (read-only — views / likes / comments).
        Positioned(
          right: DesignTokens.s12,
          bottom: 220,
          child: _AnalyticsRail(reel: reel),
        ),

        // Collapsed-by-default details panel; tap to expand.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: () => setState(() => _detailsExpanded = !_detailsExpanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                constraints: BoxConstraints(
                  maxHeight: _detailsExpanded
                      ? MediaQuery.of(context).size.height * 0.62
                      : 96,
                ),
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s12, 72, DesignTokens.s16,
                ),
                child: SingleChildScrollView(
                  physics: _detailsExpanded
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _detailsExpanded
                                ? Icons.keyboard_arrow_down_rounded
                                : Icons.keyboard_arrow_up_rounded,
                            color: DesignTokens.textMuted,
                            size: 18,
                          ),
                          const SizedBox(width: DesignTokens.s4),
                          _Chip(icon: Icons.public, label: reel.platformLabel),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      if (reel.caption != null && reel.caption!.isNotEmpty)
                        Text(
                          reel.caption!,
                          maxLines: _detailsExpanded ? null : 1,
                          overflow: _detailsExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: DesignTokens.bodyText
                              .copyWith(color: DesignTokens.textWhite),
                        ),
                      if (_detailsExpanded) ...[
                        if (reel.sourceUrl.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.s12),
                          TextButton.icon(
                            onPressed: () => launchUrl(
                              Uri.parse(reel.sourceUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('View original'),
                          ),
                        ],
                        if (reel.musicLabel != null) ...[
                          const SizedBox(height: DesignTokens.s8),
                          Row(
                            children: [
                              const Icon(Icons.music_note,
                                  size: 16, color: DesignTokens.textLight),
                              const SizedBox(width: DesignTokens.s4),
                              Expanded(
                                child: Text(reel.musicLabel!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DesignTokens.smallRegular),
                              ),
                            ],
                          ),
                        ],
                        if (reel.taggedProducts.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.s20),
                          const Text('Tagged Products',
                              style: DesignTokens.mediumSemibold),
                          const SizedBox(height: DesignTokens.s12),
                          for (final p in reel.taggedProducts) ...[
                            _ProductRow(product: p),
                            const SizedBox(height: DesignTokens.s8),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
        const SizedBox(height: DesignTokens.s20),
        _RailStat(icon: Icons.favorite_outline, value: reel.likes),
        const SizedBox(height: DesignTokens.s20),
        _RailStat(icon: Icons.chat_bubble_outline, value: reel.comments),
      ],
    );
  }
}

class _RailStat extends StatelessWidget {
  const _RailStat({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.s8,
            horizontal: DesignTokens.s4,
          ),
          decoration: const BoxDecoration(
            color: Color(0x99333333),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DesignTokens.iconWhite, size: 24),
              const SizedBox(height: DesignTokens.s4),
              Text(
                _formatCount(value),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});
  final ReelTaggedProduct product;
  @override
  Widget build(BuildContext context) {
    final img = product.imageUrl;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: (img == null || img.isEmpty)
                  ? Container(
                      color: DesignTokens.bgAppFoundation,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined,
                          color: DesignTokens.iconLight))
                  : Image.network(img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _e, _s) => Container(
                          color: DesignTokens.bgAppFoundation,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined,
                              color: DesignTokens.iconLight))),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name ?? 'Product',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${product.priceLabel}  •  ${product.commissionPercent.toStringAsFixed(0)}% commission',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
