import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/widgets/evidence_answer_panel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_option_chooser.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/passport_claims_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_option_choosers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/delivery_estimate_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_badges_row.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_comparison_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_image_carousel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_reels_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_save_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_signals_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/related_products_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/return_record_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/review_summary_block.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/presentation/widgets/group_buy_banner.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/rate_review_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/reel_review_thumbnail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/review_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final Map<String, String> _selectedVariants = {};
  bool _descExpanded = false;
  ProductOptionChooser? _chooser;
  String? _chooserProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productDetailNotifierProvider(widget.productId).notifier)
          .loadProduct(widget.productId);
      _recordRecentlyViewed();
    });
  }

  /// Home's "Recently viewed" rail and the adaptive feed: one fire-and-forget
  /// post per open. Never blocks the page or shows an error.
  ///
  /// Both recorders gate themselves on the storefront-personalisation purpose
  /// — the global pause, a refused or undecided decision and an unreadable
  /// one all stop the write before the network is touched. The sign-in check
  /// below is only a cheap short-circuit; it is not the consent gate.
  void _recordRecentlyViewed() {
    if (!mounted) return;
    try {
      if (!ref.read(sessionControllerProvider).isAuthenticated) return;
      ref.read(recentlyViewedRecorderProvider).record(widget.productId);
      // Opening a product page is the clearest statement of intent the app
      // has, and the one the feed reads as "researching".
      ref.read(feedSignalRecorderProvider).productViewed(widget.productId);
    } on Object catch (_) {
      // Best effort only.
    }
  }

  /// The size/colour picks for [product], kept across reloads of the same
  /// product (Add to Cart refetches it). Products with no options get an
  /// empty selection that changes nothing on the page.
  ProductOptionChooser _chooserFor(ProductDetail product) {
    final existing = _chooser;
    if (existing != null && _chooserProductId == product.id) return existing;
    existing?.dispose();
    _chooserProductId = product.id;
    return _chooser = ProductOptionChooser.forProduct(product)
      ..addListener(_onChoiceChanged);
  }

  void _onChoiceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chooser?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailNotifierProvider(widget.productId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: state.when(
        initial: () => const _Loader(),
        loadInProgress: () => const _Loader(),
        loadSuccess: (product) {
          final chooser = _chooserFor(product);
          // Price, stock and the add-to-cart bar follow the picked variant.
          final chosen = chooser.value.applyTo(product);
          return _ProductBody(
            product: chosen,
            chooser: product.options.isEmpty ? null : chooser,
            quantity: _quantity,
            selectedVariants: _selectedVariants,
            descExpanded: _descExpanded,
            onQuantityChanged: (v) => setState(() => _quantity = v),
            onVariantSelected: (k, v) =>
                setState(() => _selectedVariants[k] = v),
            onToggleDesc: () => setState(() => _descExpanded = !_descExpanded),
            onAddToCart: () => _handleAddToCart(chosen),
            onBuyNow: () => _handleBuyNow(chosen),
          );
        },
        loadFailure: (_) => SmErrorView(
          message: 'Failed to load product.',
          onRetry: () => ref
              .read(productDetailNotifierProvider(widget.productId).notifier)
              .loadProduct(widget.productId),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(ProductDetail product) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;
    String? selectedSkuId;
    for (final group in product.variants) {
      if (group.type != 'sku' || group.values.isEmpty) continue;
      final selectedValue = _selectedVariants[group.id] ?? group.values.first;
      selectedSkuId = group.optionVariantIds[selectedValue];
      break;
    }
    final success = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .addToCart(
          productId: widget.productId,
          qty: _quantity,
          variantId: selectedSkuId ?? product.defaultVariantId,
        );
    if (success) {
      // productDetailNotifierProvider.addToCart() writes through its own
      // Discovery-module repository, not the Cart module's — cartNotifierProvider
      // is a keepAlive singleton that only fetches once at construction, so
      // without this it keeps showing the cart as it was before this add (or
      // empty) until some other screen happens to mutate it. Confirmed live:
      // "Added to cart" showed, then Your Cart still said empty.
      unawaited(ref.read(cartNotifierProvider.notifier).fetchCart());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart'),
            backgroundColor: DesignTokens.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleBuyNow(ProductDetail product) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;

    String? selectedSkuId;
    for (final group in product.variants) {
      if (group.type != 'sku' || group.values.isEmpty) continue;
      final selectedValue = _selectedVariants[group.id] ?? group.values.first;
      selectedSkuId = group.optionVariantIds[selectedValue];
      break;
    }

    final added = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .addToCart(
          productId: widget.productId,
          qty: _quantity,
          variantId: selectedSkuId ?? product.defaultVariantId,
        );
    if (!mounted) return;

    if (!added) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't add this item. Please try again."),
          backgroundColor: DesignTokens.colorError,
        ),
      );
      return;
    }

    // Same stale-cart issue as _handleAddToCart: refresh before navigating to
    // Checkout so it doesn't render off cartNotifierProvider's pre-add state.
    await ref.read(cartNotifierProvider.notifier).fetchCart();
    if (!mounted) return;
    await context.push(RouteNames.checkout);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const SmPageLoader();
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ProductBody extends StatelessWidget {
  const _ProductBody({
    required this.product,
    required this.quantity,
    required this.selectedVariants,
    required this.descExpanded,
    required this.onQuantityChanged,
    required this.onVariantSelected,
    required this.onToggleDesc,
    required this.onAddToCart,
    required this.onBuyNow,
    this.chooser,
  });

  final ProductDetail product;

  /// Null for a product with no options — the legacy SKU chips show instead.
  final ProductOptionChooser? chooser;
  final int quantity;
  final Map<String, String> selectedVariants;
  final bool descExpanded;
  final ValueChanged<int> onQuantityChanged;
  final void Function(String, String) onVariantSelected;
  final VoidCallback onToggleDesc;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 410,
              stretch: true,
              pinned: true,
              backgroundColor: DesignTokens.bgAppFoundation,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: DesignTokens.textWhite,
                ),
                onPressed: () => context.popOrHome(),
              ),
              actions: [
                ProductSaveButton(
                  productId: product.id,
                  variantId: product.defaultVariantId,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: DesignTokens.textWhite,
                  ),
                  onPressed: () => _shareProduct(product),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImageCarousel(images: product.images),
                    const Align(
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: DesignTokens.imageScrim,
                        ),
                        child: SizedBox(
                          height: DesignTokens.thumbSmall,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: DesignTokens.s12),
                    ProductBadgesRow(product: product),
                    const SizedBox(height: DesignTokens.s12),
                    _NamePriceRow(product: product),
                    DeliveryEstimateLine(
                      delivery: product.delivery,
                      padding: const EdgeInsets.only(top: DesignTokens.s8),
                    ),
                    // Where the old random-number urgency banner sat. What
                    // stands here now is measured or it is not drawn at all
                    // — see the note below the build methods.
                    ProductSignalsSection(productId: product.id),
                    GroupBuyBanner(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    _ExpandableBlock(
                      description: product.description,
                      specs: product.specifications,
                      expanded: descExpanded,
                      onToggle: onToggleDesc,
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    if (chooser case final ProductOptionChooser picker) ...[
                      ProductOptionChoosers(chooser: picker),
                      const SizedBox(height: DesignTokens.s16),
                    ] else if (product.variants.isNotEmpty) ...[
                      _VariantChips(
                        variants: product.variants,
                        selected: selectedVariants,
                        onSelected: onVariantSelected,
                      ),
                      const SizedBox(height: DesignTokens.s16),
                    ],
                    _SoldByRow(
                      vendorName: product.vendorName,
                      vendorAvatarUrl: product.vendorAvatarUrl,
                      vendorId: product.vendorId,
                      productId: product.id,
                    ),
                    ProductReelsRail(
                      productId: product.id,
                      padding: const EdgeInsets.only(top: DesignTokens.s24),
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _PassportSection(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    ProductComparisonCard(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    ReturnRecordCard(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    _FaqSection(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    // The FAQ above answers what a seller chose to write
                    // down. This answers what the records say, and shows
                    // them. Seeded with the product's own name so the first
                    // question is already about the thing on screen.
                    EvidenceAnswerPanel(
                      familyKey: product.id,
                      seedQuery: product.name,
                      currentProductId: product.id,
                    ),
                    const SizedBox(height: DesignTokens.s12),
                    _ReviewsSection(
                      productId: product.id,
                      reviewCount: product.reviewCount,
                    ),
                    const SizedBox(height: DesignTokens.s20),
                    _FromTheReelSection(
                      vendorName: product.vendorName,
                      vendorAvatarUrl: product.vendorAvatarUrl,
                    ),
                    RelatedProductsRail(
                      productId: product.id,
                      padding: const EdgeInsets.only(top: DesignTokens.s24),
                    ),
                    // Reserves space for the overlaid _BottomBar, whose own
                    // height grows with MediaQuery's bottom safe-area inset
                    // (see its padding) — without adding that same inset
                    // here, the last section sits under the bar on devices
                    // with a 3-button nav bar instead of gesture nav.
                    SizedBox(
                      height: 100 + MediaQuery.of(context).padding.bottom,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomBar(
            product: product,
            quantity: quantity,
            onQuantityChanged: onQuantityChanged,
            onAddToCart: onAddToCart,
            onBuyNow: onBuyNow,
          ),
        ),
      ],
    );
  }
}

void _shareProduct(ProductDetail product) {
  unawaited(
    SharePlus.instance.share(
      ShareParams(
        text:
            'Check out ${product.name} from ${product.vendorName} on '
            'Style Mint — ${formatMoney(product.price)}. '
            'Product ID: ${product.id}',
      ),
    ),
  );
}

// ── Product signals: what replaced the urgency banner ──────────────────────

// DO NOT RESTORE THE OLD URGENCY BANNER.
//
// `_UrgencyBanner` drew "Only 7 left · 5 people added to cart recently" from
// `GET /api/v1/customer/discover/products/{id}/urgency`, and that endpoint
// measured none of it. In lead360,
// StyleMint.Modules.Discovery/Service/SocialProofService/SocialProofService.cs
// used to return
//
//     var stockRemaining = _rng.Next(0, 100);
//     var cartAdds10Min  = _rng.Next(0, 15);
//
// so the figure a buyer read as scarcity was a fresh random number on every
// load, and it changed if they pulled to refresh.
//
// **That backend is now fixed**, and the fix was to delete the fabrications
// rather than zero them. `StockRemaining` and `CartAddsLast10Min` are gone
// from `UrgencyDto`; `RecentPurchases`, `AddedToCartToday`, `FriendNames`,
// `TrendingLabel` and `IsBackInStock` are gone from `SocialProofDto`. What
// the contract carries instead is measured: `UnitsSoldLast30Days` from the
// Orders module, the coarse `IsInStock` / `IsLowStock` pair from Catalog,
// `AverageRating` that is **null when there are no reviews**, and
// `ViewersRightNow` from a Redis counter that nothing writes yet — so it is
// null on every call in production today.
//
// `ProductSignalsSection` (presentation/widgets/product_signals_section.dart)
// draws those, each one only when it has a value behind it. Read its rules
// before adding anything to it. In particular:
//
//   * a null figure draws nothing — never a 0, never an empty bar;
//   * the stock signal stays coarse. The exact count exists in Catalog and
//     is deliberately not exposed: it is a vendor disclosure and a pressure
//     tactic. Do not reconstruct a number, a countdown or an "N left" line
//     from the booleans;
//   * no invented velocity. Nothing records cart-adds or "selling fast".

// ── Name + Price ──────────────────────────────────────────────────────────────

class _NamePriceRow extends StatelessWidget {
  const _NamePriceRow({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final unitLabel = product.variants.isNotEmpty
        ? '/${product.variants.first.name}'
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: DesignTokens.titleMedium),
        const SizedBox(height: DesignTokens.s8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Both prices shrink rather than truncate: an ellipsised price
            // reads as a different number.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${formatMoney(product.price)}$unitLabel',
                  style: DesignTokens.moneyLarge,
                ),
              ),
            ),
            if (product.compareAtPrice != null) ...[
              const SizedBox(width: DesignTokens.s8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${formatMoney(product.compareAtPrice!)}$unitLabel',
                    // Muted, not red: a struck-through original is history,
                    // not a fault.
                    style: DesignTokens.moneySmall.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ── Expandable Description + Accordions ───────────────────────────────────────

class _ExpandableBlock extends StatelessWidget {
  const _ExpandableBlock({
    required this.description,
    required this.specs,
    required this.expanded,
    required this.onToggle,
  });

  final String description;
  final Map<String, String> specs;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!expanded)
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: DesignTokens.mediumRegular,
          )
        else ...[
          Text(description, style: DesignTokens.mediumRegular),
          if (specs.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            _InfoAccordion(
              title: 'Key Information',
              specs: specs,
              initiallyExpanded: true,
            ),
            const SizedBox(height: DesignTokens.s8),
            _InfoAccordion(
              title: 'Other Information',
              specs: const {},
              initiallyExpanded: false,
            ),
          ],
        ],
        const SizedBox(height: DesignTokens.s4),
        GestureDetector(
          onTap: onToggle,
          child: Text(
            expanded ? 'Read less' : 'Read More',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoAccordion extends StatefulWidget {
  const _InfoAccordion({
    required this.title,
    required this.specs,
    required this.initiallyExpanded,
  });

  final String title;
  final Map<String, String> specs;
  final bool initiallyExpanded;

  @override
  State<_InfoAccordion> createState() => _InfoAccordionState();
}

class _InfoAccordionState extends State<_InfoAccordion> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              child: Row(
                children: [
                  Text(widget.title, style: DesignTokens.mediumSemibold),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: DesignTokens.iconLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.specs.isNotEmpty) ...[
            const Divider(height: 1, color: DesignTokens.borderDefault),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                children: widget.specs.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                e.key,
                                style: DesignTokens.smallRegular,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: DesignTokens.smallRegular.copyWith(
                                  color: DesignTokens.textLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Variant Chips ─────────────────────────────────────────────────────────────

class _VariantChips extends StatelessWidget {
  const _VariantChips({
    required this.variants,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductVariant> variants;
  final Map<String, String> selected;
  final void Function(String, String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: variants
          .map((v) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select ${v.name}',
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textLight,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: v.values
                        .map((val) {
                          // default-select first value if nothing chosen yet
                          final isSelected =
                              selected[v.id] == val ||
                              (selected[v.id] == null && v.values.first == val);
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: DesignTokens.s8,
                            ),
                            child: GestureDetector(
                              onTap: () => onSelected(v.id, val),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: DesignTokens.s16,
                                  vertical: DesignTokens.s8,
                                ),
                                decoration: isSelected
                                    ? DesignTokens.chipDecorationSelected()
                                    : DesignTokens.chipDecorationDefault(),
                                child: Text(
                                  val,
                                  style: DesignTokens.mediumSemibold.copyWith(
                                    color: isSelected
                                        ? DesignTokens.primaryGreen
                                        : DesignTokens.chipsDefaultText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            );
          })
          .toList(growable: false),
    );
  }
}

// ── Product passport ─────────────────────────────────────────────────────────

/// "Digital Product Passport and Authenticity Proof" — listing-level
/// provenance surfaced in-app. Renders nothing while loading or on error,
/// since this is a supplementary trust signal, never a blocking one.
class _PassportSection extends ConsumerWidget {
  const _PassportSection({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passport = ref
        .watch(productPassportProvider(productId))
        .asData
        ?.value;
    // Schema 2 can carry claims and coverage on a listing whose authenticity
    // statement is empty, and that payload is worth drawing: "nothing has
    // been recorded against this listing's passport" is an answer.
    if (passport == null ||
        (passport.authenticityStatement.isEmpty &&
            passport.subject == null &&
            passport.claims.isEmpty &&
            passport.coverage == null)) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passport.vendorIdentityVerified
                    ? Icons.verified_user
                    : Icons.info_outline,
                size: 20,
                color: passport.vendorIdentityVerified
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textMuted,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  'Product passport',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
              Text(
                'v${passport.schemaVersion}',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          if (passport.authenticityStatement.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              passport.authenticityStatement,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
          // Schema 2: what the passport identifies, the claims recorded
          // against the listing, and what is not recorded at all.
          PassportClaimsSection(passport: passport),
          if (passport.provenance.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            ...passport.provenance.map(
              (fact) => Padding(
                padding: const EdgeInsets.only(top: DesignTokens.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      fact.verified
                          ? Icons.check_circle_outline
                          : Icons.remove_circle_outline,
                      size: 14,
                      color: fact.verified
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                    ),
                    const SizedBox(width: DesignTokens.s6),
                    Expanded(
                      child: Text(
                        '${fact.label}: ${fact.value}',
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (passport.revision.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Revision ${passport.revision.substring(0, passport.revision.length > 10 ? 10 : passport.revision.length)}',
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── FAQ ───────────────────────────────────────────────────────────────────────

/// "Frequently Asked Questions" — Voyager "Autonomous SEO and Answer-Engine
/// Authority" surfaced in-app. Renders nothing while loading, on error, or
/// when the backend has no FAQ content, since this is a supplementary
/// section, never a blocking one.
class _FaqSection extends ConsumerWidget {
  const _FaqSection({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final faq = ref.watch(productFaqProvider(productId)).asData?.value;
    if (faq == null || faq.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Frequently Asked Questions',
          style: DesignTokens.sectionInnerTitle,
        ),
        const SizedBox(height: DesignTokens.s8),
        ...faq.map(
          (entry) => Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: DesignTokens.s8),
              title: Text(entry.question, style: DesignTokens.mediumSemibold),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    entry.answer,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sold By ───────────────────────────────────────────────────────────────────

class _SoldByRow extends ConsumerWidget {
  const _SoldByRow({
    required this.vendorName,
    required this.vendorAvatarUrl,
    required this.vendorId,
    required this.productId,
  });

  final String vendorName;
  final String vendorAvatarUrl;
  final String vendorId;
  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            // Opens the brand's storefront.
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              onTap: vendorId.isEmpty
                  ? null
                  : () => context.push(
                      RouteNames.brandStorefront.replaceFirst(
                        ':vendorAccountId',
                        Uri.encodeComponent(vendorId),
                      ),
                    ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    backgroundImage: vendorAvatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(vendorAvatarUrl)
                        : null,
                    child: vendorAvatarUrl.isEmpty
                        ? const Icon(
                            Icons.store_rounded,
                            color: DesignTokens.iconLight,
                            size: 18,
                          )
                        : null,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sold By', style: DesignTokens.smallRegular),
                        Text(vendorName, style: DesignTokens.mediumSemibold),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Unflexed, this button took the whole row at large text sizes and
          // collapsed the seller block to zero width, so "Sold By" and the
          // vendor name vanished. It now yields space and shrinks its label.
          Flexible(
            child: OutlinedButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => _AskQuestionDialog(
                  vendorId: vendorId,
                  productId: productId,
                ),
              ),
              style: DesignTokens.outlinedButtonStyle(),
              icon: const Icon(Icons.help_outline_rounded, size: 16),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Ask a question'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AskQuestionDialog extends ConsumerStatefulWidget {
  const _AskQuestionDialog({required this.vendorId, required this.productId});

  final String vendorId;
  final String productId;

  @override
  ConsumerState<_AskQuestionDialog> createState() => _AskQuestionDialogState();
}

class _AskQuestionDialogState extends ConsumerState<_AskQuestionDialog> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _controller.text.trim();
    if (question.isEmpty) {
      setState(() => _error = 'Please enter your question.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final either = await ref
        .read(supportRepositoryProvider)
        .openProductInquiry(
          vendorAccountId: widget.vendorId,
          question: question,
          productId: widget.productId,
        );
    if (!mounted) return;
    either.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = 'Failed to send your question. Please try again.';
      }),
      (_) {
        Navigator.pop(context);
        SmSnackbar.success(context, 'Question sent to the vendor!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: Text('Ask a Question', style: DesignTokens.sectionInnerTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            maxLines: 3,
            enabled: !_submitting,
            style: DesignTokens.bodyText,
            decoration: DesignTokens.inputDecoration(
              hintText: 'Ask the vendor about this product',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              _error!,
              style: DesignTokens.smallRegular.copyWith(color: Colors.red),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: Text(
            'Send',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Reviews Section (embedded preview with tabs) ──────────────────────────────

// ── Customer Reviews Section ──────────────────────────────────────────────────

class _ReviewsSection extends ConsumerStatefulWidget {
  const _ReviewsSection({required this.productId, required this.reviewCount});
  final String productId;
  final int reviewCount;

  @override
  ConsumerState<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<_ReviewsSection>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _reviewsRoute =>
      RouteNames.productReviews.replaceFirst(':productId', widget.productId);

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(reviewsNotifierProvider(widget.productId));

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              0,
            ),
            child: Row(
              children: [
                // Expanded in place of a Spacer: the heading carries the
                // review count, so it wraps instead of pushing the action
                // off the row.
                Expanded(
                  child: Text(
                    'Customer Reviews (${widget.reviewCount})',
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                GestureDetector(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: DesignTokens.bgAppBody,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(DesignTokens.cardRadius),
                      ),
                    ),
                    builder: (_) =>
                        RateReviewSheet(productId: widget.productId),
                  ),
                  child: Text(
                    'Add review',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          ReviewSummaryBlock(
            productId: widget.productId,
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s4,
            ),
          ),

          // ── tabs ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelStyle: DesignTokens.mediumSemibold,
              unselectedLabelStyle: DesignTokens.mediumRegular,
              labelColor: DesignTokens.primaryGreen,
              unselectedLabelColor: DesignTokens.textMuted,
              indicatorColor: DesignTokens.primaryGreen,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              padding: EdgeInsets.zero,
              tabs: const [
                Tab(text: 'Reel Reviews'),
                Tab(text: 'Written Reviews'),
              ],
            ),
          ),

          // ── content ─────────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _tabCtrl,
            builder: (_, __) {
              if (_tabCtrl.index == 0) {
                return _ReelReviewsContent(
                  state: reviewsState,
                  onSeeAll: () => context.push(_reviewsRoute),
                );
              }
              return _WrittenReviewsContent(
                state: reviewsState,
                onSeeAll: () => context.push(_reviewsRoute),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Reel tab ─────────────────────────────────────────────────────────────────

class _ReelReviewsContent extends StatelessWidget {
  const _ReelReviewsContent({required this.state, required this.onSeeAll});
  final ReviewsState state;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final reviews = state.maybeWhen(
      loadSuccess: (items, _, __, ___) => items
          .where(
            (review) =>
                review.kind == ReviewKind.reel &&
                Uri.tryParse(review.reelSourceUrl ?? '') != null,
          )
          .take(9)
          .toList(growable: false),
      orElse: () => const <Review>[],
    );
    return Column(
      children: [
        if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Text(
              'No reel reviews yet.',
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: reviews.length,
            itemBuilder: (_, index) =>
                ReelReviewThumbnail(review: reviews[index], compact: true),
          ),

        // ── See all reviews button ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s12,
            DesignTokens.s12,
            DesignTokens.s12,
            DesignTokens.s16,
          ),
          child: GestureDetector(
            onTap: onSeeAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              alignment: Alignment.center,
              child: Text(
                'See all reviews',
                style: DesignTokens.mediumSemibold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Written tab ───────────────────────────────────────────────────────────────

class _WrittenReviewsContent extends StatelessWidget {
  const _WrittenReviewsContent({required this.state, required this.onSeeAll});
  final ReviewsState state;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s12,
        DesignTokens.s8,
        DesignTokens.s12,
        DesignTokens.s16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          state.when(
            initial: () => const SizedBox.shrink(),
            loadInProgress: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.s24),
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
            loadSuccess: (reviews, _, __, ___) {
              final writtenReviews = reviews
                  .where((review) => review.kind == ReviewKind.written)
                  .toList(growable: false);
              if (writtenReviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.s16,
                  ),
                  child: Text(
                    'No written reviews yet.',
                    style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                );
              }
              return Column(
                children: writtenReviews
                    .take(3)
                    .map((r) => ReviewCard(review: r))
                    .toList(growable: false),
              );
            },
            loadFailure: (_) => const SizedBox.shrink(),
          ),
          const SizedBox(height: DesignTokens.s8),
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              alignment: Alignment.center,
              child: Text(
                'See all reviews',
                style: DesignTokens.mediumSemibold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── From the Reel ─────────────────────────────────────────────────────────────

// ponytail: shows vendor info as placeholder — wire to product.featuredReel when entity has it
class _FromTheReelSection extends StatelessWidget {
  const _FromTheReelSection({
    required this.vendorName,
    required this.vendorAvatarUrl,
  });

  final String vendorName;
  final String vendorAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From the Reel', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s8),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: DesignTokens.cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: DesignTokens.bgAppBodyLight,
                backgroundImage: vendorAvatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(vendorAvatarUrl)
                    : null,
                child: vendorAvatarUrl.isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        color: DesignTokens.iconLight,
                      )
                    : null,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$vendorName',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                    Text(
                      'Check out the latest reel featuring this product...',
                      style: DesignTokens.smallRegular,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.iconLight,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final ProductDetail product;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s12 + bottomPad,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: DesignTokens.glassStroke),
        boxShadow: DesignTokens.shadowLifted,
      ),
      child: product.isInCart
          ? _InCartBar(
              price: formatMoney(product.price),
              quantity: quantity,
              onQuantityChanged: onQuantityChanged,
              onBuyNow: onBuyNow,
            )
          : _DefaultBar(
              isInStock: product.isInStock,
              onAddToCart: onAddToCart,
              onBuyNow: onBuyNow,
            ),
    );
  }
}

class _DefaultBar extends StatelessWidget {
  const _DefaultBar({
    required this.isInStock,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final bool isInStock;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isInStock ? onAddToCart : null,
            style: DesignTokens.outlinedButtonStyle(),
            child: Text(
              isInStock ? 'Add to Cart' : 'Out of Stock',
              style: DesignTokens.mediumSemibold,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: ElevatedButton(
            onPressed: isInStock ? onBuyNow : null,
            style: DesignTokens.primaryButtonStyle(),
            child: Text(
              'Buy Now',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.buttonPrimaryText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InCartBar extends StatelessWidget {
  const _InCartBar({
    required this.price,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onBuyNow,
  });

  final String price;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    // Two lines, not one: the amount reads on its own row and the controls
    // get the full width beneath it. A single Row could not hold a quiet
    // label, a price, two 44dp steppers and a CTA at 320dp x 1.3 — it
    // overflowed by 117px.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s4,
          children: [
            Text('Item Total', style: DesignTokens.smallRegular),
            Text(
              price,
              style: DesignTokens.moneyLarge.copyWith(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            _StepperButton(
              icon: Icons.remove_rounded,
              onTap: quantity > 1
                  ? () => onQuantityChanged(quantity - 1)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
              ),
              child: Text('$quantity', style: DesignTokens.mediumSemibold),
            ),
            _StepperButton(
              icon: Icons.add_rounded,
              onTap: () => onQuantityChanged(quantity + 1),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: ElevatedButton(
                onPressed: onBuyNow,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Buy Now',
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap != null
          ? DesignTokens.bgAppBodyLight
          : DesignTokens.bgAppBody,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        side: const BorderSide(color: DesignTokens.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          // 32dp was a hairline target; iOS HIG floor is 44.
          width: DesignTokens.minTouchTarget,
          height: DesignTokens.minTouchTarget,
          child: Icon(
            icon,
            size: DesignTokens.iconSmall,
            color: onTap != null
                ? DesignTokens.textWhite
                : DesignTokens.iconLight,
          ),
        ),
      ),
    );
  }
}
