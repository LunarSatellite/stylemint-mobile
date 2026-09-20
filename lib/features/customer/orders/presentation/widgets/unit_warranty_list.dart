import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_eligibility.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The warranties on one order line, when that line's goods carry markers.
///
/// A line for three identical shirts is one row in the order, but three
/// garments. Each was tagged separately by someone holding it, so each has its
/// own clock, its own claim slot and its own history. This widget renders them
/// as what they are — separate warranties — and never as one warranty with a
/// quantity beside it.
///
/// It is only ever built for a line that actually has units. A line with no
/// marker keeps the single line-level chip it has always had; that is the
/// right answer for almost all stock, not a lesser one.
class UnitWarrantyList extends StatelessWidget {
  const UnitWarrantyList({
    required this.units,
    this.onOpenUnit,
    super.key,
  });

  final List<WarrantyUnitEligibility> units;

  /// Opens one unit's claim history. Null omits the control.
  final void Function(WarrantyUnitEligibility unit)? onOpenUnit;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          units.length == 1
              ? 'This item is tagged, so its warranty follows the item itself.'
              : 'Each of these ${units.length} items was tagged separately '
                    'and has its own warranty. A claim on one does not cover '
                    'the others.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        for (var i = 0; i < units.length; i++) ...[
          const SizedBox(height: DesignTokens.s8),
          _UnitWarrantyRow(
            unit: units[i],
            position: i + 1,
            total: units.length,
            onOpen: onOpenUnit,
          ),
        ],
      ],
    );
  }
}

class _UnitWarrantyRow extends StatelessWidget {
  const _UnitWarrantyRow({
    required this.unit,
    required this.position,
    required this.total,
    required this.onOpen,
  });

  final WarrantyUnitEligibility unit;
  final int position;
  final int total;
  final void Function(WarrantyUnitEligibility unit)? onOpen;

  @override
  Widget build(BuildContext context) {
    final handler = onOpen;
    return Semantics(
      container: true,
      label: total == 1
          ? 'Warranty for the tagged item'
          : 'Warranty for item $position of $total',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap, not Row: at 320dp with text at 1.3x the label and the
            // reference will not sit side by side.
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  total == 1 ? 'Tagged item' : 'Item $position of $total',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unit.markerReference.isNotEmpty)
                  Text(
                    unit.markerReference,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            _CoverageLine(unit: unit),
            if (unit.hasOpenClaim) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                total == 1
                    ? 'A claim is open on this item.'
                    : 'A claim is open on this item only.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (unit.statusExplanation.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              // The backend's own sentence, verbatim. It knows whether cover
              // has run out, whether a claim is already open and why; a
              // paraphrase here is how a screen tells a buyer something that
              // is not true.
              Text(
                unit.statusExplanation,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ],
            if (handler != null && unit.unitMarkerBindingId.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s8),
              OutlinedButton(
                onPressed: () => handler(unit),
                style: DesignTokens.outlinedButtonStyle(),
                child: Text(
                  'View this item’s claims',
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What cover this unit has, or the plain statement that its start was never
/// recorded.
///
/// There is no third branch. Where neither a delivery nor a handover binding
/// exists the platform does not know when cover began, and the order date is
/// **not** a stand-in: a warranty with no start is not a warranty, and
/// printing a date the record does not hold would be a fabricated fact shown
/// to a customer.
class _CoverageLine extends StatelessWidget {
  const _CoverageLine({required this.unit});

  final WarrantyUnitEligibility unit;

  @override
  Widget build(BuildContext context) {
    if (!unit.hasRecordedStart) {
      return Text(
        'Start date not recorded, so cover cannot be dated. Ask the seller '
        'to record the delivery or handover for this item.',
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      );
    }

    final format = DateFormat('MMM d, y');
    final start = format.format(unit.coverageStartsUtc!.toLocal());
    final ends = unit.coverageEndsUtc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ends == null
              ? 'Cover started $start.'
              : 'Cover runs to ${format.format(ends.toLocal())}.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        Text(
          'Counted from ${unit.clockBasis!.noun} on $start.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }
}
