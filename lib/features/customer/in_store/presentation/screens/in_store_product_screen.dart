import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_image_carousel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/widgets/product_reels_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/review_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `/in-store/product/{productId}` — a product scanned off a shelf card or
/// NFC tag: photos, price, which store it's in, reels that show it, reviews,
/// and Add to cart / Save for later. Uses the same product, cart and saved
/// items state as the full product page.
class InStoreProductScreen extends ConsumerStatefulWidget {
  const InStoreProductScreen({
    required this.productId,
    this.storeId,
    this.code,
    this.storeName,
    this.storeCity,
    super.key,
  });

  final String productId;
  final String? storeId;

  /// The code that was scanned, when opened from one.
  final String? code;
  final String? storeName;
  final String? storeCity;

  /// The banner line: `In {store}, {city}`.
  static String storeBannerText({String? storeName, String? storeCity}) {
    final store = storeName?.trim() ?? '';
    final city = storeCity?.trim() ?? '';
    if (store.isEmpty) {
      return city.isEmpty ? 'Scanned in store' : 'In a store in $city';
    }
    return city.isEmpty ? 'In $store' : 'In $store, $city';
  }

  @override
  ConsumerState<InStoreProductScreen> createState() =>
      _InStoreProductScreenState();
}

class _InStoreProductScreenState extends ConsumerState<InStoreProductScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(productDetailNotifierProvider(widget.productId).notifier)
            .loadProduct(widget.productId),
      );
    });
  }

  /// Size, colour and the like are chosen on the full product page.
  static bool _needsChoice(ProductDetail product) =>
      product.variants.any((group) => group.values.length > 1);

  static String? _variantFor(ProductDetail product) {
    for (final group in product.variants) {
      if (group.type != 'sku' || group.values.isEmpty) continue;
      return group.optionVariantIds[group.values.first] ??
          product.defaultVariantId;
    }
    return product.defaultVariantId;
  }

  Future<void> _addToCart(ProductDetail product) async {
    if (_needsChoice(product)) {
      SmSnackbar.info(context, 'Choose an option first.');
      unawaited(
        context.push(
          RouteNames.productDetail.replaceFirst(':productId', product.id),
        ),
      );
      return;
    }
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;
    if (!await ensureProfile(context, ref, [ProfileField.shippingAddress])) {
      return;
    }
    if (!mounted) return;
    final added = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .addToCart(
          productId: product.id,
          qty: 1,
          variantId: _variantFor(product),
        );
    if (!mounted) return;
    if (!added) {
      SmSnackbar.error(context, "Couldn't add this item. Please try again.");
      return;
    }
    // The cart keeps its own copy; refresh it, as the product page does.
    unawaited(ref.read(cartNotifierProvider.notifier).fetchCart());
    SmSnackbar.success(context, 'Added to cart');
  }

  Future<void> _toggleSave(ProductDetail product) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.save)) return;
    if (!mounted) return;
    final saved = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .toggleSave(product.id);
    if (!mounted) return;
    if (!saved) {
      SmSnackbar.error(context, "Couldn't save this item. Please try again.");
      return;
    }
    unawaited(ref.read(savedItemsNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailNotifierProvider(widget.productId));
    return state.when(
      initial: () => const _Frame(child: SmPageLoader()),
      loadInProgress: () => const _Frame(child: SmPageLoader()),
      loadSuccess: (product) => Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        body: _InStoreProductBody(
          product: product,
          bannerText: InStoreProductScreen.storeBannerText(
            storeName: widget.storeName,
            storeCity: widget.storeCity,
          ),
          onAddToCart: () => unawaited(_addToCart(product)),
          onToggleSave: () => unawaited(_toggleSave(product)),
        ),
      ),
      loadFailure: (_) => _Frame(
        child: SmErrorView(
          message: 'Failed to load this product.',
          onRetry: () => unawaited(
            ref
                .read(productDetailNotifierProvider(widget.productId).notifier)
                .loadProduct(widget.productId),
          ),
        ),
      ),
    );
  }
}

/// A plain page with a back button, for loading and errors.
class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DesignTokens.bgAppFoundation,
    appBar: AppBar(
      backgroundColor: DesignTokens.bgAppFoundation,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: DesignTokens.textWhite,
        ),
        onPressed: () => context.popOrHome(),
      ),
    ),
    body: child,
  );
}

class _InStoreProductBody extends StatelessWidget {
  const _InStoreProductBody({
    required this.product,
    required this.bannerText,
    required this.onAddToCart,
    required this.onToggleSave,
  });

  final ProductDetail product;
  final String bannerText;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final compareAt = product.compareAtPrice;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 360,
              pinned: true,
              backgroundColor: DesignTokens.bgAppFoundation,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: DesignTokens.textWhite,
                ),
                onPressed: () => context.popOrHome(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: ProductImageCarousel(images: product.images),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s12,
                DesignTokens.s16,
                // Room for the bottom bar, which grows with the inset.
                100 + bottomInset,
              ),
              sliver: SliverList.list(
                children: [
                  _StoreBanner(text: bannerText),
                  const SizedBox(height: DesignTokens.s12),
                  Text(
                    product.name,
                    style: DesignTokens.titleMedium.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: DesignTokens.s6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatMoney(product.price),
                        style: DesignTokens.oneLinerSemibold,
                      ),
                      if (compareAt != null) ...[
                        const SizedBox(width: DesignTokens.s8),
                        Text(
                          formatMoney(compareAt),
                          style: DesignTokens.smallRegular.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s24),
                  ProductReelsSection(productId: product.id),
                  const SizedBox(height: DesignTokens.s24),
                  _ReviewsSummary(productId: product.id),
                  const SizedBox(height: DesignTokens.s8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => unawaited(
                        context.push(
                          RouteNames.productDetail.replaceFirst(
                            ':productId',
                            product.id,
                          ),
                        ),
                      ),
                      style: DesignTokens.textButtonStyle(),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text('See full product details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomBar(
            product: product,
            bottomInset: bottomInset,
            onAddToCart: onAddToCart,
            onToggleSave: onToggleSave,
          ),
        ),
      ],
    );
  }
}

class _StoreBanner extends StatelessWidget {
  const _StoreBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s12,
      vertical: DesignTokens.s8,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreenDark,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      border: Border.all(color: DesignTokens.chipsSelectedBorder),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.storefront_rounded,
          size: 18,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            text,
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReviewsSummary extends ConsumerWidget {
  const _ReviewsSummary({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewsNotifierProvider(productId));
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Reviews', style: DesignTokens.sectionInnerTitle),
              const Spacer(),
              TextButton(
                onPressed: () => unawaited(
                  context.push(
                    RouteNames.productReviews.replaceFirst(
                      ':productId',
                      productId,
                    ),
                  ),
                ),
                style: DesignTokens.textButtonStyle(),
                child: const Text('See all'),
              ),
            ],
          ),
          state.maybeWhen(
            loadSuccess: (reviews, summary, _, _) =>
                _ReviewsContent(reviews: reviews, summary: summary),
            loadFailure: (_) => Text(
              "Couldn't load reviews.",
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            orElse: () =>
                const SizedBox(height: 48, child: SmPageLoader(size: 32)),
          ),
        ],
      ),
    );
  }
}

class _ReviewsContent extends StatelessWidget {
  const _ReviewsContent({required this.reviews, required this.summary});

  final List<Review> reviews;
  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final count = summary.totalReviews > 0
        ? summary.totalReviews
        : reviews.length;
    if (count == 0) {
      return Text(
        'No reviews yet.',
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      );
    }
    final written = reviews
        .where((review) => review.kind == ReviewKind.written)
        .take(2)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              size: 20,
              color: DesignTokens.secondaryYellow,
            ),
            const SizedBox(width: DesignTokens.s4),
            Text(
              summary.averageRating.toStringAsFixed(1),
              style: DesignTokens.oneLinerSemibold,
            ),
            const SizedBox(width: DesignTokens.s8),
            Text(
              count == 1 ? '1 review' : '$count reviews',
              style: DesignTokens.smallRegular,
            ),
          ],
        ),
        for (final review in written) ...[
          const SizedBox(height: DesignTokens.s12),
          ReviewCard(review: review),
        ],
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.product,
    required this.bottomInset,
    required this.onAddToCart,
    required this.onToggleSave,
  });

  final ProductDetail product;
  final double bottomInset;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      DesignTokens.s16,
      DesignTokens.s12,
      DesignTokens.s16,
      DesignTokens.s12 + bottomInset,
    ),
    decoration: const BoxDecoration(
      color: DesignTokens.bgAppBody,
      border: Border(
        top: BorderSide(color: DesignTokens.borderDefault, width: 0.5),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onToggleSave,
            style: DesignTokens.outlinedButtonStyle(),
            icon: Icon(
              product.isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: product.isSaved
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textWhite,
            ),
            label: Text(product.isSaved ? 'Saved' : 'Save for later'),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: ElevatedButton(
            onPressed: product.isInStock ? onAddToCart : null,
            style: DesignTokens.primaryButtonStyle(),
            child: Text(product.isInStock ? 'Add to cart' : 'Out of stock'),
          ),
        ),
      ],
    ),
  );
}
