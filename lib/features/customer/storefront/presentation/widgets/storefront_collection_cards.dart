import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_collection.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

extension StorefrontCollectionToVm on StorefrontCollection {
  MallCollectionVm toVm() => MallCollectionVm(
    id: slug,
    title: title,
    eyebrow: collectionEyebrow(kind),
    coverUrl: coverImageUrl,
    itemCount: itemCount,
    previewImageUrls: previewImageUrls,
  );
}

/// Wide editorial collection cards: one column on phones, two from 600dp.
class StorefrontSliverCollections extends StatelessWidget {
  const StorefrontSliverCollections({
    required this.collections,
    required this.onTap,
    super.key,
  });

  final List<StorefrontCollection> collections;
  final ValueChanged<StorefrontCollection> onTap;

  static const double aspectRatio = 4 / 3;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: DesignTokens.s16,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.crossAxisExtent >= 600 ? 2 : 1,
            mainAxisSpacing: DesignTokens.s16,
            crossAxisSpacing: DesignTokens.s12,
            childAspectRatio: aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final collection = collections[index];
            return MallCollectionCard(
              key: ValueKey(collection.slug),
              collection: collection.toVm(),
              aspectRatio: aspectRatio,
              onTap: () => onTap(collection),
            );
          }, childCount: collections.length),
        ),
      ),
    );
  }
}

/// Tall look cards: two columns on phones, three from 600dp, four from 900dp.
class StorefrontSliverLooks extends StatelessWidget {
  const StorefrontSliverLooks({
    required this.looks,
    required this.onTap,
    super.key,
  });

  final List<StorefrontCollection> looks;
  final ValueChanged<StorefrontCollection> onTap;

  static int columnsFor(double width) => width >= 900
      ? 4
      : width >= 600
      ? 3
      : 2;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: DesignTokens.s16,
        ),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnsFor(constraints.crossAxisExtent),
            mainAxisSpacing: DesignTokens.s12,
            crossAxisSpacing: DesignTokens.s12,
            childAspectRatio: StorefrontLookCard.aspectRatio,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final look = looks[index];
            return StorefrontLookCard(
              key: ValueKey(look.slug),
              look: look,
              onTap: () => onTap(look),
            );
          }, childCount: looks.length),
        ),
      ),
    );
  }
}

/// A look as a tall 3:4 photo card: "The look", its title in the display
/// face and a "Shop the look" line.
class StorefrontLookCard extends StatelessWidget {
  const StorefrontLookCard({
    required this.look,
    required this.onTap,
    super.key,
  });

  final StorefrontCollection look;
  final VoidCallback onTap;

  static const double aspectRatio = 3 / 4;
  static const double railWidth = 196;

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: DesignTokens.displayFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 26 / 22,
    letterSpacing: -0.2,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _ctaStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static String shopLine(int count) => count <= 0
      ? 'Shop the look'
      : count == 1
      ? 'Shop the look · 1 piece'
      : 'Shop the look · $count pieces';

  @override
  Widget build(BuildContext context) {
    final cover =
        look.coverImageUrl ??
        (look.previewImageUrls.isEmpty ? null : look.previewImageUrls.first);
    const radius = BorderRadius.all(Radius.circular(DesignTokens.cardRadius));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: DesignTokens.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: DesignTokens.surfaceRaised),
                  if (cover != null)
                    MallNetworkImage(url: cover)
                  else
                    const MallImagePlaceholder(),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: 0.7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: DesignTokens.imageScrim,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 14,
                    end: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MallEyebrow(
                          'The look',
                          color: DesignTokens.textLight,
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          look.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle,
                        ),
                        const SizedBox(height: DesignTokens.s8),
                        Row(
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: DesignTokens.textWhite,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shopLine(look.itemCount),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _ctaStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            MallTapOverlay(
              semanticLabel:
                  'The look, ${look.title}. '
                  '${shopLine(look.itemCount)}',
              onTap: onTap,
              borderRadius: radius,
            ),
          ],
        ),
      ),
    );
  }
}
