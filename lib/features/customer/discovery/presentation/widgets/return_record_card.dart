import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_return_record.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Return record" on product detail: how often this product and its
/// same-category alternatives came back, from
/// `GET /v1/public/products/{id}/return-record`.
///
/// ## What this card refuses to do
///
/// It replaces a card that drew a blended regret score and a Low/Medium/High
/// chip. That chip was a verdict — on a product, and by implication on the
/// seller behind it — and the blend under it was measured against one
/// universal worst-return-rate constant, so a category that simply comes back
/// more often than another looked worse for being itself. None of that
/// survives here:
///
/// * **No score, level, rank or confidence.** The options are never numbered
///   and never ordered on screen by anything this card computes.
/// * **No rate without its counts.** Every rate is drawn by [_RateWithCounts],
///   which prints the numerator and denominator it came from in the same
///   breath. "3 returns per 100 sold" on its own invites the reader to measure
///   it against a baseline they have imagined; "12 of the 412 sold in the last
///   180 days came back" cannot be misread that way.
/// * **One comparison, and it is within-category.**
///   [ProductReturnOption.comparedWithCategory] is measured against this
///   category's own rate, and the basis block prints that rate with its own
///   counts so the reader can see exactly what the comparison rests on.
/// * **Absence is absence.** An option with no quotable rate is left out
///   rather than drawn as a zero, a dash or an empty slot, and a comparison
///   the server could not make — or that this build does not recognise —
///   draws nothing at all.
/// * **No fault is implied.** Every state is carried by a glyph and a word on
///   a neutral pill. There is no red, no alert glyph and no "risk" wording,
///   because coming back more often than the category is a number a shopper
///   can weigh, not an accusation. The server takes the same position: a
///   product above its category's rate is never demoted, only one below it is
///   ever lifted.
class ReturnRecordCard extends ConsumerWidget {
  const ReturnRecordCard({
    required this.productId,
    this.onOpenProduct,
    super.key,
  });

  final String productId;

  /// Opens another option's product page. Defaults to pushing its route.
  final ValueChanged<String>? onOpenProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref
        .watch(productReturnRecordProvider(productId))
        .asData
        ?.value;
    // Supplementary, like the sections beside it: nothing while loading,
    // nothing on failure, and nothing when no option has a countable record.
    if (record == null || !record.hasQuotableOptions) {
      return const SizedBox.shrink();
    }

    final open =
        onOpenProduct ??
        (id) => context.push(
          RouteNames.productDetail.replaceFirst(':productId', id),
        );
    final viewedId = record.productId.isNotEmpty ? record.productId : productId;
    final options = record.quotableOptions;

    return Container(
      key: const ValueKey('return-record-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(windowDays: record.windowDays),
          const SizedBox(height: DesignTokens.s12),
          _BasisBlock(basis: record.basis, windowDays: record.windowDays),
          const SizedBox(height: DesignTokens.s12),
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0)
              const Divider(
                height: DesignTokens.s24,
                color: DesignTokens.borderDefault,
              ),
            _OptionRow(
              option: options[i],
              windowDays: record.windowDays,
              isViewed: _sameId(options[i].productId, viewedId),
              onOpen: open,
            ),
          ],
        ],
      ),
    );
  }
}

bool _sameId(String a, String b) => a.toLowerCase() == b.toLowerCase();

/// Digits a shopper can read at a glance: 12400 is slower than 12,400.
String formatUnitCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// "12 of the 412 sold in the last 180 days came back", or the no-returns
/// form. Always names both counts and the window they were counted over, so
/// a rate quoted beside it can never float free of its denominator.
String returnCountsSentence({
  required int unitsSold,
  required int unitsReturned,
  required int windowDays,
}) {
  final sold = formatUnitCount(unitsSold);
  final window = 'in the last $windowDays days';
  return unitsReturned == 0
      ? 'None of the $sold sold $window came back'
      : '${formatUnitCount(unitsReturned)} of the $sold sold $window '
            'came back';
}

/// The within-category comparison, in plain words. Null for the two absent
/// cases, which draw nothing rather than a placeholder.
String? categoryComparisonLabel(CategoryComparison comparison) =>
    switch (comparison) {
      CategoryComparison.belowCategoryTypical =>
        'Comes back less often than others in this category',
      CategoryComparison.aboutCategoryTypical =>
        'Comes back about as often as others in this category',
      CategoryComparison.aboveCategoryTypical =>
        'Comes back more often than others in this category',
      CategoryComparison.notEnoughData || CategoryComparison.unknown => null,
    };

/// The glyph that carries the comparison where colour does not. All three
/// share one neutral tone on purpose: tinting "more often" would turn a count
/// into a verdict.
IconData categoryComparisonGlyph(CategoryComparison comparison) =>
    switch (comparison) {
      CategoryComparison.belowCategoryTypical => Icons.south_rounded,
      CategoryComparison.aboveCategoryTypical => Icons.north_rounded,
      _ => Icons.drag_handle_rounded,
    };

class _Header extends StatelessWidget {
  const _Header({required this.windowDays});

  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        'How often these came back, counted within this category over the '
        'last $windowDays days.';
    return Semantics(
      container: true,
      header: true,
      label: 'Return record. $subtitle',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.assignment_return_outlined,
            size: 18,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return record',
                  style: DesignTokens.sectionInnerTitle,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  subtitle,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
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

/// The category's own measured rate — the one thing any comparison below is
/// measured against — printed with the counts it was divided from.
///
/// When the category has not been measured, the server's own reason is
/// printed plainly. It explains why no comparison appears; it is not a
/// result, and nothing about any product is being reported by it.
class _BasisBlock extends StatelessWidget {
  const _BasisBlock({required this.basis, required this.windowDays});

  static const String _qualifier =
      "Each comparison below is against this category's own measured rate, "
      'not an overall standard.';

  static const String _notMeasured =
      "This category's return record has not been measured, so there is "
      'nothing to compare these against.';

  final CategoryReturnBasis basis;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final counts = returnCountsSentence(
      unitsSold: basis.unitsSold,
      unitsReturned: basis.unitsReturned,
      windowDays: windowDays,
    );
    final products = formatUnitCount(basis.productsCounted);
    final perHundred = basis.returnsPerHundredSold;
    final headline = 'In this category: $perHundred returns per 100 sold.';
    final lines = <String>[
      if (basis.hasQuotableRate) ...[
        headline,
        '$counts, across $products products with a sales history.',
        _qualifier,
      ] else
        basis.unavailableReason ?? _notMeasured,
    ];

    return Semantics(
      container: true,
      label: lines.join(' '),
      excludeSemantics: true,
      child: Container(
        key: const ValueKey('return-record-basis'),
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.infoFillDark,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.straighten_rounded,
              size: DesignTokens.iconSmall,
              color: DesignTokens.infoIconLight,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                      child: Text(
                        line,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.infoTextLight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.windowDays,
    required this.isViewed,
    required this.onOpen,
  });

  final ProductReturnOption option;
  final int windowDays;
  final bool isViewed;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final comparison = categoryComparisonLabel(option.comparedWithCategory);
    final split = option.returnedUnits;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(option.productName, style: DesignTokens.mediumSemibold),
                  if (isViewed)
                    const MallStatusPill(
                      label: 'This one',
                      tone: MallStatusTone.neutral,
                      icon: Icons.visibility_outlined,
                      dense: true,
                    ),
                ],
              ),
              const SizedBox(height: DesignTokens.s6),
              _RateWithCounts(option: option, windowDays: windowDays),
              // Absent and unrecognised comparisons draw nothing at all.
              if (comparison != null) ...[
                const SizedBox(height: DesignTokens.s6),
                MallStatusPill(
                  label: comparison,
                  tone: MallStatusTone.neutral,
                  icon: categoryComparisonGlyph(option.comparedWithCategory),
                  dense: true,
                ),
              ],
              // Null for most products: nobody recorded where the units went.
              // Absent is never drawn as "none came back unfit to resell".
              if (split != null) ...[
                const SizedBox(height: DesignTokens.s6),
                _ReturnedUnitsLine(split: split),
              ],
            ],
          ),
        ),
        if (!isViewed)
          const Padding(
            padding: EdgeInsets.only(left: DesignTokens.s8),
            child: Icon(
              Icons.chevron_right,
              size: 20,
              color: DesignTokens.textMuted,
            ),
          ),
      ],
    );

    final spoken = _spoken(comparison, split);

    return KeyedSubtree(
      key: ValueKey('return-record-option-${option.productId}'),
      child: isViewed
          ? Semantics(
              container: true,
              label: spoken,
              excludeSemantics: true,
              child: content,
            )
          : Semantics(
              container: true,
              button: true,
              label: spoken,
              // The row speaks as one sentence, so the InkWell's own
              // semantics are excluded — and the tap action it would have
              // contributed is restated here rather than lost.
              excludeSemantics: true,
              onTap: () => onOpen(option.productId),
              child: InkWell(
                onTap: () => onOpen(option.productId),
                borderRadius: BorderRadius.circular(DesignTokens.s8),
                child: content,
              ),
            ),
    );
  }

  String _spoken(String? comparison, ReturnedUnitSplit? split) => [
    option.productName,
    if (isViewed) 'the product you are viewing',
    '${option.returnsPerHundredSold} returns per 100 sold',
    returnCountsSentence(
      unitsSold: option.unitsSold,
      unitsReturned: option.unitsReturned,
      windowDays: windowDays,
    ),
    ?comparison,
    if (split != null) returnedUnitsSentence(split),
    if (!isViewed) 'Opens this product',
  ].join('. ');
}

/// A rate and the two counts it was divided from, in one widget so that
/// neither can be drawn without the other.
class _RateWithCounts extends StatelessWidget {
  const _RateWithCounts({required this.option, required this.windowDays});

  final ProductReturnOption option;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    // Belt and braces: the card only ever builds this for a quotable option,
    // and it still refuses to draw a bare rate if that stops being true.
    if (!option.hasQuotableRate) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${option.returnsPerHundredSold} returns per 100 sold',
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          returnCountsSentence(
            unitsSold: option.unitsSold,
            unitsReturned: option.unitsReturned,
            windowDays: windowDays,
          ),
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

/// Where the returned units were sent, as counts. Never a cause and never a
/// judgement, which is why [_ReturnedUnitsLine] prints the qualifier under
/// it: "did not go straight back into stock" is otherwise read as "came back
/// broken", and the platform holds no such finding.
String returnedUnitsSentence(ReturnedUnitSplit split) =>
    'Of ${formatUnitCount(split.classifiedReturns)} returned units whose '
    'handling was recorded, ${formatUnitCount(split.fitToResell)} went '
    'straight back into stock and ${formatUnitCount(split.notFitToResell)} '
    'did not';

class _ReturnedUnitsLine extends StatelessWidget {
  const _ReturnedUnitsLine({required this.split});

  static const String _qualifier =
      'This records where a returned unit was sent, not why it came back.';

  final ReturnedUnitSplit split;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${returnedUnitsSentence(split)}.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _qualifier,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
      ],
    );
  }
}
