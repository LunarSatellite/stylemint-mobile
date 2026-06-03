import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/related_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_image_carousel.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/variant_selector.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

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
    final state = ref.watch(
      productDetailNotifierProvider(widget.productId),
    );

    ref.listen<Object?>(
      productDetailNotifierProvider(widget.productId).select(
        (_) => null,
      ),
      (_, __) {
        // Listen for addToCart result handled inside, no state change
      },
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: state.when(
        initial: () => const _Loader(),
        loadInProgress: () => const _Loader(),
        loadSuccess: (product) => _ProductBody(
          product: product,
          quantity: _quantity,
          selectedVariants: _selectedVariants,
          onQuantityChanged: (v) => setState(() => _quantity = v),
          onVariantSelected:
              (variantId, value) =>
                  setState(() => _selectedVariants[variantId] = value),
          onAddToCart: () => _handleAddToCart(product),
          onToggleSave: () => _handleToggleSave(product),
        ),
        loadFailure:
            (failure) => SmErrorView(
              message: 'Failed to load product.',
              onRetry: () {
                ref
                    .read(
                      productDetailNotifierProvider(widget.productId).notifier,
                    )
                    .loadProduct(widget.productId);
              },
            ),
      ),
    );
  }

  Future<void> _handleAddToCart(ProductDetail product) async {
    // Progressive auth gate (design §2): auth + required profile fields
    // resolve just-in-time before the real action runs.
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;
    if (!await ensureProfile(context, ref, [ProfileField.shippingAddress])) {
      return;
    }
    if (!mounted) return;
    final success = await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .addToCart(
          productId: widget.productId,
          qty: _quantity,
          variantId: _selectedVariants.isNotEmpty
              ? _selectedVariants.values.first
              : null,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to cart'),
          backgroundColor: DesignTokens.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleToggleSave(ProductDetail product) async {
    await ref
        .read(productDetailNotifierProvider(widget.productId).notifier)
        .toggleSave(widget.productId);
  }
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({
    required this.product,
    required this.quantity,
    required this.selectedVariants,
    required this.onQuantityChanged,
    required this.onVariantSelected,
    required this.onAddToCart,
    required this.onToggleSave,
  });

  final ProductDetail product;
  final int quantity;
  final Map<String, String> selectedVariants;
  final ValueChanged<int> onQuantityChanged;
  final void Function(String variantId, String value) onVariantSelected;
  final VoidCallback onAddToCart;
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: DesignTokens.textWhite),
                onPressed: () => context.pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: DesignTokens.textWhite),
                  onPressed: () {},
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: ProductImageCarousel(images: product.images),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductInfo(product: product),
                    const SizedBox(height: DesignTokens.s20),
                    if (product.variants.isNotEmpty)
                      ...product.variants.map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                          child: VariantSelector(
                            variant: v,
                            selectedValue: selectedVariants[v.id],
                            onSelected:
                                (val) => onVariantSelected(v.id, val),
                          ),
                        ),
                      ),
                    const SizedBox(height: DesignTokens.s4),
                    _QuantityStepper(
                      quantity: quantity,
                      onChanged: onQuantityChanged,
                      maxStock: product.stockCount,
                    ),
                    const SizedBox(height: DesignTokens.s20),
                    _DescriptionSection(description: product.description),
                    const SizedBox(height: DesignTokens.s20),
                    if (product.specifications.isNotEmpty) ...[
                      _SectionTitle('Specifications'),
                      const SizedBox(height: DesignTokens.s8),
                      _SpecificationsTable(
                        specifications: product.specifications,
                      ),
                      const SizedBox(height: DesignTokens.s20),
                    ],
                    _VendorCard(
                      vendorName: product.vendorName,
                      vendorAvatarUrl: product.vendorAvatarUrl,
                    ),
                    const SizedBox(height: DesignTokens.s20),
                    _SectionTitle(
                      'Reviews (${product.reviewCount})',
                      action: product.reviewCount > 0
                          ? GestureDetector(
                              onTap: () {},
                              child: Text(
                                'See All',
                                style: DesignTokens.mediumSemibold.copyWith(
                                  color: DesignTokens.primaryGreen,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    _ReviewsPreview(reviewCount: product.reviewCount),
                    const SizedBox(height: DesignTokens.s20),
                    _SectionTitle('Related Products'),
                    const SizedBox(height: DesignTokens.s8),
                    _RelatedProductsSection(productId: product.id),
                    const SizedBox(height: DesignTokens.s16),
                    _ShippingInfo(info: product.shippingInfo),
                    const SizedBox(height: 100),
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
            onAddToCart: onAddToCart,
          ),
        ),
        Positioned(
          right: DesignTokens.s16,
          bottom: 80 + MediaQuery.of(context).padding.bottom,
          child: _SaveButton(isSaved: product.isSaved, onTap: onToggleSave),
        ),
      ],
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});

  final ProductDetail product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: DesignTokens.titleLarge),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Text(
              formatMoney(product.price),
              style: DesignTokens.titleMedium.copyWith(
                color: DesignTokens.primaryGreen,
              ),
            ),
            if (product.compareAtPrice != null) ...[
              const SizedBox(width: DesignTokens.s8),
              Text(
                formatMoney(product.compareAtPrice!),
                style: DesignTokens.bodyText.copyWith(
                  color: DesignTokens.textMuted,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            const Icon(Icons.star_rounded,
                size: DesignTokens.iconSmall,
                color: DesignTokens.secondaryYellow),
            const SizedBox(width: DesignTokens.s4),
            Text(
              '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
              style: DesignTokens.smallRegular,
            ),
            const SizedBox(width: DesignTokens.s12),
            Text(
              '${_compact(product.soldCount)} sold',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
        if (!product.isInStock)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s8),
            child: Text(
              'Out of Stock',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ),
      ],
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    this.maxStock,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int? maxStock;

  @override
  Widget build(BuildContext context) {
    final maxQty = maxStock ?? 99;
    return Row(
      children: [
        Text('Quantity', style: DesignTokens.mediumSemibold),
        const Spacer(),
        _StepperButton(
          icon: Icons.remove_rounded,
          onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
          child: SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: DesignTokens.oneLinerSemibold,
            ),
          ),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          onTap: quantity < maxQty ? () => onChanged(quantity + 1) : null,
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
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              onTap != null
                  ? DesignTokens.bgAppBodyLight
                  : DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Icon(icon, size: 18, color: DesignTokens.textWhite),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: DesignTokens.sectionInnerTitle),
        if (action != null) ...[const Spacer(), action!],
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Description'),
        const SizedBox(height: DesignTokens.s8),
        Text(description, style: DesignTokens.bodyText),
      ],
    );
  }
}

class _SpecificationsTable extends StatelessWidget {
  const _SpecificationsTable({required this.specifications});

  final Map<String, String> specifications;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Column(
        children: specifications.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    e.key,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    e.value,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendorName,
    required this.vendorAvatarUrl,
  });

  final String vendorName;
  final String vendorAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DesignTokens.bgAppBodyLight,
            backgroundImage:
                vendorAvatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(vendorAvatarUrl)
                    : null,
            child:
                vendorAvatarUrl.isEmpty
                    ? const Icon(Icons.store,
                        color: DesignTokens.iconLight, size: 22)
                    : null,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(vendorName, style: DesignTokens.mediumSemibold),
          ),
          TextButton(
            onPressed: () {},
            style: DesignTokens.outlinedButtonStyle().copyWith(
              minimumSize: WidgetStateProperty.all(const Size(0, 36)),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              ),
            ),
            child: const Text('View Shop'),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPreview extends StatelessWidget {
  const _ReviewsPreview({required this.reviewCount});

  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Text(
        'No reviews yet',
        style: DesignTokens.bodyText.copyWith(color: DesignTokens.textMuted),
      );
    }
    return const SizedBox.shrink();
  }
}

class _RelatedProductsSection extends ConsumerWidget {
  const _RelatedProductsSection({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(relatedProductsProvider(productId));

    return state.when(
      initial: () => const SizedBox.shrink(),
      loadInProgress: () => const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
      ),
      loadSuccess: (products) => SizedBox(
        height: 210,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s12),
          itemBuilder: (_, i) => _RelatedProductCard(product: products[i]),
        ),
      ),
      loadFailure: (_) => const SizedBox.shrink(),
    );
  }
}

class _RelatedProductCard extends StatelessWidget {
  const _RelatedProductCard({required this.product});

  final RelatedProduct product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '${RouteNames.productDetail}'.replaceFirst(':productId', product.id),
        );
      },
      child: Container(
        width: 140,
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.cardRadius),
              ),
              child: SizedBox(
                height: 120,
                width: 140,
                child:
                    product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, _) => const ColoredBox(
                                color: DesignTokens.bgAppBodyLight,
                              ),
                          errorWidget:
                              (_, _, _) => const ColoredBox(
                                color: DesignTokens.bgAppBodyLight,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: DesignTokens.iconLight,
                                ),
                              ),
                        )
                        : const ColoredBox(color: DesignTokens.bgAppBodyLight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    formatMoney(product.price),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: DesignTokens.secondaryYellow,
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: DesignTokens.smallRegular,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShippingInfo extends StatelessWidget {
  const _ShippingInfo({required this.info});

  final String info;

  @override
  Widget build(BuildContext context) {
    if (info.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_outlined,
              color: DesignTokens.iconLight, size: DesignTokens.iconSmall),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              info,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.product, required this.onAddToCart});

  final ProductDetail product;
  final VoidCallback onAddToCart;

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
        color: DesignTokens.bgAppBody,
        border: const Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            formatMoney(product.price),
            style: DesignTokens.titleMedium.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: ElevatedButton(
              onPressed: product.isInStock ? onAddToCart : null,
              style: DesignTokens.primaryButtonStyle(),
              child: Text(
                product.isInStock || product.stockCount == null
                    ? 'Add to Cart'
                    : 'Out of Stock',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.buttonPrimaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaved, required this.onTap});

  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSaved ? DesignTokens.colorError : DesignTokens.bgAppBody,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSaved ? DesignTokens.colorError : DesignTokens.borderDefault,
            width: 1.5,
          ),
        ),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border_rounded,
          color:
              isSaved ? DesignTokens.textWhite : DesignTokens.textWhite,
          size: DesignTokens.iconMedium,
        ),
      ),
    );
  }
}
