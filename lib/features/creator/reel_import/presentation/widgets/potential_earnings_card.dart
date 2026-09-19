import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/reel_earnings_projection.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/tag_product_commission.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

String _products(int n) => n == 1 ? 'product' : 'products';

String _has(int n) => n == 1 ? 'has' : 'have';

/// The sentence that has to sit beside a total which does **not** cover the
/// whole tagged basket.
///
/// Shared by the earnings card, the Review screen and the Published screen so
/// that a creator reads the same coverage in the same words on all three, and
/// so that a fourth screen cannot quietly drop it. A total over two of five
/// tagged products, drawn as *the* total, is a false statement about
/// someone's income; the figure is worth keeping, the silence is not.
String partialEarningsCoverage(ReelEarningsProjection projection) {
  final unknown = projection.unknownProducts;
  return 'Covers ${projection.statedProducts} of '
      '${projection.totalProducts} tagged '
      '${_products(projection.totalProducts)}. The other $unknown '
      '${_has(unknown)} no commission figure.';
}

/// The earnings header above the product list.
///
/// ## What it replaced
///
/// `Est. Potential Earnings: ~Rs 1,200`, summed from `price * 0.10` over the
/// tagged products, with a breakdown of `12 * ~Rs 300 = ~Rs 3,600 (est.)`
/// rows underneath. The rate was invented, and it was drawn immediately above
/// cards already showing the real one.
///
/// ## The mixed basket
///
/// Two tagged products with a partnership and three with no answer is the
/// case that decides whether this card is honest. Summing the two and
/// printing the sum as *the* potential earnings is a false statement about
/// someone's income, so a figure that does not cover the whole basket says
/// so, in words, next to the figure — [ReelEarningsProjection.isPartial].
/// A basket where nothing at all is known ([ReelEarningsProjection.isSilent])
/// draws no card; the caller gates on it.
///
/// A `NoPartnership` product is **covered**, not unknown: the server stated
/// that no commission is earned on it. It adds nothing to the figure and
/// nothing is invented for it, and a basket of nothing but `NoPartnership`
/// says "No commission applies" with no numeral anywhere.
class PotentialEarningsCard extends StatelessWidget {
  const PotentialEarningsCard({
    required this.projection,
    required this.isExpanded,
    required this.onToggle,
    required this.taggedProducts,
    required this.commissions,
    super.key,
  });

  final ReelEarningsProjection projection;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<TaggedProductForImport> taggedProducts;

  /// The batched answers, by product id. Null while the lookup is in flight
  /// or after it failed — which makes every row unknown, never zero.
  final Map<String, TagProductCommission>? commissions;

  static const _projectedSales = 50;

  /// The figure, or the stated absence of one. Never an estimate.
  String get _headline {
    final perSale = projection.perSale;
    if (perSale == null) return 'No commission applies';
    return 'Your commission: ${formatMoney(perSale)} per sale';
  }

  /// What the headline covers. This is the whole point of the card: a total
  /// that omits part of the basket must say which part.
  String get _coverage {
    final total = projection.totalProducts;
    final stated = projection.statedProducts;
    final unknown = projection.unknownProducts;
    if (projection.hasFigure) {
      if (projection.isPartial) {
        return partialEarningsCoverage(projection);
      }
      return 'Across all $total tagged ${_products(total)}.';
    }
    if (projection.isPartial) {
      return '$stated of $total tagged ${_products(total)} earn no '
          'commission. The other $unknown ${_has(unknown)} no commission '
          'figure.';
    }
    return 'None of your $total tagged ${_products(total)} earns a '
        'commission.';
  }

  @override
  Widget build(BuildContext context) {
    final n = taggedProducts.length;
    final salesPerProduct = n > 0 ? _projectedSales ~/ n : 0;
    final remainder = n > 0 ? _projectedSales % n : 0;

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _headline,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        _coverage,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: DesignTokens.s12),
              Text(
                'If this reel generates $_projectedSales sales:',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              for (int i = 0; i < taggedProducts.length; i++) ...[
                _BreakdownRow(
                  product: taggedProducts[i],
                  qty: salesPerProduct + (i < remainder ? 1 : 0),
                  answer: commissions?[taggedProducts[i].productId],
                ),
                if (i < taggedProducts.length - 1)
                  const SizedBox(height: DesignTokens.s8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// One product's line in the expanded breakdown.
///
/// It used to read `12 * ~Rs 300 = ~Rs 3,600 (est.)`, where `Rs 300` was ten
/// percent of the shelf price. The per-sale money is now the server's
/// [TagProductCommission.commissionPerSale], multiplied only by the stated
/// hypothetical quantity the card names above it.
///
/// The three outcomes match the `_CommissionChip` on the product card exactly,
/// so a product cannot say one thing on its card and another here:
///
/// * `Applies` with a per-sale figure — the arithmetic, including a genuine
///   `Rs 0.00` for a recorded 0% term.
/// * `NoPartnership` — "No commission applies", no numeral.
/// * anything else, including a lookup in flight or failed — **nothing**.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.product,
    required this.qty,
    required this.answer,
  });

  final TaggedProductForImport product;
  final int qty;

  /// Null while the lookup is in flight, when it failed, or when the server
  /// returned no row for this product.
  final TagProductCommission? answer;

  Widget? _figure() {
    final commission = answer;
    if (commission == null) return null;
    switch (commission.status) {
      case TagProductCommissionStatus.productUnavailable:
        return null;
      case TagProductCommissionStatus.noPartnership:
        return Text(
          'No commission applies',
          textAlign: TextAlign.end,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
            fontStyle: FontStyle.italic,
          ),
        );
      case TagProductCommissionStatus.applies:
        final perSale = commission.commissionPerSale;
        // A rate with no money behind it cannot be turned into rupees here.
        if (perSale == null) return null;
        final total = Money(
          amount: perSale.amount * qty,
          currency: perSale.currency,
        );
        return Text(
          '$qty × ${formatMoney(perSale)} = ${formatMoney(total)}',
          textAlign: TextAlign.end,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final figure = _figure();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            product.productName,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textWhite,
            ),
          ),
        ),
        if (figure != null) ...[
          const SizedBox(width: DesignTokens.s8),
          Expanded(flex: 3, child: figure),
        ],
      ],
    );
  }
}
