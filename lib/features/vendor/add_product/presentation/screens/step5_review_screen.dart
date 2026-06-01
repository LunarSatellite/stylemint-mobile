import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/presentation/notifiers/add_product_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/add_product/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class Step5ReviewScreen extends ConsumerWidget {
  const Step5ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addProductNotifierProvider);

    ref.listen<AddProductState>(addProductNotifierProvider, (prev, next) {
      next.maybeWhen(
        publishSuccess: (productId) {
          SmSnackbar.success(context, 'Product published successfully!');
          context.pop();
        },
        publishFailure: (_, __) {
          SmSnackbar.error(context, 'Failed to publish product.');
        },
        saveSuccess: (_, __) {
          SmSnackbar.success(context, 'Draft saved!');
        },
        saveFailure: (_, __) {
          SmSnackbar.error(context, 'Failed to save draft.');
        },
        orElse: () {},
      );
    });

    final review = state.maybeWhen(
      loadSuccess: (fs) => fs.reviewInfo,
      loadInProgress: (fs) => fs.reviewInfo,
      saveInProgress: (fs) => fs.reviewInfo,
      saveSuccess: (fs, _) => fs.reviewInfo,
      saveFailure: (fs, _) => fs.reviewInfo,
      publishing: (fs) => fs.reviewInfo,
      publishFailure: (fs, _) => fs.reviewInfo,
      orElse: () => null,
    );

    if (review == null) {
      return const Center(child: Text('Complete previous steps first',
          style: DesignTokens.bodyText));
    }

    final isPublishing =
        state.maybeWhen(publishing: (_) => true, orElse: () => false);
    final isSaving =
        state.maybeWhen(saveInProgress: (_) => true, orElse: () => false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Publish', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s20),
          _SectionCard(
            title: 'Basic Info',
            rows: [
              _ReviewRow('Name', review.basicInfo.productName),
              _ReviewRow('Description', review.basicInfo.description),
              _ReviewRow(
                  'Categories', review.basicInfo.categories.join(', ')),
              if (review.basicInfo.brand != null)
                _ReviewRow('Brand', review.basicInfo.brand!),
              _ReviewRow('Tags', review.basicInfo.tags.join(', ')),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          _SectionCard(
            title: 'Images',
            children: [
              Text(
                '${review.imagesInfo.images.length} image(s)',
                style: DesignTokens.mediumRegular,
              ),
              const SizedBox(height: DesignTokens.s8),
              Row(
                children: review.imagesInfo.images
                    .take(4)
                    .map((url) => Padding(
                          padding:
                              const EdgeInsets.only(right: DesignTokens.s8),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.s8),
                            child: Image.network(
                              url,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image,
                                  size: 24, color: DesignTokens.textMuted),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          _SectionCard(
            title: 'Pricing',
            rows: [
              _ReviewRow('Base Price',
                  formatMoney(review.pricingInfo.basePrice)),
              if (review.pricingInfo.compareAtPrice != null)
                _ReviewRow('Compare At',
                    formatMoney(review.pricingInfo.compareAtPrice!)),
              if (review.pricingInfo.costPerItem != null)
                _ReviewRow('Cost',
                    formatMoney(review.pricingInfo.costPerItem!)),
              _ReviewRow(
                  'Tax Rate', '${review.pricingInfo.taxRate.toStringAsFixed(0)}%'),
              if (review.pricingInfo.discountEnabled &&
                  review.pricingInfo.discountPercent != null)
                _ReviewRow('Discount',
                    '${review.pricingInfo.discountPercent!.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          _SectionCard(
            title: 'Shipping',
            rows: [
              _ReviewRow('Requires Shipping',
                  review.shippingInfo.requiresShipping ? 'Yes' : 'No'),
              if (review.shippingInfo.requiresShipping) ...[
                _ReviewRow('Weight',
                    '${review.shippingInfo.weight} ${review.shippingInfo.weightUnit}'),
                _ReviewRow('Dimensions',
                    '${review.shippingInfo.dimensionsLength} x ${review.shippingInfo.dimensionsWidth} x ${review.shippingInfo.dimensionsHeight} cm'),
                if (review.shippingInfo.shippingFee != null)
                  _ReviewRow('Shipping Fee',
                      formatMoney(review.shippingInfo.shippingFee!)),
                if (review.shippingInfo.freeShippingOver != null)
                  _ReviewRow('Free Over',
                      formatMoney(review.shippingInfo.freeShippingOver!)),
                _ReviewRow(
                    'Delivery',
                    '${review.shippingInfo.deliveryEstimateMin} - ${review.shippingInfo.deliveryEstimateMax} days'),
              ],
            ],
          ),
          const SizedBox(height: DesignTokens.s24),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () => ref
                      .read(addProductNotifierProvider.notifier)
                      .saveDraft(),
              style: DesignTokens.outlinedButtonStyle(),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: DesignTokens.textWhite))
                  : Text('Save as Draft',
                      style: DesignTokens.mediumSemibold),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
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
                          strokeWidth: 2, color: DesignTokens.buttonPrimaryText))
                  : Text('Publish Product',
                      style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.buttonPrimaryText)),
            ),
          ),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, this.rows, this.children});

  final String? title;
  final List<Widget>? rows;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen),
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
          if (rows != null) ...rows!,
          if (children != null) ...children!,
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: DesignTokens.mediumSemibold,
            ),
          ),
        ],
      ),
    );
  }
}
