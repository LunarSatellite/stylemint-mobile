import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_routes.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One bundle as a card on a rail: picture, title, counts, prices.
class BundleCardTile extends StatelessWidget {
  const BundleCardTile({
    required this.bundle,
    this.width = 220,
    this.taggedBundleId,
    super.key,
  });

  static Key tileKey(String bundleId) => Key('bundle-card-$bundleId');

  final BundleCard bundle;
  final double width;
  final String? taggedBundleId;

  @override
  Widget build(BuildContext context) {
    final discount = bundleDiscountLabel(bundle.discountPercent);
    final counts = bundleCountsLabel(
      items: bundle.itemCount,
      shops: bundle.shopCount,
    );
    return SizedBox(
      width: width,
      child: Material(
        color: DesignTokens.bgAppBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          side: const BorderSide(color: DesignTokens.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: tileKey(bundle.id),
          onTap: () => context.push(
            BundleRoutes.detailPath(
              bundle.id,
              taggedBundleId: taggedBundleId,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    MallNetworkImage(url: bundle.imageUrl),
                    if (discount != null)
                      Positioned(
                        left: DesignTokens.s8,
                        top: DesignTokens.s8,
                        child: _Badge(discount),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(DesignTokens.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.title,
                      style: DesignTokens.mediumSemibold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (counts.isNotEmpty)
                      Text(
                        counts,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: DesignTokens.s4),
                    Wrap(
                      spacing: DesignTokens.s8,
                      children: [
                        Text(
                          bundleMoney(bundle.bundleTotal),
                          style: DesignTokens.mediumSemibold,
                        ),
                        if (bundle.hasSaving)
                          Text(
                            bundleMoney(bundle.listTotal),
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    if (!bundle.isPurchasable)
                      Text(
                        'Not available right now',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.colorWarning,
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

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: 2,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreen,
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
    ),
    child: Text(
      text,
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.baseBlack,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// A "Bundles" rail for a storefront or creator profile, as one sliver.
/// Draws nothing while loading, on any error (a bare 404 means bundles are
/// not deployed), and when there are none.
class BundleRailSliver extends ConsumerWidget {
  const BundleRailSliver({
    required this.listKey,
    this.title = 'Bundles',
    this.eyebrow = 'Shop the set',
    super.key,
  });

  static const Key railKey = Key('bundle-rail');

  final BundleListKey listKey;
  final String title;
  final String eyebrow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundles = ref.watch(bundleListProvider(listKey)).asData?.value;
    if (bundles == null || bundles.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Padding(
        key: railKey,
        padding: const EdgeInsets.only(top: DesignTokens.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(title, style: DesignTokens.sectionInnerTitle),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              height: 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                itemCount: bundles.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: DesignTokens.s12),
                itemBuilder: (_, i) => BundleCardTile(bundle: bundles[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The bundles tagged on a reel, as chips over the video beside its product
/// tags (contract §B9). Tapping one opens the bundle with the reel's tag, so
/// the add credits the reel's creator.
class ReelBundleTags extends StatelessWidget {
  const ReelBundleTags({required this.bundles, super.key});

  static Key chipKey(String taggedBundleId) =>
      Key('reel-bundle-tag-$taggedBundleId');

  final List<ReelTaggedBundle> bundles;

  @override
  Widget build(BuildContext context) {
    if (bundles.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 72),
      child: Row(
        children: [
          for (final tag in bundles.take(3))
            Padding(
              padding: const EdgeInsets.only(right: DesignTokens.s8),
              child: _ReelBundleChip(tag: tag),
            ),
        ],
      ),
    );
  }
}

class _ReelBundleChip extends StatelessWidget {
  const _ReelBundleChip({required this.tag});

  final ReelTaggedBundle tag;

  @override
  Widget build(BuildContext context) {
    final b = tag.bundle;
    final price = b.hasSaving
        ? '${bundleMoney(b.bundleTotal)} · save ${bundleMoney(b.saving)}'
        : bundleMoney(b.bundleTotal);
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
        side: BorderSide(
          color: DesignTokens.primaryGreen.withValues(alpha: 0.7),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ReelBundleTags.chipKey(tag.taggedBundleId),
        onTap: () => context.push(
          BundleRoutes.detailPath(b.id, taggedBundleId: tag.taggedBundleId),
        ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: MallNetworkImage(url: b.imageUrl),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: DesignTokens.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            b.title,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textWhite,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      price,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
