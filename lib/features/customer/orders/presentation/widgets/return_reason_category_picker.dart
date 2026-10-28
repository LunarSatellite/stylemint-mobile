import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_reason_category.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "What's wrong?" — one chip per [ReturnReasonCategory.choices].
class ReturnReasonCategoryPicker extends StatelessWidget {
  const ReturnReasonCategoryPicker({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final ReturnReasonCategory? selected;
  final ValueChanged<ReturnReasonCategory> onSelected;

  static Key chipKey(ReturnReasonCategory category) =>
      ValueKey<String>('return-category-${category.wire}');

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: DesignTokens.s8,
    runSpacing: DesignTokens.s8,
    children: [
      for (final category in ReturnReasonCategory.choices)
        ChoiceChip(
          key: chipKey(category),
          label: Text(category.label),
          selected: selected == category,
          onSelected: (_) => onSelected(category),
        ),
    ],
  );
}

/// Where the pickup-fare quote stands in the return form.
class ReturnPickupQuoteView {
  const ReturnPickupQuoteView.none() : quote = null, loading = false;
  const ReturnPickupQuoteView.loading() : quote = null, loading = true;
  const ReturnPickupQuoteView.unavailable() : quote = null, loading = false;
  const ReturnPickupQuoteView.ready(ReturnPickupQuote this.quote)
    : loading = false;

  final ReturnPickupQuote? quote;
  final bool loading;
}

/// Who pays the rider, said before the buyer submits (contract §6). Only
/// "Changed my mind" costs the buyer anything.
class ReturnPickupFeeNote extends StatelessWidget {
  const ReturnPickupFeeNote({
    required this.category,
    required this.quote,
    super.key,
  });

  final ReturnReasonCategory category;
  final ReturnPickupQuoteView quote;

  static const freeText = 'No pickup fee: the seller pays it.';
  static const noQuoteText =
      'The pickup fee comes off your refund. We could not work it out yet.';

  /// "Pickup fee about Rs 150. Up to Rs 185 will be deducted from your
  /// refund."
  static String feeText(ReturnPickupQuote quote) =>
      'Pickup fee about ${formatFare(quote.estimate)}. '
      'Up to ${formatFare(quote.upTo)} will be deducted from your refund.';

  @override
  Widget build(BuildContext context) {
    final buyerPays = category.buyerPaysPickup;
    final ready = quote.quote;
    final text = !buyerPays
        ? freeText
        : ready != null
        ? feeText(ready)
        : quote.loading
        ? 'Working out the pickup fee…'
        : noQuoteText;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: (buyerPays ? DesignTokens.colorWarning : DesignTokens.primaryGreen)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            buyerPays ? Icons.two_wheeler_rounded : Icons.check_circle_outline,
            size: 18,
            color: buyerPays
                ? DesignTokens.colorWarning
                : DesignTokens.primaryGreen,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: DesignTokens.smallRegular),
                if (buyerPays && ready?.refundIfChangedMind != null)
                  Text(
                    'You get back at least '
                    '${formatFare(ready!.refundIfChangedMind!)}.',
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Rs 150" for a whole amount, "Rs 150.50" otherwise.
String formatFare(Money money) => formatMoney(
  money,
  decimalDigits: money.amount == money.amount.roundToDouble() ? 0 : 2,
);
