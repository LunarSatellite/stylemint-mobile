import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/refill_plan_dto.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One line of a prepared refill basket.
///
/// Four rules decide everything this widget draws.
///
/// **An excluded line is visibly excluded.** `included == false` gets a
/// caution pill and the server's own `excludedReason`, and its figures are
/// never folded into any total. It is shown because the customer is owed the
/// explanation, not because it is nearly in.
///
/// **A null price is rendered as nothing, never as a number.** `notVerified`
/// arrives with `currentPrice == null` because the platform could not read it.
/// Drawing "Rs 0" or quietly reusing what they last paid would both be the
/// client inventing a fact.
///
/// **A price change shows both prices.** `lastPaidPrice` and `currentPrice`
/// sit side by side and labelled. One number would hide the very change the
/// customer opened this screen to see.
///
/// **No photograph.** The Mall is typographic outside product detail (owner
/// directive, 2026-09-16); the line's `thumbnailUrl` is carried on the DTO and
/// deliberately never drawn.
///
/// Nothing here carries a confidence, score or rank. Those are not on the
/// payload and are not reconstructed: the steadiness rule the customer set is
/// the only form that gate takes on a screen.
class RefillPlanLineTile extends StatelessWidget {
  const RefillPlanLineTile({
    required this.line,
    required this.onOpenProduct,
    super.key,
  });

  final RefillPlanLineDto line;
  final VoidCallback onOpenProduct;

  @override
  Widget build(BuildContext context) {
    final excluded = !line.included;
    final variant = line.variantLabel?.trim();

    return Semantics(
      container: true,
      label: _spokenLabel,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: excluded
                ? DesignTokens.borderDefault
                : DesignTokens.borderDefault.withValues(alpha: 0.6),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            onTap: onOpenProduct,
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title and status stack rather than share a row: at a
                  // large text scale on a 320dp phone a long status beside a
                  // long product name has nowhere to go, and a truncated
                  // "Not checked" is exactly the fact that must not be lost.
                  Text(
                    line.productName,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: excluded
                          ? DesignTokens.textMuted
                          : DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MallStatusPill(
                      label: _statusLabel,
                      tone: _statusTone,
                      dense: true,
                      semanticLabel: _statusLabel,
                    ),
                  ),
                  if (variant != null && variant.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      variant,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.s8),
                  _PriceFacts(line: line),
                  const SizedBox(height: DesignTokens.s8),
                  // The server's own reason line, shown as it was sent. The
                  // client does not rewrite it and does not sharpen it.
                  Text(
                    line.reason,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      height: 1.35,
                    ),
                  ),
                  if (excluded) ...[
                    const SizedBox(height: DesignTokens.s8),
                    _ExcludedNote(line: line),
                  ],
                  if (line.alternatives.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s8),
                    _Alternatives(line: line),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _statusLabel => switch (line.checkKind) {
    RefillLineCheck.ready => 'In this basket',
    RefillLineCheck.priceChanged => 'Price changed',
    RefillLineCheck.outOfStock => 'Not enough in stock',
    RefillLineCheck.variantUnavailable => 'Option unavailable',
    RefillLineCheck.notVerified => 'Not checked',
  };

  MallStatusTone get _statusTone => switch (line.checkKind) {
    RefillLineCheck.ready => MallStatusTone.success,
    RefillLineCheck.priceChanged => MallStatusTone.caution,
    _ => MallStatusTone.neutral,
  };

  /// What a screen-reader user hears first: whether this line is in the
  /// basket, then the item, then the quantity. The kind of row comes before
  /// what it sells.
  String get _spokenLabel {
    final variant = (line.variantLabel ?? '').trim();
    return [
      if (line.included) 'In this basket' else 'Left out of this basket',
      line.productName,
      if (variant.isNotEmpty) variant,
      'quantity ${line.quantity}',
    ].join(', ');
  }
}

/// The money facts for one line.
///
/// `priceChanged` draws **both** figures, each labelled. Everything else
/// draws what it can honestly draw: `currentPrice` when the server sent one,
/// and a plain "Price not checked" when it did not — no number, no zero, no
/// fallback to what they last paid dressed up as today's price.
class _PriceFacts extends StatelessWidget {
  const _PriceFacts({required this.line});

  final RefillPlanLineDto line;

  @override
  Widget build(BuildContext context) {
    final lastPaid = formatMoney(
      Money(amount: line.lastPaidPrice, currency: line.lastPaidCurrency),
    );
    final current = line.currentPrice;
    final currentText = current == null
        ? null
        : formatMoney(
            Money(
              amount: current,
              currency: line.currentCurrency ?? line.lastPaidCurrency,
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Quantity ${line.quantity}',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s6),
        if (line.showsBothPrices)
          // Side by side, so the change is the fact on the screen rather than
          // something the customer has to remember.
          Wrap(
            spacing: DesignTokens.s12,
            runSpacing: DesignTokens.s4,
            children: [
              _PriceFact(label: 'You last paid', value: lastPaid),
              _PriceFact(
                label: 'Now',
                value: currentText!,
                emphasised: true,
              ),
            ],
          )
        else if (currentText != null)
          _PriceFact(label: 'Price now', value: currentText, emphasised: true)
        else
          // A price the platform could not read. Said as a gap, because it
          // is one.
          Text(
            'Price not checked',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

class _PriceFact extends StatelessWidget {
  const _PriceFact({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    excludeSemantics: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        Text(
          value,
          style: DesignTokens.smallRegular.copyWith(
            color: emphasised ? DesignTokens.textWhite : DesignTokens.textLight,
            fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

/// Why this line is not in the basket, in the server's words.
///
/// The backend writes the sentence (`excludedReason`); the client does not
/// paraphrase it and does not soften it. When the server sent no sentence the
/// widget states the plain fact instead of inventing a cause.
class _ExcludedNote extends StatelessWidget {
  const _ExcludedNote({required this.line});

  final RefillPlanLineDto line;

  @override
  Widget build(BuildContext context) {
    final reason = line.excludedReason?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s8),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Left out of this basket',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              reason,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Other options the seller has, offered only because the customer switched
/// substitutions on.
///
/// **Nothing here is selected and nothing swaps itself.** Each is a link to
/// that option's own page, so the choice is made where the customer can see
/// everything about it. Silence is a no.
class _Alternatives extends StatelessWidget {
  const _Alternatives({required this.line});

  static String _money(RefillAlternativeDto alternative) => formatMoney(
    Money(amount: alternative.price, currency: alternative.currency),
  );

  final RefillPlanLineDto line;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Other options you could pick yourself',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textLight,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: DesignTokens.s4),
      for (final alternative in line.alternatives)
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            '${alternative.sku} — ${_money(alternative)}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      const SizedBox(height: 2),
      Text(
        'We never swap one for another — picking is yours.',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
      ),
    ],
  );
}
