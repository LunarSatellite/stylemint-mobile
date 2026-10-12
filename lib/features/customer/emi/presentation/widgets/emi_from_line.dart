import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_calculator_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "EMI from Rs x/month" under the product price — and, when the seller
/// offers them, pay later and pay-now-buy-later too. Opens the plan sheet.
///
/// What is on offer comes from `GET /v1/credit/offers/{variantId}`. Until that
/// answers, or on a server that predates it, the line falls back to phase 1:
/// EMI from the product payload's own terms, drawn exactly as before. When
/// the server answers that nothing is offered, nothing is drawn.
///
/// The EMI figure is this variant's instalment at the minimum down payment
/// over the longest tenure, worked out with the contract's rounding, so it is
/// the same number the sheet opens on.
class EmiFromLine extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final id = variantId;
    if (id == null) return const SizedBox.shrink();

    final options = ref.watch(planOptionsProvider(id)).asData?.value;
    if (options != null) {
      if (options.options.isEmpty) return const SizedBox.shrink();
      return _withOptions(context, id, options);
    }
    return _phaseOne(context, id);
  }

  /// Phase 1, unchanged: EMI from the product payload, or nothing.
  Widget _phaseOne(BuildContext context, String id) {
    final terms = offer;
    final price = terms?.priceOf(id);
    final monthly = terms?.fromMonthlyFor(id);
    if (terms == null || price == null || monthly == null) {
      return const SizedBox.shrink();
    }
    return _Line(
      padding: padding,
      label: 'EMI from ${formatMoney(monthly, decimalDigits: 0)}/month',
      hint: 'Opens the EMI calculator.',
      onTap: () => showEmiCalculatorSheet(
        context,
        productId: productId,
        productName: productName,
        variantId: id,
        price: price,
        offer: terms,
      ),
    );
  }

  Widget _withOptions(BuildContext context, String id, PlanOptions options) {
    final emi = options.of(PlanKind.instalment);
    // Phase 1's terms, when the payload carried them for this variant, keep
    // the EMI part of the sheet exactly as it was — including its live
    // server check.
    final phaseOne = offer != null && offer!.priceOf(id) != null ? offer : null;
    final price = phaseOne?.priceOf(id) ?? options.price;

    final String lead;
    if (emi != null) {
      final monthly = phaseOne?.fromMonthlyFor(id) ?? emi.fromMonthly;
      lead = 'EMI from ${_whole(monthly)}/month';
    } else {
      final first = options.options.first;
      lead = '${first.kind.label} from ${_whole(first.fromMonthly)}/month';
    }
    final others = options.options
        .where((o) => o.kind != (emi?.kind ?? options.options.first.kind))
        .map((o) => o.kind.label.toLowerCase())
        .toList();
    final label = others.isEmpty ? lead : '$lead · or ${others.join(', ')}';

    return _Line(
      padding: padding,
      label: label,
      hint: 'Opens the payment plans.',
      onTap: () => showEmiCalculatorSheet(
        context,
        productId: productId,
        productName: productName,
        variantId: id,
        price: price,
        offer: emi == null ? null : phaseOne,
        planOptions: options.options,
      ),
    );
  }

  static String _whole(Money money) => formatMoney(money, decimalDigits: 0);
}

class _Line extends StatelessWidget {
  const _Line({
    required this.padding,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final EdgeInsets padding;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Semantics(
      button: true,
      label: '$label. $hint',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        onTap: onTap,
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
