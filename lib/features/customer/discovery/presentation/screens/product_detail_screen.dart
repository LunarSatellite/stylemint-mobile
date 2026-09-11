import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_image_carousel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/presentation/widgets/group_buy_banner.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/notifiers/reviews_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/rate_review_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/presentation/widgets/review_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/support/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(productDetailNotifierProvider(widget.productId).notifier)
          .loadProduct(widget.productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailNotifierProvider(widget.productId));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: state.when(
        initial: () => const _Loader(),
        loadInProgress: () => const _Loader(),
        loadSuccess: (product) => _ProductBody(
          product: product,
          quantity: _quantity,
          selectedVariants: _selectedVariants,
          descExpanded: _descExpanded,
          onQuantityChanged: (v) => setState(() => _quantity = v),
          onVariantSelected: (k, v) => setState(() => _selectedVariants[k] = v),
          onToggleDesc: () => setState(() => _descExpanded = !_descExpanded),
          onAddToCart: () => _handleAddToCart(product),
          onBuyNow: () => _handleBuyNow(product),
          onToggleSave: () => _handleToggleSave(),
        ),
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
    if (!await ensureProfile(context, ref, [ProfileField.shippingAddress]))
      return;
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

  Future<void> _handleToggleSave() async {
    final success = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .toggleSave(widget.productId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save this item. Please try again."),
          backgroundColor: DesignTokens.colorError,
        ),
      );
      return;
    }
    // Profile's Saved Items screen (and its stats-row count) reads from a
    // singleton provider that only ever fetched once at first access —
    // without this it silently kept showing whatever it loaded before this
    // save/unsave happened, even though the backend was updated correctly.
    if (success) {
      ref.read(savedItemsNotifierProvider.notifier).load();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
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
    required this.onToggleSave,
  });

  final ProductDetail product;
  final int quantity;
  final Map<String, String> selectedVariants;
  final bool descExpanded;
  final ValueChanged<int> onQuantityChanged;
  final void Function(String, String) onVariantSelected;
  final VoidCallback onToggleDesc;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
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
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: DesignTokens.textWhite,
                ),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    product.isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: product.isSaved
                        ? DesignTokens.colorError
                        : DesignTokens.textWhite,
                  ),
                  onPressed: onToggleSave,
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
                background: ProductImageCarousel(images: product.images),
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
                    _BadgesRow(product: product),
                    const SizedBox(height: DesignTokens.s12),
                    _NamePriceRow(product: product),
                    const SizedBox(height: DesignTokens.s12),
                    _UrgencyBanner(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    GroupBuyBanner(productId: product.id),
                    const SizedBox(height: DesignTokens.s12),
                    _ExpandableBlock(
                      description: product.description,
                      specs: product.specifications,
                      expanded: descExpanded,
                      onToggle: onToggleDesc,
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    if (product.variants.isNotEmpty) ...[
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

// ── Urgency banner ──────────────────────────────────────────────────────────

/// Shows a low-stock / high-activity nudge from the PDP urgency-signals
/// endpoint. Renders nothing while loading, on error, or when neither
/// signal is meaningfully urgent — this is a passive upsell, never a
/// blocking or error-surfacing element.
class _UrgencyBanner extends ConsumerWidget {
  const _UrgencyBanner({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgency = ref.watch(productUrgencyProvider(productId)).asData?.value;
    if (urgency == null) return const SizedBox.shrink();

    final parts = <String>[];
    if (urgency.stockRemaining > 0 && urgency.stockRemaining <= 10) {
      parts.add('Only ${urgency.stockRemaining} left');
    }
    if (urgency.cartAddsLast10Min >= 3) {
      parts.add('${urgency.cartAddsLast10Min} people added to cart recently');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s8,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.colorError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 16,
            color: DesignTokens.colorError,
          ),
          const SizedBox(width: DesignTokens.s8),
          Flexible(
            child: Text(
              parts.join(' · '),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    final discountPct =
        product.compareAtPrice != null && product.compareAtPrice!.amount > 0
        ? ((1 - product.price.amount / product.compareAtPrice!.amount) * 100)
              .round()
        : null;

    return Wrap(
      spacing: DesignTokens.s8,
      runSpacing: DesignTokens.s6,
      children: [
        _Badge(
          icon: Icons.star_rounded,
          iconColor: DesignTokens.secondaryYellow,
          label: '${product.rating.toStringAsFixed(1)} Stars',
        ),
        const _Badge(
          icon: Icons.local_shipping_outlined,
          iconColor: DesignTokens.primaryGreen,
          label: 'Free Delivery',
        ),
        if (discountPct != null && discountPct > 0)
          _Badge(
            icon: Icons.sell_outlined,
            iconColor: DesignTokens.primaryGreen,
            label: '$discountPct% Off',
          ),
        if (product.flashSaleEndsAt != null)
          _Badge(
            icon: Icons.bolt_rounded,
            iconColor: DesignTokens.colorError,
            label: 'Flash Sale · ends ${_formatCountdown(product.flashSaleEndsAt!)}',
          ),
      ],
    );
  }

  static String _formatCountdown(DateTime endsAt) {
    final remaining = endsAt.difference(DateTime.now());
    if (remaining.isNegative) return 'soon';
    if (remaining.inHours >= 1) return 'in ${remaining.inHours}h';
    if (remaining.inMinutes >= 1) return 'in ${remaining.inMinutes}m';
    return 'now';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: DesignTokens.s4),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

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
              '${formatMoney(product.price)}$unitLabel',
              style: DesignTokens.oneLinerSemibold,
            ),
            if (product.compareAtPrice != null) ...[
              const SizedBox(width: DesignTokens.s8),
              Text(
                '${formatMoney(product.compareAtPrice!)}$unitLabel',
                style: DesignTokens.smallRegular.copyWith(
                  decoration: TextDecoration.lineThrough,
                  color: DesignTokens.colorError,
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
          OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => _AskQuestionDialog(
                vendorId: vendorId,
                productId: productId,
              ),
            ),
            style: DesignTokens.outlinedButtonStyle(),
            icon: const Icon(Icons.help_outline_rounded, size: 16),
            label: const Text('Ask a question'),
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
                Text(
                  'Customer Reviews (${widget.reviewCount})',
                  style: DesignTokens.mediumSemibold,
                ),
                const Spacer(),
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
            itemBuilder: (_, index) => _ReelThumb(review: reviews[index]),
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

class _ReelThumb extends StatelessWidget {
  const _ReelThumb({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    final source = Uri.tryParse(review.reelSourceUrl ?? '');
    return Material(
      color: DesignTokens.bgAppBodyLight,
      child: InkWell(
        onTap: source == null
            ? null
            : () => launchUrl(source, mode: LaunchMode.externalApplication),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white38,
                size: 26,
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              left: 4,
              child: Text(
                _platformLabel(review.reelPlatform),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _platformLabel(String? platform) => switch (platform) {
    '0' || 'Instagram' || 'instagram' => 'Instagram',
    '1' || 'YouTubeShorts' || 'youtubeShorts' => 'YouTube',
    '2' || 'TikTok' || 'tiktok' => 'TikTok',
    '3' || 'Facebook' || 'facebook' => 'Facebook',
    _ => 'Open reel',
  };
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
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 0.5),
        ),
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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Item Total', style: DesignTokens.smallRegular),
            Text(
              price,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(width: DesignTokens.s12),
        _StepperButton(
          icon: Icons.remove_rounded,
          onTap: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
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

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? DesignTokens.bgAppBodyLight
              : DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Icon(icon, size: 16, color: DesignTokens.textWhite),
      ),
    );
  }
}
