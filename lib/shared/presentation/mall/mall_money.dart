import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_signal.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// The money ledger. Post-purchase, the single most common failure is an
// ambiguous number: a buyer cannot tell what they paid from what is coming
// back from what is still owed. So amounts get a shape, not just a value.
//
// Takes pre-formatted strings on purpose — currency formatting already lives
// in the features, and the kit must not grow a second formatter.

/// What an amount *means*, which decides its weight and its sign.
enum MallAmountKind {
  /// An ordinary line: subtotal, shipping, tax.
  line,

  /// A reduction already applied — discount, coupon. Drawn with a leading
  /// minus and the accent.
  deduction,

  /// The order's total. Heavier, larger, above a hairline.
  total,

  /// Money coming back to the buyer. Drawn with a leading plus and a glyph.
  refund,

  /// Money still owed. Drawn with the caution tone and a glyph, so it can
  /// never be mistaken for a paid figure.
  due,
}

/// One row of a [MallMoneyLedger]: label on the left, amount on the right.
@immutable
class MallAmount {
  const MallAmount({
    required this.label,
    required this.value,
    this.kind = MallAmountKind.line,
    this.note,
  });

  final String label;

  /// Already formatted, e.g. "Rs 3,499".
  final String value;
  final MallAmountKind kind;

  /// Small print under the label, e.g. "Back to your card in 5-7 days".
  final String? note;

  /// Sign prefix. A refund and a deduction are never bare numbers.
  String get prefix => switch (kind) {
    MallAmountKind.deduction => '-',
    MallAmountKind.refund => '+',
    MallAmountKind.line || MallAmountKind.total || MallAmountKind.due => '',
  };

  /// Non-colour carrier for the two kinds a buyer must not misread.
  IconData? get glyph => switch (kind) {
    MallAmountKind.refund => Icons.south_west_rounded,
    MallAmountKind.due => Icons.error_outline_rounded,
    _ => null,
  };

  /// Spoken form — screen readers get the meaning, not the glyph.
  String get spoken => switch (kind) {
    MallAmountKind.refund => '$label, $value refunded',
    MallAmountKind.due => '$label, $value still due',
    MallAmountKind.deduction => '$label, minus $value',
    _ => '$label, $value',
  };
}

/// A block of amounts with one rhythm: labels left, tabular figures right,
/// a hairline above the total, emphasis reserved for the figures that change
/// what the buyer does.
class MallMoneyLedger extends StatelessWidget {
  const MallMoneyLedger({
    required this.amounts,
    super.key,
    this.semanticLabel,
  });

  final List<MallAmount> amounts;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (amounts.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < amounts.length; i++) ...[
            if (amounts[i].kind == MallAmountKind.total && i > 0) ...[
              const SizedBox(height: DesignTokens.s12),
              const Divider(
                height: 1,
                thickness: 1,
                color: DesignTokens.borderDefault,
              ),
              const SizedBox(height: DesignTokens.s12),
            ] else if (i > 0)
              const SizedBox(height: DesignTokens.s8),
            MallAmountRow(amount: amounts[i]),
          ],
        ],
      ),
    );
  }
}

/// One ledger row. Public so a screen can drop a single amount into an
/// existing card without building a whole ledger.
class MallAmountRow extends StatelessWidget {
  const MallAmountRow({required this.amount, super.key});

  final MallAmount amount;

  ({Color labelColor, Color valueColor, double valueSize, FontWeight weight})
  get _style => switch (amount.kind) {
    MallAmountKind.line => (
      labelColor: DesignTokens.textMuted,
      valueColor: DesignTokens.textLight,
      valueSize: 13.0,
      weight: FontWeight.w500,
    ),
    MallAmountKind.deduction => (
      labelColor: DesignTokens.textMuted,
      valueColor: DesignTokens.primaryGreen,
      valueSize: 13.0,
      weight: FontWeight.w500,
    ),
    MallAmountKind.total => (
      labelColor: DesignTokens.textWhite,
      valueColor: DesignTokens.textWhite,
      valueSize: 18.0,
      weight: FontWeight.w700,
    ),
    MallAmountKind.refund => (
      labelColor: DesignTokens.textLight,
      valueColor: DesignTokens.primaryGreen,
      valueSize: 16.0,
      weight: FontWeight.w700,
    ),
    MallAmountKind.due => (
      labelColor: DesignTokens.textLight,
      valueColor: DesignTokens.warning300,
      valueSize: 16.0,
      weight: FontWeight.w700,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final note = amount.note;
    final glyph = amount.glyph;
    final glyphMark = glyph == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(end: 4, top: 2),
            child: Icon(glyph, size: 14, color: style.valueColor),
          );
    return Semantics(
      label: [amount.spoken, ?note].join('. '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount.label,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: amount.kind == MallAmountKind.total ? 15 : 13,
                    fontWeight: amount.kind == MallAmountKind.total
                        ? FontWeight.w600
                        : FontWeight.w400,
                    height: 1.35,
                    color: style.labelColor,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 11.5,
                      height: 1.35,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          ?glyphMark,
          // The value gets its own flex: at 1.3x a long label and a long
          // amount would otherwise push each other off the row.
          Flexible(
            child: Text(
              '${amount.prefix}${amount.value}',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: style.valueSize,
                fontWeight: style.weight,
                height: 1.3,
                color: style.valueColor,
                fontFeatures: mallTabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
