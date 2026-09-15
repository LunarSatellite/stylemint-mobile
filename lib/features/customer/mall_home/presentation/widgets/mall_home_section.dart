import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/reel_products_sheet.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One Mall home section drawn with the kit.
class MallHomeSectionView extends ConsumerWidget {
  const MallHomeSectionView({
    required this.section,
    super.key,
    this.prominent = false,
  });

  final HomeSection section;

  /// The page's lead product rail uses the larger card.
  final bool prominent;

  /// Width of a category tile in its rail.
  static const double categoryTileWidth = 124;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(MallDestination destination) =>
        openMallDestination(context, ref, destination);
    void push(String location) => open(MallPush(location));

    final seeAll = destinationForSeeAll(section);
    final onSeeAll = seeAll == null ? null : () => open(seeAll);
    final label = section.title ?? '';

    return switch (section) {
      HomeCampaignsSection(:final items) => _CampaignHero(
        campaigns: items,
        onCta: (cta) {
          final destination = destinationForCta(cta);
          if (destination != null) open(destination);
        },
      ),
      HomeProductsSection(:final items) => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: _ProductRail(
          products: items,
          prominent: prominent,
          semanticLabel: label.isEmpty ? 'Products' : label,
          onTap: (product) => push(MallRoutes.product(product.id)),
        ),
      ),
      HomeReelsSection(:final items) => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: MallRail<HomeReel>(
          items: items,
          itemWidth: MallReelCard.regularWidth,
          height: MallReelCard.heightFor(MallReelCard.regularWidth),
          semanticLabel: label.isEmpty ? 'Shoppable reels' : label,
          itemBuilder: (context, reel, _) => MallReelCard(
            reel: reel.toVm(),
            onTap: () => push(MallRoutes.reel(reel.id)),
            onTaggedProductsTap: reel.taggedProductCount > 0
                ? () => unawaited(showReelProductsSheet(context, reel: reel))
                : null,
          ),
        ),
      ),
      HomeCategoriesSection(:final items) => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: MallRail<HomeCategory>(
          items: items,
          itemWidth: categoryTileWidth,
          height: MallCategoryTile.heightFor(
            categoryTileWidth,
            shape: MallTileShape.tall,
          ),
          semanticLabel: label.isEmpty ? 'Categories' : label,
          itemBuilder: (_, category, _) => MallCategoryTile(
            category: category.toVm(),
            shape: MallTileShape.tall,
            onTap: () => push(MallRoutes.category(category)),
          ),
        ),
      ),
      HomeBrandsSection(:final items) => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: MallRail<HomeBrand>(
          items: items,
          itemWidth: MallBrandCard.defaultWidth,
          height: MallBrandCard.heightFor(
            context,
            width: MallBrandCard.defaultWidth,
          ),
          semanticLabel: label.isEmpty ? 'Brands' : label,
          itemBuilder: (_, brand, _) => MallBrandCard(
            brand: brand.toVm(),
            onTap: () =>
                push(MallRoutes.brand(brand.vendorAccountId, brand.name)),
          ),
        ),
      ),
      HomeCreatorsSection(:final items) => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: MallRail<HomeCreator>(
          items: items,
          itemWidth: MallCreatorCard.defaultWidth,
          height: MallCreatorCard.heightFor(context, hasFollowAction: false),
          semanticLabel: label.isEmpty ? 'Creators' : label,
          itemBuilder: (_, creator, _) => MallCreatorCard(
            creator: creator.toVm(),
            onTap: () => push(MallRoutes.creator(creator.accountId)),
          ),
        ),
      ),
      HomeCollectionsSection(:final items) => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: MallRail<HomeCollection>(
          items: items,
          itemWidth: MallCollectionCard.defaultWidth,
          height: MallCollectionCard.heightFor(MallCollectionCard.defaultWidth),
          semanticLabel: label.isEmpty ? 'Collections' : label,
          itemBuilder: (_, collection, _) => MallCollectionCard(
            collection: collection.toVm(),
            onTap: () => push(MallRoutes.collection(collection.slug)),
          ),
        ),
      ),
      HomeTrustSection() => _Titled(
        section: section,
        onSeeAll: onSeeAll,
        child: const MallTrustStrip(),
      ),
    };
  }
}

/// A section header (when the section has a title) above its content. The
/// personalisation reason, when sent, is the subtle subtitle.
class _Titled extends StatelessWidget {
  const _Titled({
    required this.section,
    required this.onSeeAll,
    required this.child,
  });

  final HomeSection section;
  final VoidCallback? onSeeAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final title = section.title;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          MallSectionHeader(
            title: title,
            eyebrow: section.eyebrow,
            subtitle: section.reason ?? section.subtitle,
            onSeeAll: onSeeAll,
          ),
        child,
      ],
    );
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.products,
    required this.prominent,
    required this.semanticLabel,
    required this.onTap,
  });

  final List<HomeProduct> products;
  final bool prominent;
  final String semanticLabel;
  final ValueChanged<HomeProduct> onTap;

  @override
  Widget build(BuildContext context) {
    final size = prominent ? MallCardSize.regular : MallCardSize.compact;
    final width = prominent
        ? MallProductCard.regularWidth
        : MallProductCard.compactWidth;
    return MallRail<HomeProduct>(
      items: products,
      itemWidth: width,
      height: MallProductCard.heightFor(context, width: width, size: size),
      semanticLabel: semanticLabel,
      itemBuilder: (_, product, _) => MallProductCard(
        product: product.toVm(),
        size: size,
        onTap: () => onTap(product),
      ),
    );
  }
}

/// The campaign carousel, inset with rounded corners so it reads as the
/// page's lead editorial image.
class _CampaignHero extends StatelessWidget {
  const _CampaignHero({required this.campaigns, required this.onCta});

  final List<HomeCampaign> campaigns;
  final ValueChanged<HomeCampaignCta> onCta;

  static final BorderRadius _radius = BorderRadius.circular(
    DesignTokens.radiusLarge,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: DesignTokens.shadowLifted,
        ),
        child: MallCampaignHero(
          campaigns: [for (final campaign in campaigns) campaign.toVm()],
          borderRadius: _radius,
          // Stops advancing while Home is hidden (Reels, another tab).
          autoAdvance: TickerMode.valuesOf(context).enabled,
          onAction: (campaign, action) {
            final source = campaigns
                .where((c) => c.id == campaign.id)
                .firstOrNull;
            final index = int.tryParse(action.id);
            if (source == null || index == null) return;
            if (index < 0 || index >= source.ctas.length) return;
            onCta(source.ctas[index]);
          },
        ),
      ),
    );
  }
}
