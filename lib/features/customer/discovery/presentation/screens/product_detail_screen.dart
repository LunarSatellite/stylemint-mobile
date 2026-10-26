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
import 'package:stylemint_mobile_frontend/features/customer/engagement/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
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
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/presentation/widgets/collab_product_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/presentation/widgets/product_matched_reels_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_save_button.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_signals_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/related_products_rail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/return_record_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/review_summary_block.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_from_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/presentation/widgets/group_buy_banner.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/rate_review_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/reel_review_thumbnail.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/review_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_choice.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_item_bar.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/item/service_item_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/presentation/widgets/try_on_entry_button.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    required this.productId,
    this.replaceLineId,
    this.reelTagContextId,
    super.key,
  });

  final String productId;

  /// The reel tag a stay or trip was opened from: its cart line is credited
  /// to the reel's creator.
  final String? reelTagContextId;

  /// A stay or trip opened from its cart line to change it: the page starts
  /// from that line's choice, and adding replaces the line.
  final String? replaceLineId;

  static const Key displayPriceKey = Key('product-display-price');

  /// The in-cart counter's number and its two steppers.
  static const Key cartCountKey = Key('product-cart-count');
  static const Key cartDecrementKey = Key('product-cart-decrement');
  static const Key cartIncrementKey = Key('product-cart-increment');
  static const Key addToCartKey = Key('product-add-to-cart');
  static const Key buyNowKey = Key('product-buy-now');

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  /// A cart write from this page is in flight: Add to cart, Buy now and the
  /// counter's steppers all wait for it, so a double tap cannot add twice.
  bool _cartBusy = false;
  final Map<String, String> _selectedVariants = {};
  bool _descExpanded = false;
  ProductOptionChooser? _chooser;
  String? _chooserProductId;

  /// Dates, room and guests (or departure and travellers) for a stay or trip
  /// — what a service item has in place of size and colour.
  ServiceChoice? _serviceChoice;
  String? _serviceChoiceProductId;

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
      // One id for the batch event and the per-signal call (AI features
      // contract §2.1), attributed to the reel of a recent tag tap.
      final eventId = ref
          .read(engagementTrackerProvider)
          .productViewed(widget.productId);
      ref
          .read(feedSignalRecorderProvider)
          .productViewed(widget.productId, clientEventId: eventId);
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

  /// The choice for a bookable stay or trip, kept across reloads of the same
  /// item; null for a product, a bank, or an item still being set up.
  ServiceChoice? _serviceChoiceFor(ProductDetail product) {
    final item = product.service;
    final bookable =
        item != null &&
        ((item.type == ServiceItemType.stay && item.stay != null) ||
            (item.type == ServiceItemType.package && item.package != null));
    if (item == null || !bookable) return null;
    final existing = _serviceChoice;
    if (existing != null && _serviceChoiceProductId == product.id) {
      return existing;
    }
    existing?.dispose();
    _serviceChoiceProductId = product.id;
    return _serviceChoice = ServiceChoice(
      item: item,
      today: kathmanduDay(ref.read(servicesClockProvider)()),
      from: _lineBeingReplaced(),
    );
  }

  /// The cart line this page was opened to change, when it is a service.
  ServiceLine? _lineBeingReplaced() {
    final lineId = widget.replaceLineId;
    if (lineId == null) return null;
    return ref
        .read(cartNotifierProvider)
        .maybeWhen(
          loadSuccess: (cart) {
            for (final i in cart.items) {
              if (i.id == lineId) return i.service;
            }
            return null;
          },
          orElse: () => null,
        );
  }

  @override
  void dispose() {
    _chooser?.dispose();
    _serviceChoice?.dispose();
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
          // What of this variant is in the cart, read from the cart itself
          // so it is right after a change made anywhere (the cart screen, a
          // reel, another visit) and after a restart once the cart loads.
          // The detail payload's `isInCart` is never sent (always false).
          final lines = _cartLinesFor(
            chosen,
            choiceResolved:
                chooser.value.isEmpty || chooser.value.resolvedVariant != null,
          );
          final inCart = lines.fold<int>(0, (sum, i) => sum + i.quantity);
          return _ProductBody(
            product: chosen,
            serviceChoice: _serviceChoiceFor(product),
            replaceLineId: widget.replaceLineId,
            reelTagContextId: widget.reelTagContextId,
            chooser: product.options.isEmpty ? null : chooser,
            cartQuantity: inCart,
            cartBusy: _cartBusy,
            // Several lines only when the page knows no variant: the total
            // shows, + adds the page's choice, and - is left to the cart.
            onCartDecrement: lines.length == 1
                ? () => unawaited(_changeCartQuantity(lines.single, -1))
                : null,
            onCartIncrement: lines.length == 1
                ? () => unawaited(_changeCartQuantity(lines.single, 1))
                : () => unawaited(_handleAddToCart(chosen)),
            selectedVariants: _selectedVariants,
            emiVariantId: _selectedSkuId(chosen) ?? chosen.defaultVariantId,
            descExpanded: _descExpanded,
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

  /// The SKU picked on the legacy chip row, when the product has one.
  String? _selectedSkuId(ProductDetail product) {
    for (final group in product.variants) {
      if (group.type != 'sku' || group.values.isEmpty) continue;
      final selectedValue = _selectedVariants[group.id] ?? group.values.first;
      return group.optionVariantIds[selectedValue];
    }
    return null;
  }

  /// The variant an add from this page sends: the legacy SKU chip's pick,
  /// else the chosen (or default) variant.
  String? _variantIdFor(ProductDetail product) =>
      _selectedSkuId(product) ?? product.defaultVariantId;

  /// The cart lines of the variant on screen. None while the size/colour
  /// choice names no variant yet: the counter would otherwise count the
  /// default variant under a choice that is not it.
  List<CartItem> _cartLinesFor(
    ProductDetail product, {
    required bool choiceResolved,
  }) {
    final cart = ref.watch(settledCartProvider);
    if (!choiceResolved || cart == null) return const <CartItem>[];
    return cart.productLines(product.id, variantId: _variantIdFor(product));
  }

  void _showCartError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: DesignTokens.colorError,
        ),
      );
  }

  /// Adds one unit of the variant on screen and brings the cart up to date.
  /// Returns whether it landed; a refusal says so here.
  Future<bool> _addOne(ProductDetail product) async {
    final success = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .addToCart(
          productId: widget.productId,
          qty: 1,
          variantId: _variantIdFor(product),
        );
    if (!mounted) return false;
    if (!success) {
      _showCartError("Couldn't add this item. Please try again.");
      return false;
    }
    ref.read(engagementTrackerProvider).addedToCart(widget.productId);
    // productDetailNotifierProvider.addToCart() writes through its own
    // Discovery-module repository, not the Cart module's. cartNotifierProvider
    // is a keepAlive singleton that only fetches once at construction, so
    // without this it keeps showing the cart as it was before this add (or
    // empty) until some other screen happens to mutate it. Confirmed live:
    // "Added to cart" showed, then Your Cart still said empty. Awaited, so
    // the counter replaces Add to cart as the confirmation shows.
    await ref.read(cartNotifierProvider.notifier).fetchCart();
    return mounted;
  }

  Future<void> _handleAddToCart(ProductDetail product) async {
    if (_cartBusy) return;
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;
    setState(() => _cartBusy = true);
    final added = await _addOne(product);
    if (!mounted) return;
    setState(() => _cartBusy = false);
    if (!added) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to cart'),
        backgroundColor: DesignTokens.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// The counter's - and +: one unit less or more of [line]; down from 1
  /// removes the line and the bar returns to Add to cart. The same cart
  /// writes the cart screen's steppers make. A refused change puts the
  /// previous number back, says so, and reloads the cart.
  Future<void> _changeCartQuantity(CartItem line, int delta) async {
    if (_cartBusy) return;
    final next = line.quantity + delta;
    final previous = ref.read(settledCartProvider);
    final notifier = ref.read(cartNotifierProvider.notifier);
    setState(() => _cartBusy = true);
    if (next <= 0) {
      await notifier.removeItem(line.id);
    } else {
      await notifier.updateItem(itemId: line.id, quantity: next);
    }
    if (!mounted) return;
    final failed = ref
        .read(cartNotifierProvider)
        .maybeWhen(loadFailure: (_) => true, orElse: () => false);
    if (failed) {
      ref.read(settledCartProvider.notifier).restore(previous);
      _showCartError("Couldn't update your cart. Please try again.");
      unawaited(notifier.fetchCart());
    }
    setState(() => _cartBusy = false);
  }

  /// Buy now opens the cart, never checkout: the buyer sees the whole cart
  /// before paying. The variant on screen is added (one unit) only when it
  /// is not in the cart yet; one already there keeps its quantity.
  Future<void> _handleBuyNow(ProductDetail product) async {
    if (_cartBusy) return;
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;
    setState(() => _cartBusy = true);
    final notifier = ref.read(cartNotifierProvider.notifier);
    // A cart that has not loaded yet (just after launch, or mid-request)
    // cannot say whether the item is there: load it first rather than risk
    // a second unit.
    var cart = ref
        .read(cartNotifierProvider)
        .maybeWhen<Cart?>(loadSuccess: (c) => c, orElse: () => null);
    if (cart == null) {
      await notifier.fetchCart();
      if (!mounted) return;
      cart = ref
          .read(cartNotifierProvider)
          .maybeWhen<Cart?>(loadSuccess: (c) => c, orElse: () => null);
    }
    final alreadyInCart =
        cart != null &&
        cart.productQuantity(product.id, variantId: _variantIdFor(product)) >
            0;
    if (!alreadyInCart && !await _addOne(product)) {
      if (mounted) setState(() => _cartBusy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _cartBusy = false);
    await context.push(RouteNames.cart);
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
    required this.cartQuantity,
    required this.cartBusy,
    required this.onCartIncrement,
    required this.selectedVariants,
    required this.descExpanded,
    required this.onVariantSelected,
    required this.onToggleDesc,
    required this.onAddToCart,
    required this.onBuyNow,
    this.chooser,
    this.emiVariantId,
    this.onCartDecrement,
    this.serviceChoice,
    this.replaceLineId,
    this.reelTagContextId,
  });

  final ProductDetail product;

  /// A stay or trip's choice; null for a product or a bank.
  final ServiceChoice? serviceChoice;
  final String? replaceLineId;
  final String? reelTagContextId;

  /// The variant on screen, for the "EMI from" line under the price.
  final String? emiVariantId;

  /// Null for a product with no options — the legacy SKU chips show instead.
  final ProductOptionChooser? chooser;

  /// Units of the variant on screen in the cart; 0 shows Add to cart.
  final int cartQuantity;

  /// A cart write from this page is in flight.
  final bool cartBusy;

  /// The counter's minus; null when it cannot step (several lines).
  final VoidCallback? onCartDecrement;
  final VoidCallback onCartIncrement;
  final Map<String, String> selectedVariants;
  final bool descExpanded;
  final void Function(String, String) onVariantSelected;
  final VoidCallback onToggleDesc;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final isService = product.isServiceItem;
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
                    // A stay, trip or bank product has no instalments, no
                    // delivery and no group buy: it is booked or enquired.
                    if (!isService) ...[
                      // Draws nothing unless the vendor offers EMI on this
                      // variant — and nothing at all on a pre-EMI server.
                      EmiFromLine(
                        offer: product.emi,
                        productId: product.id,
                        productName: product.name,
                        variantId: emiVariantId,
                        padding: const EdgeInsets.only(top: DesignTokens.s4),
                      ),
                      DeliveryEstimateLine(
                        delivery: product.delivery,
                        padding: const EdgeInsets.only(top: DesignTokens.s8),
                      ),
                      // Where the old random-number urgency banner sat. What
                      // stands here now is measured or it is not drawn at all
                      // — see the note below the build methods.
                      ProductSignalsSection(productId: product.id),
                      GroupBuyBanner(productId: product.id),
                    ],
                    const SizedBox(height: DesignTokens.s12),
                    _ExpandableBlock(
                      description: product.description,
                      specs: product.specifications,
                      expanded: descExpanded,
                      onToggle: onToggleDesc,
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    // In place of size and colour: dates, rooms and guests,
                    // a departure and travellers, or a bank's rates and
                    // branches (service items contract v1 §4).
                    if (isService) ...[
                      ServiceItemSection(
                        item: product.service,
                        choice: serviceChoice,
                      ),
                      const SizedBox(height: DesignTokens.s24),
                    ] else if (chooser case final ProductOptionChooser picker) ...[
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
                    // Premium AR try-on. Draws nothing unless the service is
                    // on and this product is set up for it.
                    if (!isService)
                      TryOnEntryButton(
                        productId: product.id,
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.s16,
                        ),
                      ),
                    _SoldByRow(
                      vendorName: product.vendorName,
                      vendorAvatarUrl: product.vendorAvatarUrl,
                      vendorId: product.vendorId,
                      productId: product.id,
                    ),
                    // Reels featuring, then like, this product (AI features
                    // contract §4.2); the tagged-reels rail on a server
                    // without it.
                    ProductMatchedReelsRail(
                      productId: product.id,
                      padding: const EdgeInsets.only(top: DesignTokens.s24),
                    ),
                    // Provenance, comparisons and return records are about
                    // goods; a stay, trip or bank product has none.
                    if (!isService) ...[
                      const SizedBox(height: DesignTokens.s12),
                      _PassportSection(productId: product.id),
                      const SizedBox(height: DesignTokens.s12),
                      ProductComparisonCard(productId: product.id),
                      const SizedBox(height: DesignTokens.s12),
                      ReturnRecordCard(productId: product.id),
                    ],
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
                      quickQuestions: EvidenceAnswerPanel.productQuestions,
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
                    // Collaborative filtering (AI features contract §3).
                    // Each draws nothing until other shoppers' aggregate
                    // behaviour produced neighbours.
                    if (!isService)
                      CollabProductRail(
                        productId: product.id,
                        relation: CollabProductRelation.boughtTogether,
                        padding: const EdgeInsets.only(top: DesignTokens.s24),
                      ),
                    CollabProductRail(
                      productId: product.id,
                      relation: CollabProductRelation.alsoViewed,
                      padding: const EdgeInsets.only(top: DesignTokens.s24),
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
          // A digital product this build may not sell gets no purchase bar at
          // all — not a disabled one. The page still loads, because a deep
          // link or a share can land here, and says why there is nothing to
          // press. See DigitalGoodsPolicy.
          child: isService
              ? _serviceBar(product)
              : DigitalGoodsPolicy.of(context).blocksPurchaseOf(
                  product.productKind,
                )
              ? const _UnavailableBar()
              : _BottomBar(
                  product: product,
                  cartQuantity: cartQuantity,
                  busy: cartBusy,
                  onCartDecrement: onCartDecrement,
                  onCartIncrement: onCartIncrement,
                  onAddToCart: onAddToCart,
                  onBuyNow: onBuyNow,
                ),
        ),
      ],
    );
  }
}

extension on _ProductBody {
  /// A stay or trip books through [ServiceItemBar]; a bank enquires through
  /// [BankItemBar]; an item still being set up has no bar.
  Widget _serviceBar(ProductDetail product) {
    final item = product.service;
    final bank = item?.bank;
    if (item?.type == ServiceItemType.bank && bank != null) {
      return BankItemBar(productId: product.id, bank: bank);
    }
    final choice = serviceChoice;
    if (choice == null || item == null || !item.addableToCart) {
      return const SizedBox.shrink();
    }
    return ServiceItemBar(
      productId: product.id,
      variantId: product.defaultVariantId,
      choice: choice,
      replaceLineId: replaceLineId,
      reelTagContextId: reelTagContextId,
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
    if (product.isServiceItem) return _servicePriceRow();
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

extension on _NamePriceRow {
  /// "from Rs 4,500/night", "Rs 45,000 per person", "Dates coming soon"; a
  /// bank shows no price (its rates are below). An older server without
  /// `displayPrice` shows the item's price as products do.
  Widget _servicePriceRow() {
    final label =
        product.displayPrice?.describe(serviceMoney) ??
        (product.serviceType == ServiceItemType.bank
            ? null
            : formatMoney(product.price));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: DesignTokens.titleMedium),
        if (label != null) ...[
          const SizedBox(height: DesignTokens.s8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              key: ProductDetailScreen.displayPriceKey,
              style: DesignTokens.moneyLarge,
            ),
          ),
        ],
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

/// Stands in for the purchase bar on a product this build may not sell.
///
/// Deliberately carries no action: no Add to Cart, no Buy Now, no price and
/// no link out. The product is simply not for sale in this app.
class _UnavailableBar extends StatelessWidget {
  const _UnavailableBar();

  static const notice = 'Not available for purchase in the app.';

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16 + bottomPad,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: DesignTokens.glassStroke),
      ),
      child: const Text(
        notice,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 13,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.cartQuantity,
    required this.busy,
    required this.onCartIncrement,
    required this.onAddToCart,
    required this.onBuyNow,
    this.onCartDecrement,
  });

  final ProductDetail product;

  /// Units of the variant on screen in the cart, from the cart itself.
  final int cartQuantity;

  /// A cart write is in flight: every control waits for it.
  final bool busy;
  final VoidCallback? onCartDecrement;
  final VoidCallback onCartIncrement;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final price = product.price;
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
      // Once the variant is in the cart, Add to cart turns into the cart's
      // own counter: - and + change the cart line, and down from 1 takes it
      // out and brings Add to cart back.
      child: cartQuantity > 0
          ? _InCartBar(
              total: formatMoney(
                Money(
                  amount: price.amount * cartQuantity,
                  currency: price.currency,
                ),
              ),
              quantity: cartQuantity,
              onDecrement: busy ? null : onCartDecrement,
              // An item that went out of stock stays countable, not addable.
              onIncrement: busy || !product.isInStock ? null : onCartIncrement,
              onBuyNow: busy ? null : onBuyNow,
            )
          : _DefaultBar(
              isInStock: product.isInStock,
              onAddToCart: busy ? null : onAddToCart,
              onBuyNow: busy ? null : onBuyNow,
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

  /// Null while a cart write is in flight.
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            key: ProductDetailScreen.addToCartKey,
            onPressed: isInStock ? onAddToCart : null,
            style: DesignTokens.outlinedButtonStyle(),
            child: Text(
              isInStock ? 'Add to Cart' : 'Out of Stock',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.mediumSemibold,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: ElevatedButton(
            key: ProductDetailScreen.buyNowKey,
            onPressed: isInStock ? onBuyNow : null,
            style: DesignTokens.primaryButtonStyle(),
            child: Text(
              'Buy Now',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    required this.total,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onBuyNow,
  });

  /// The unit price times [quantity], formatted.
  final String total;
  final int quantity;

  /// Null while a change is in flight (or when the page cannot step).
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final VoidCallback? onBuyNow;

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
              total,
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
              key: ProductDetailScreen.cartDecrementKey,
              icon: Icons.remove_rounded,
              semanticLabel: quantity > 1
                  ? 'One less in cart'
                  : 'Remove from cart',
              onTap: onDecrement,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
              ),
              child: Semantics(
                label: '$quantity in cart',
                excludeSemantics: true,
                child: Text(
                  '$quantity',
                  key: ProductDetailScreen.cartCountKey,
                  style: DesignTokens.mediumSemibold,
                ),
              ),
            ),
            _StepperButton(
              key: ProductDetailScreen.cartIncrementKey,
              icon: Icons.add_rounded,
              semanticLabel: 'One more in cart',
              onTap: onIncrement,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: ElevatedButton(
                key: ProductDetailScreen.buyNowKey,
                onPressed: onBuyNow,
                style: DesignTokens.primaryButtonStyle(),
                child: Text(
                  'Buy Now',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
  const _StepperButton({
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: _material(),
    );
  }

  Widget _material() {
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
