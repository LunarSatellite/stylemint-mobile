import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_calculator_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Pay with EMI" on the checkout screen.
///
/// Payment plans are per variant and check out one item at a time
/// (`POST /v1/checkout/sessions/payment-plan`). Every cart line whose variant
/// has plan options gets a card that opens the same plan sheet as the product
/// page (tenure, down payment, schedule, verification, then the plan
/// checkout, where the down payment is paid online). Lines without options
/// draw nothing.
class CheckoutEmiOption extends ConsumerWidget {
  const CheckoutEmiOption({required this.items, super.key});

  final List<CartItem> items;

  static const Key cardKey = Key('checkout-emi-card');
  static const Key noteKey = Key('checkout-emi-note');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One card per item that has a payment plan, whatever else is in the
    // cart: the plan checks out that item on its own
    // (`POST /v1/checkout/sessions/payment-plan`), the rest of the cart stays.
    final cards = <Widget>[];
    for (final item in items) {
      final id = item.variantId;
      if (id == null) continue;
      final options = ref.watch(planOptionsProvider(id)).asData?.value;
      if (options == null || options.options.isEmpty) continue;
      cards.add(_EmiCard(item: item, options: options, named: items.length > 1));
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...cards,
        if (items.length > 1)
          Padding(
            key: noteKey,
            padding: const EdgeInsets.only(bottom: DesignTokens.s16),
            child: const Text(
              'A payment plan covers one item: choosing EMI checks out that '
              'item on its own, and the rest stays in your cart.',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmiCard extends StatelessWidget {
  const _EmiCard({
    required this.item,
    required this.options,
    required this.named,
  });

  final CartItem item;
  final PlanOptions options;

  /// Name the item when the cart holds more than one.
  final bool named;

  @override
  Widget build(BuildContext context) {
    final emi = options.of(PlanKind.instalment) ?? options.options.first;
    final monthly = formatMoney(emi.fromMonthly, decimalDigits: 0);
    final down = formatMoney(emi.fromDownPayment, decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Material(
        color: DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: named ? ValueKey('checkout-emi-card-${item.variantId}') : CheckoutEmiOption.cardKey,
          borderRadius: BorderRadius.circular(16),
          onTap: () => showEmiCalculatorSheet(
            context,
            productId: item.productId,
            productName: item.productName,
            variantId: item.variantId!,
            price: options.price,
            planOptions: options.options,
            initialKind: emi.kind,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        named ? 'Pay with EMI · ${item.productName}' : 'Pay with EMI',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Down payment from $down now, then from $monthly/month. '
                        'Choose your plan and see the full schedule.',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: DesignTokens.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
