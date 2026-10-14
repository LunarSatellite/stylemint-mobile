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
/// (`POST /v1/checkout/sessions/payment-plan`), so:
/// - a cart of exactly one line whose variant has plan options shows a card
///   that opens the same plan sheet as the product page (tenure, down
///   payment, schedule, verification, then the plan checkout, where the down
///   payment is paid online);
/// - a cart of several lines says which items can be bought on EMI on their
///   own, without changing the cart;
/// - anything else draws nothing.
class CheckoutEmiOption extends ConsumerWidget {
  const CheckoutEmiOption({required this.items, super.key});

  final List<CartItem> items;

  static const Key cardKey = Key('checkout-emi-card');
  static const Key noteKey = Key('checkout-emi-note');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withVariant = items.where((i) => i.variantId != null).toList();
    if (withVariant.isEmpty) return const SizedBox.shrink();

    if (items.length == 1 && items.first.quantity == 1) {
      final item = items.first;
      final options =
          ref.watch(planOptionsProvider(item.variantId!)).asData?.value;
      if (options == null || options.options.isEmpty) {
        return const SizedBox.shrink();
      }
      return _EmiCard(item: item, options: options);
    }

    // Several lines: name the ones that could go on a plan by themselves.
    final eligible = <String>[];
    for (final item in withVariant) {
      final options =
          ref.watch(planOptionsProvider(item.variantId!)).asData?.value;
      if (options != null && options.options.isNotEmpty) {
        eligible.add(item.productName);
      }
    }
    if (eligible.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: noteKey,
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Text(
        'EMI is available for ${eligible.join(', ')}. '
        'Payment plans cover one item at a time — buy it on its own '
        '(one piece) to pay a down payment now and the rest monthly.',
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 13,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}

class _EmiCard extends StatelessWidget {
  const _EmiCard({required this.item, required this.options});

  final CartItem item;
  final PlanOptions options;

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
          key: CheckoutEmiOption.cardKey,
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
                      const Text(
                        'Pay with EMI',
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
