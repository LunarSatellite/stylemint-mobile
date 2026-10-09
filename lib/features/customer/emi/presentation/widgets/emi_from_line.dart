import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_calculator_sheet.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "EMI from Rs x/month" under the product price, for a variant the vendor's
/// EMI terms cover. Draws nothing otherwise — no offer, an ineligible
/// variant, or a server that predates EMI.
///
/// The figure is this variant's installment at the minimum down payment over
/// the longest tenure, worked out with the contract's rounding, so it is the
/// same number the calculator opens on.
class EmiFromLine extends StatelessWidget {
  const EmiFromLine({
    required this.offer,
    required this.productId,
    required this.productName,
    required this.variantId,
    this.padding = const EdgeInsets.only(top: DesignTokens.s8),
    super.key,
  });

  final ProductEmiOffer? offer;
  final String productId;
  final String productName;
  final String? variantId;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final terms = offer;
    final id = variantId;
    final price = terms?.priceOf(id);
    final monthly = terms?.fromMonthlyFor(id);
    if (terms == null || id == null || price == null || monthly == null) {
      return const SizedBox.shrink();
    }
    final label = 'EMI from ${formatMoney(monthly, decimalDigits: 0)}/month';
    return Padding(
      padding: padding,
      child: Semantics(
        button: true,
        label: '$label. Opens the EMI calculator.',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          onTap: () => showEmiCalculatorSheet(
            context,
            productId: productId,
            productName: productName,
            variantId: id,
            price: price,
            offer: terms,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DesignTokens.minTouchTarget,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s8),
                Flexible(
                  child: Text(
                    label,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: DesignTokens.primaryGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
