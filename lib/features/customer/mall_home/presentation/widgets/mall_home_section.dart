import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_zones.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/reel_products_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Draws one home section in the treatment its zone calls for.
///
/// The zone is decided in `mall_zones.dart` from the section's own data, so
/// this widget only maps a zone onto a block — it holds no layout opinions
/// and invents no content.
class MallHomeSectionView extends ConsumerWidget {
  const MallHomeSectionView({
    required this.section,
    super.key,
    this.index = 0,
    this.topInset = 0,
    this.overline,
  });

  final HomeSection section;

  /// 1-based block number for the section marker; 0 hides the marker.
  final int index;

  /// Space the cinematic hero keeps clear for the Home switch.
  final double topInset;

  /// A quiet line the hero carries under the switch — the greeting.
  final Widget? overline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open(MallDestination destination) =>
        openMallDestination(context, ref, destination);
    void push(String location) => open(MallPush(location));

    final strings = MallStrings.of(context);
    final now = ref.read(mallClockProvider)();
    final seeAll = destinationForSeeAll(section);
    final onSeeAll = seeAll == null ? null : () => open(seeAll);
    final title = section.title ?? '';

    Widget titled(Widget child) => _Titled(
      section: section,
      index: index,
      meta: mallSectionMeta(section, strings),
      onSeeAll: onSeeAll,
      child: child,
    );

    return switch (section) {
      // ── Cinematic ──────────────────────────────────────────────────────
      HomeCampaignsSection(:final items) => _CampaignStage(
        campaigns: items,
        topInset: topInset,
        overline: overline,
        onOpen: open,
      ),
      HomeReelsSection(:final items) => titled(
        MallRail<HomeReel>(
          items: items,
          itemWidth: MallReelCard.regularWidth,
          height: MallReelCard.heightFor(MallReelCard.regularWidth),
          semanticLabel: title.isEmpty ? 'Shoppable reels' : title,
          itemBuilder: (context, reel, _) => MallReelCard(
            reel: reel.toVm(),
            // A rail card is a play mark: it opens the reel in the window
            // over the Mall, exactly as a product tile's does.
            onTap: () => unawaited(openMallReelWindow(context, reel.toRef())),
            onTaggedProductsTap: reel.taggedProductCount > 0
                ? () => unawaited(showReelProductsSheet(context, reel: reel))
                : null,
          ),
        ),
      ),

      // ── Bold retail, or dense discovery, decided by the data ───────────
      HomeProductsSection(:final items) => isDropBlock(items)
          ? _DropBlock(
              section: section,
              items: items,
              facts: MallDealFacts.from(items),
              strings: strings,
              now: now,
              onCta: onSeeAll,
              onOpenProduct: (id) => push(MallRoutes.product(id)),
            )
          : titled(
              _SignalRail(
                items: items,
                now: now,
                strings: strings,
                size: MallCardSize.compact,
                semanticLabel: title.isEmpty ? 'Products' : title,
                onOpenProduct: (id) => push(MallRoutes.product(id)),
              ),
            ),
      HomeCreatorsSection(:final items) => titled(
        MallRail<HomeCreator>(
          items: items,
          itemWidth: MallCreatorCard.defaultWidth,
          height: MallCreatorCard.heightFor(context, hasFollowAction: false),
          semanticLabel: title.isEmpty ? 'Creators' : title,
          itemBuilder: (_, creator, _) => MallCreatorCard(
            creator: creator.toVm(),
            onTap: () => push(MallRoutes.creator(creator.accountId)),
          ),
        ),
      ),

      // ── Editorial ──────────────────────────────────────────────────────
      HomeCollectionsSection(:final items) => titled(
        MallEditorialSpread(
          collections: [for (final item in items) item.toVm()],
          semanticLabel: title.isEmpty ? 'Collections' : title,
          onOpen: (collection) =>
              push(MallRoutes.collection(collection.id)),
        ),
      ),
      HomeBrandsSection(:final items) => titled(
        MallRail<HomeBrand>(
          items: items,
          itemWidth: MallBrandCard.defaultWidth,
          height: MallBrandCard.heightFor(
            context,
            width: MallBrandCard.defaultWidth,
          ),
          semanticLabel: title.isEmpty ? 'Brands' : title,
          itemBuilder: (_, brand, _) => MallBrandCard(
            brand: brand.toVm(),
            onTap: () =>
                push(MallRoutes.brand(brand.vendorAccountId, brand.name)),
          ),
        ),
      ),

      // ── Graphic ────────────────────────────────────────────────────────
      HomeCategoriesSection(:final items) => titled(
        MallCategoryMosaic(
          categories: [for (final item in items) item.toVm()],
          semanticLabel: title.isEmpty ? 'Categories' : title,
          onOpen: (category) {
            final source = items
                .where((item) => (item.id.isEmpty ? item.slug : item.id) ==
                    category.id)
                .firstOrNull;
            if (source != null) push(MallRoutes.category(source));
          },
        ),
      ),

      // ── The page's closing reassurance ─────────────────────────────────
      HomeTrustSection() => const _TrustBlock(),
    };
  }
}

/// A section header above its block. The personalisation reason, when the
/// server sent one, is the subtle subtitle.
class _Titled extends StatelessWidget {
  const _Titled({
    required this.section,
    required this.index,
    required this.meta,
    required this.onSeeAll,
    required this.child,
  });

  final HomeSection section;
  final int index;
  final List<MallSignal> meta;
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
            index: index > 0 ? index : null,
            meta: meta,
          ),
        child,
      ],
    );
  }
}

/// The cinematic stage, and the shared-element flight out of it.
class _CampaignStage extends StatelessWidget {
  const _CampaignStage({
    required this.campaigns,
    required this.topInset,
    required this.overline,
    required this.onOpen,
  });

  final List<HomeCampaign> campaigns;
  final double topInset;
  final Widget? overline;
  final void Function(MallDestination destination) onOpen;

  /// A campaign flies into its collection only when it actually leads to one.
  static bool _leadsToCollection(HomeCampaign campaign) => campaign.ctas.any(
    (cta) =>
        cta.targetKind == HomeCtaTargetKind.collection &&
        cta.targetValue.trim().isNotEmpty,
  );

  @override
  Widget build(BuildContext context) {
    return MallCinematicHero(
      campaigns: [for (final campaign in campaigns) campaign.toVm()],
      topInset: topInset,
      overline: overline,
      // Stops advancing while Home is hidden (Reels, another tab).
      autoAdvance: TickerMode.valuesOf(context).enabled,
      heroTagFor: (campaign) {
        final source = campaigns
            .where((item) => item.id == campaign.id)
            .firstOrNull;
        if (source == null || !_leadsToCollection(source)) return null;
        return mallCampaignHeroTag(source.id);
      },
      onAction: (campaign, action) {
        final source = campaigns
            .where((item) => item.id == campaign.id)
            .firstOrNull;
        final index = int.tryParse(action.id);
        if (source == null || index == null) return;
        if (index < 0 || index >= source.ctas.length) return;
        final cta = source.ctas[index];
        // Only the tagged campaign's collection CTA carries the flight.
        final tag = cta.targetKind == HomeCtaTargetKind.collection &&
                _leadsToCollection(source)
            ? mallCampaignHeroTag(source.id)
            : null;
        final destination = destinationForCta(cta, heroTag: tag);
        if (destination != null) onOpen(destination);
      },
    );
  }
}

/// A products block that really is a drop: the colour-blocked plate with the
/// block's own products running under it.
class _DropBlock extends StatelessWidget {
  const _DropBlock({
    required this.section,
    required this.items,
    required this.facts,
    required this.strings,
    required this.now,
    required this.onCta,
    required this.onOpenProduct,
  });

  final HomeSection section;
  final List<HomeProduct> items;
  final MallDealFacts facts;
  final MallStrings strings;
  final DateTime now;
  final VoidCallback? onCta;
  final void Function(String productId) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final title = section.title ?? '';
    return MallDealBand(
      title: title.isEmpty ? strings.shopTheDrop : title,
      eyebrow: section.eyebrow,
      subtitle: section.reason ?? section.subtitle,
      topDiscountPercent: facts.topDiscountPercent,
      endsUtc: facts.endsUtc,
      ctaLabel: onCta == null ? null : strings.shopTheDrop,
      onCta: onCta,
      now: () => now,
      child: _SignalRail(
        items: items,
        now: now,
        strings: strings,
        semanticLabel: title.isEmpty ? 'Deals' : title,
        onOpenProduct: onOpenProduct,
      ),
    );
  }
}

/// A product rail whose cards each carry one live fact.
///
/// The slot is reserved for the whole rail when any card has something to
/// say, so every card is exactly the height the rail was sized for.
class _SignalRail extends StatelessWidget {
  const _SignalRail({
    required this.items,
    required this.now,
    required this.strings,
    required this.semanticLabel,
    required this.onOpenProduct,
    this.size = MallCardSize.regular,
  });

  final List<HomeProduct> items;
  final DateTime now;
  final MallStrings strings;
  final String semanticLabel;
  final void Function(String productId) onOpenProduct;
  final MallCardSize size;

  @override
  Widget build(BuildContext context) {
    final width = size == MallCardSize.compact
        ? MallProductTile.compactWidth
        : MallProductTile.regularWidth;
    final withSignal = mallRailHasSignals(
      items,
      now: now,
      strings: strings,
    );
    return MallRail<HomeProduct>(
      items: items,
      itemWidth: width,
      height: MallProductTile.heightFor(
        context,
        width: width,
        size: size,
        withSignal: withSignal,
      ),
      semanticLabel: semanticLabel,
      itemBuilder: (context, product, _) => SaveableMallProductTile(
        product: product.toVm(),
        size: size,
        signal: mallProductSignal(product, now: now, strings: strings),
        reserveSignal: withSignal,
        onTap: () => onOpenProduct(product.id),
        onReelTap: (reel) => unawaited(openMallReelWindow(context, reel)),
      ),
    );
  }
}

/// The trust strip, set off by a hairline so the page closes rather than
/// simply stopping.
class _TrustBlock extends StatelessWidget {
  const _TrustBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: 16),
          child: ColoredBox(
            color: DesignTokens.bgAppBodyLight,
            child: SizedBox(height: 1),
          ),
        ),
        SizedBox(height: DesignTokens.s24),
        MallTrustStrip(),
      ],
    );
  }
}
