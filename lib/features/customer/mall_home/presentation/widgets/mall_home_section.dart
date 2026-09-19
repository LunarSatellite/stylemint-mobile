import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_cart_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_view_mappers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_zones.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/widgets/reel_products_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/reel_window.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/saved_products_providers.dart';
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
    this.showSpotlight = false,
  });

  final HomeSection section;

  /// 1-based block number for the section marker; 0 hides the marker.
  final int index;

  /// Whether this block leads with the page's one spotlight. Decided for the
  /// whole page by `spotlightSectionIndex`, not by the block itself.
  final bool showSpotlight;

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

    // One cart write for the whole page: the same path the product details
    // page and Buy It Again take, gated for guests, reported back so the buy
    // control can show its own result.
    // The variant goes over the wire explicitly: the card already told us
    // which one the server would have picked, so nothing is left implicit.
    // Only products the card cleared reach here — the buy control on a
    // product needing a size opens its page instead.
    Future<bool> addToBag(HomeProduct product) => mallAddToBag(
      context,
      ref,
      productId: product.id,
      productName: product.name,
      variantId: product.defaultVariantId,
    );

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
          height: MallRail.heightForStaggered(
            MallReelCard.heightFor(MallReelCard.regularWidth),
          ),
          // The discovery zone's rails sit off the line; the editorial
          // zone's brand and creator rails stay flush, so the two read as
          // different densities of the same page rather than one rhythm.
          stagger: MallRail.defaultStagger,
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
      HomeProductsSection(:final items) =>
        isDropBlock(items)
            ? _DropBlock(
                section: section,
                items: items,
                facts: MallDealFacts.from(items),
                strings: strings,
                now: now,
                onCta: onSeeAll,
                onOpenProduct: (id) => push(MallRoutes.product(id)),
                onAddToBag: addToBag,
              )
            : titled(
                _ShoppableProducts(
                  items: items,
                  pick: showSpotlight ? spotlightPickOf(items) : null,
                  now: now,
                  strings: strings,
                  semanticLabel: title.isEmpty ? 'Products' : title,
                  onOpenProduct: (id) => push(MallRoutes.product(id)),
                  onAddToBag: addToBag,
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
          onOpen: (collection) => push(MallRoutes.collection(collection.id)),
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
                .where(
                  (item) =>
                      (item.id.isEmpty ? item.slug : item.id) == category.id,
                )
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
      onReel: (campaign) {
        final reelId = campaign.reelId?.trim();
        if (reelId == null || reelId.isEmpty) return;
        onOpen(MallPush(MallRoutes.reel(reelId)));
      },
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
        final tag =
            cta.targetKind == HomeCtaTargetKind.collection &&
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
    required this.onAddToBag,
  });

  final HomeSection section;
  final List<HomeProduct> items;
  final MallDealFacts facts;
  final MallStrings strings;
  final DateTime now;
  final VoidCallback? onCta;
  final void Function(String productId) onOpenProduct;
  final Future<bool> Function(HomeProduct product) onAddToBag;

  @override
  Widget build(BuildContext context) {
    final title = section.title ?? '';
    String? promoImageUrl;
    for (final product in items) {
      final candidate = product.imageUrl?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        promoImageUrl = candidate;
        break;
      }
    }
    return MallDealBand(
      title: title.isEmpty ? strings.shopTheDrop : title,
      eyebrow: section.eyebrow,
      subtitle: section.reason ?? section.subtitle,
      backgroundImageUrl: promoImageUrl,
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
        onAddToBag: onAddToBag,
      ),
    );
  }
}

/// A discovery products block: the spotlight, where the page gave this block
/// the one it has, and the rest of the items as a signal rail underneath.
///
/// A block holding a single product shows the spotlight alone rather than a
/// rail of one — the catalogue is small today, and a composition that admits
/// it reads as a decision instead of as missing content.
class _ShoppableProducts extends StatelessWidget {
  const _ShoppableProducts({
    required this.items,
    required this.pick,
    required this.now,
    required this.strings,
    required this.semanticLabel,
    required this.onOpenProduct,
    required this.onAddToBag,
  });

  final List<HomeProduct> items;
  final MallSpotlightPick? pick;
  final DateTime now;
  final MallStrings strings;
  final String semanticLabel;
  final void Function(String productId) onOpenProduct;
  final Future<bool> Function(HomeProduct product) onAddToBag;

  @override
  Widget build(BuildContext context) {
    final featured = pick;
    if (featured == null) {
      return _SignalRail(
        items: items,
        now: now,
        strings: strings,
        size: MallCardSize.compact,
        semanticLabel: semanticLabel,
        onOpenProduct: onOpenProduct,
        onAddToBag: onAddToBag,
      );
    }
    final rest = [
      for (final product in items)
        if (product.id != featured.product.id) product,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Spotlight(
          pick: featured,
          now: now,
          strings: strings,
          onOpenProduct: onOpenProduct,
          onAddToBag: onAddToBag,
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s24),
          _SignalRail(
            items: rest,
            now: now,
            strings: strings,
            size: MallCardSize.compact,
            semanticLabel: semanticLabel,
            onOpenProduct: onOpenProduct,
            onAddToBag: onAddToBag,
          ),
        ],
      ],
    );
  }
}

/// The spotlight, wired to the shared saved list, the reel window and the
/// cart. Narrow by design: only the heart's own state is watched here.
class _Spotlight extends ConsumerWidget {
  const _Spotlight({
    required this.pick,
    required this.now,
    required this.strings,
    required this.onOpenProduct,
    required this.onAddToBag,
  });

  final MallSpotlightPick pick;
  final DateTime now;
  final MallStrings strings;
  final void Function(String productId) onOpenProduct;
  final Future<bool> Function(HomeProduct product) onAddToBag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = pick.product;
    final saved = ref.watch(
      savedProductsNotifierProvider.select((s) => s.isSaved(product.id)),
    );
    return MallSpotlight(
      product: mallProductWithSaved(product.toVm(), saved: saved),
      eyebrow: mallSpotlightEyebrow(pick.reason, strings),
      signal: mallProductSignal(product, now: now, strings: strings),
      endsUtc: product.saleEndsUtc,
      now: () => now,
      onTap: () => onOpenProduct(product.id),
      onReelTap: (reel) => unawaited(openMallReelWindow(context, reel)),
      onSaveTap: () => unawaited(
        toggleSavedProduct(context, ref, productId: product.id),
      ),
      onQuickAdd: () => onAddToBag(product),
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
    required this.onAddToBag,
    this.size = MallCardSize.regular,
  });

  final List<HomeProduct> items;
  final DateTime now;
  final MallStrings strings;
  final String semanticLabel;
  final void Function(String productId) onOpenProduct;
  final Future<bool> Function(HomeProduct product) onAddToBag;
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
    // One tile for every Mall rail. The rail used to take a photo-card
    // flag and every call site passed true, so the drop plate and both
    // discovery rails were `MallProductCard` — catalogue photos on the Mall
    // home, which the owner directive of 2026-09-16 and this kit's README
    // both rule out. The flag is gone rather than defaulted, so the Mall
    // cannot quietly become a photo grid again.
    final cardHeight = MallProductTile.heightFor(
      context,
      width: width,
      size: size,
      withSignal: withSignal,
      withAction: true,
    );
    return MallRail<HomeProduct>(
      items: items,
      itemWidth: width,
      height: MallRail.heightForStaggered(cardHeight),
      stagger: MallRail.defaultStagger,
      semanticLabel: semanticLabel,
      itemBuilder: (context, product, _) {
        final card = product.toVm();
        final signal = mallProductSignal(
          product,
          now: now,
          strings: strings,
        );
        return SaveableMallProductTile(
          product: card,
          size: size,
          signal: signal,
          reserveSignal: withSignal,
          onTap: () => onOpenProduct(product.id),
          onReelTap: (reel) => unawaited(openMallReelWindow(context, reel)),
          onQuickAdd: () => onAddToBag(product),
        );
      },
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
