import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_player.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single-reel detail (creator). Pixel-matched to Creator 'Reel Details.pdf'.
/// Backend: `GET /v1/public/reels/{id}` → ReelDto (caption, metrics, tagged
/// products). Video is external — the source opens via [CreatorReelDetail.sourceUrl].
class ReelDetailsScreen extends ConsumerWidget {
  const ReelDetailsScreen({required this.reelId, super.key});

  final String reelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(creatorReelDetailProvider(reelId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reel Details', style: DesignTokens.sectionInnerTitle),
      ),
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
    return ListView(
      // Bottom inset accounts for the device's own gesture/nav bar so the
      // last section (tagged products) isn't hidden behind it on
      // edge-to-edge displays.
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16 + MediaQuery.of(context).padding.bottom,
      ),
      children: [
        AspectRatio(
          aspectRatio: 9 / 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: GestureDetector(
              onTap: _playback.toggle,
              child: ReelPlayer(
                videoUrl: reel.videoUrl,
                thumbnailUrl: reel.thumbnailUrl ?? '',
                isActive: true,
                playbackController: _playback,
              ),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        Row(
          children: [
            _Chip(icon: Icons.public, label: reel.platformLabel),
            if (reel.sourceUrl.isNotEmpty) ...[
              const SizedBox(width: DesignTokens.s8),
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
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Row(
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
              ),
            ],
          ],
        ),
        if (reel.caption != null && reel.caption!.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(reel.caption!, style: DesignTokens.bodyText),
        ],
        const SizedBox(height: DesignTokens.s16),
        Row(
          children: [
            Expanded(child: _Metric(label: 'Views', value: reel.views)),
            Expanded(child: _Metric(label: 'Likes', value: reel.likes)),
            Expanded(child: _Metric(label: 'Comments', value: reel.comments)),
          ],
        ),
        if (reel.taggedProducts.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s24),
          const Text('Tagged Products', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          for (final p in reel.taggedProducts) ...[
            _ProductRow(product: p),
            const SizedBox(height: DesignTokens.s8),
          ],
        ],
      ],
    );
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
        color: DesignTokens.bgAppBodyLight,
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) {
    final v = value < 1000
        ? '$value'
        : '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    return Column(
      children: [
        Text(v, style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s4),
        Text(label,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textMuted)),
      ],
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
        color: DesignTokens.bgAppBodyLight,
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
