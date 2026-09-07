import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step5ReviewScreen extends ConsumerWidget {
  const Step5ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addProductNotifierProvider);
    final notifier = ref.read(addProductNotifierProvider.notifier);

    ref.listen<AddProductState>(addProductNotifierProvider, (prev, next) {
      next.maybeWhen(
        publishSuccess: (productId) {
          SmSnackbar.success(context, 'Product published successfully!');
          context.pop(true);
        },
        publishFailure: (_, e) {
          SmSnackbar.error(
            context,
            'Failed to publish product: ${NetworkExceptions.getMessage(e)}',
          );
        },
        saveSuccess: (_, d) {
          SmSnackbar.success(context, 'Draft saved!');
        },
        saveFailure: (_, e) {
          SmSnackbar.error(
            context,
            'Failed to save draft: ${NetworkExceptions.getMessage(e)}',
          );
        },
        orElse: () {},
      );
    });

    final review = state.maybeWhen(
      loadSuccess: (fs) => fs.reviewInfo,
      loadInProgress: (fs) => fs.reviewInfo,
      saveInProgress: (fs) => fs.reviewInfo,
      saveSuccess: (fs, d) => fs.reviewInfo,
      saveFailure: (fs, e) => fs.reviewInfo,
      publishing: (fs) => fs.reviewInfo,
      publishFailure: (fs, e) => fs.reviewInfo,
      orElse: () => null,
    );

    if (review == null) {
      return const Center(
        child: Text(
          'Complete previous steps first',
          style: DesignTokens.bodyText,
        ),
      );
    }

    final isPublishing =
        state.maybeWhen(publishing: (_) => true, orElse: () => false);

    final pricing = review.pricingInfo;
    final shipping = review.shippingInfo;
    final basic = review.basicInfo;
    final images = review.imagesInfo;

    // Pre-compute display strings
    final compareAtStr = pricing.compareAtPrice != null
        ? 'Rs ${pricing.compareAtPrice!.amount.toStringAsFixed(0)}'
        : '-';
    final costStr = pricing.costPerItem != null
        ? 'Rs ${pricing.costPerItem!.amount.toStringAsFixed(0)}'
        : '-';

    // Profit calculation
    final baseAmt = pricing.basePrice.amount;
    final discAmt = pricing.discountEnabled && pricing.discountPercent != null
        ? baseAmt * pricing.discountPercent! / 100
        : 0.0;
    final effectivePrice = baseAmt - discAmt;
    final costAmt = pricing.costPerItem?.amount ?? 0.0;
    final profit = effectivePrice - costAmt;
    final profitPct =
        effectivePrice > 0 ? (profit / effectivePrice * 100) : 0.0;

    // Shipping options text
    final shippingOptions = <String>[];
    if (shipping.deliveryEstimateMin >= 5) {
      shippingOptions.add('Standard (5-7 days) - FREE');
    }
    if (shipping.deliveryEstimateMin <= 3 &&
        shipping.deliveryEstimateMax <= 3) {
      shippingOptions.add('Express (2-3 days) - Rs 500');
    }
    if (shipping.deliveryEstimateMin == 1) {
      shippingOptions.add('Overnight (1 day) - Rs 800');
    }
    if (shippingOptions.isEmpty) {
      shippingOptions.add(
        '${shipping.deliveryEstimateMin}'
        '-${shipping.deliveryEstimateMax} days',
      );
    }

    return Column(
      children: [
        // â”€â”€ Scrollable content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Review Product Details',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                const Text(
                  'Review the details you entered before publishing',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: DesignTokens.textLight,
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),

                // 1 â€” Business Information
                _ReviewSection(
                  title: 'Business Information',
                  onEdit: () => notifier.goToStep(1),
                  children: [
                    _BoldValueRow(basic.productName),
                    if (basic.categories.isNotEmpty)
                      _LabelValueRow(basic.categories.join(' - ')),
                    if (basic.brand != null)
                      _LabelValueRow(basic.brand!),
                    _LabelValueRow(basic.shortDescription.isNotEmpty
                        ? basic.shortDescription
                        : basic.description,
                        maxLines: 3),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),

                // 2 â€” Images & Media
                _ReviewSection(
                  title: 'Images & Media',
                  onEdit: () => notifier.goToStep(2),
                  children: [
                    _ImagesThumbnailRow(
                      images: images.images,
                      primaryIndex: images.primaryImageIndex,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),

                // 3 â€” Pricing
                _ReviewSection(
                  title: 'Pricing',
                  onEdit: () => notifier.goToStep(3),
                  children: [
                    _DataRow(
                      label: 'Base Price',
                      value: 'Rs ${baseAmt.toStringAsFixed(0)}',
                    ),
                    _DataRow(
                      label: 'Compare at Price',
                      value: compareAtStr,
                    ),
                    _DataRow(
                      label: 'Discount Percent',
                      value: pricing.discountPercent != null
                          ? '${pricing.discountPercent!.toStringAsFixed(0)}%'
                          : '-',
                    ),
                    _DataRow(
                      label: 'Cost Per Item',
                      value: costStr,
                    ),
                    _ProfitRow(
                        profit: profit, profitPct: profitPct),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),

                // 4 â€” Inventory
                _ReviewSection(
                  title: 'Inventory',
                  onEdit: () => notifier.goToStep(3),
                  children: [
                    const _DataRow(label: 'Barcode', value: 'UPC'),
                    _DataRow(
                      label: 'Quantity',
                      value: '${pricing.quantityOnHand}',
                    ),
                    _DataRow(
                      label: 'Track Inventory',
                      value: pricing.trackInventory ? 'Yes' : 'No',
                    ),
                    _DataRow(
                      label: 'Allow Overselling',
                      value: pricing.allowOverselling ? 'Yes' : 'No',
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),

                // 5 â€” Creator Commission
                _ReviewSection(
                  title: 'Creator Commission',
                  onEdit: () => notifier.goToStep(3),
                  children: const [
                    _DataRow(label: 'Commission Rate', value: '-'),
                    _DataRow(label: 'Creators Earn', value: '-'),
                  ],
                ),
                const SizedBox(height: DesignTokens.s12),

                // 6 â€” Shipping Details
                _ReviewSection(
                  title: 'Shipping Details',
                  onEdit: () => notifier.goToStep(4),
                  children: [
                    _DataRow(
                      label: 'Weight',
                      value:
                          '${shipping.weight} ${shipping.weightUnit}',
                    ),
                    _DataRow(
                      label: 'Length',
                      value: '${shipping.dimensionsLength} inches',
                    ),
                    _DataRow(
                      label: 'Width',
                      value: '${shipping.dimensionsWidth} inches',
                    ),
                    _DataRow(
                      label: 'Height',
                      value: '${shipping.dimensionsHeight} inches',
                    ),
                    _DataRow(
                      label: 'Shipping Options',
                      value: shippingOptions.join(', '),
                    ),
                    const _DataRow(
                        label: 'Ships From', value: '-'),
                    const _DataRow(
                        label: 'Processing Time', value: '-'),
                  ],
                ),
                const SizedBox(height: DesignTokens.s16),
              ],
            ),
          ),
        ),

        // â”€â”€ Sticky Publish button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        SafeArea(
          top: false,
          child: Container(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s24,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppFoundation,
            border: Border(
              top: BorderSide(color: DesignTokens.borderDefault),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              onPressed: isPublishing
                  ? null
                  : () => ref
                      .read(addProductNotifierProvider.notifier)
                      .publish(),
              style: DesignTokens.primaryButtonStyle(),
              child: isPublishing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    )
                  : const Text(
                      'Publish Product',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
            ),
          ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Section card with Edit button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: DesignTokens.primaryGreen,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          ...children,
        ],
      ),
    );
  }
}

// â”€â”€ Bold product name row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BoldValueRow extends StatelessWidget {
  const _BoldValueRow(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s6),
      child: Text(
        value,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textWhite,
        ),
      ),
    );
  }
}

// â”€â”€ Single light-text label row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow(this.value, {this.maxLines = 2});

  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s4),
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: DesignTokens.textLight,
        ),
      ),
    );
  }
}

// â”€â”€ Label : Value row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(width: DesignTokens.s16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Your Profit row with green pill â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProfitRow extends StatelessWidget {
  const _ProfitRow({required this.profit, required this.profitPct});

  final double profit;
  final double profitPct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Profit',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: DesignTokens.textLight,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s8, vertical: 3),
            decoration: BoxDecoration(
              color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(
                  color: DesignTokens.primaryGreen.withValues(alpha: 0.4)),
            ),
            child: Text(
              '${profit.toStringAsFixed(0)} (${profitPct.toStringAsFixed(0)}%)',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Images thumbnail strip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ImagesThumbnailRow extends StatelessWidget {
  const _ImagesThumbnailRow({
    required this.images,
    required this.primaryIndex,
  });

  final List<String> images;
  final int primaryIndex;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Text(
        'No images added',
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          color: DesignTokens.textMuted,
        ),
      );
    }

    const visibleMax = 3;
    final visible = images.take(visibleMax).toList();
    final overflow = images.length - visibleMax;

    return Row(
      children: [
        ...visible.asMap().entries.map((e) {
          final isPrimary = e.key == primaryIndex;
          return Padding(
            padding:
                const EdgeInsets.only(right: DesignTokens.s8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    e.value,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image,
                          color: DesignTokens.textMuted),
                    ),
                  ),
                ),
                if (isPrimary)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Main',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
        if (overflow > 0)
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '+$overflow',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
