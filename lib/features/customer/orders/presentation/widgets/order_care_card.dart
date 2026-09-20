import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/unit_warranty_list.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

typedef CareActionHandler = void Function(CareItem item);

/// Returns what tapping [action] on [item] should do, or null to omit that
/// button (e.g. the screen has no flow for it).
typedef CareActionResolver =
    CareActionHandler? Function(CareItem item, CareAction action);

/// Voyager "Post-Purchase Care" — a "Care & returns" card listing, per item,
/// the backend's one-sentence guidance, a days-left chip while the return
/// window is open, and buttons for the actions the screen can handle.
/// Supplementary like the cards beside it: renders nothing while loading,
/// on any failure or 404, or when the plan has no items.
class OrderCareCard extends ConsumerWidget {
  const OrderCareCard({
    required this.orderNumber,
    this.resolveAction,
    this.onOpenUnitClaims,
    super.key,
  });

  final String orderNumber;
  final CareActionResolver? resolveAction;

  /// Opens one tagged item's claim history. Null omits that control, which is
  /// also what happens on every line that carries no marker.
  final void Function(WarrantyUnitEligibility unit)? onOpenUnitClaims;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(orderCarePlanProvider(orderNumber)).asData?.value;
    if (plan == null || plan.items.isEmpty) return const SizedBox.shrink();

    // Supplementary, exactly like the care plan itself: null while loading and
    // on any failure, and then every line renders the line-level warranty it
    // has always rendered. An absent answer never becomes a claim about the
    // goods.
    final eligibility = ref
        .watch(warrantyEligibilityProvider(orderNumber))
        .asData
        ?.value;

    final deadline = plan.nextReturnDeadlineUtc;

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.assignment_return_outlined,
                  size: 18,
                  color: DesignTokens.primaryGreen,
                ),
                SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    'Care & returns',
                    style: DesignTokens.sectionInnerTitle,
                  ),
                ),
              ],
            ),
            if (deadline != null) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Next return deadline: '
                '${DateFormat('MMM d').format(deadline.toLocal())}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            for (var i = 0; i < plan.items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: DesignTokens.s24,
                  color: DesignTokens.borderDefault,
                ),
              _CareItemRow(
                item: plan.items[i],
                resolveAction: resolveAction,
                units:
                    eligibility?.unitsForLine(plan.items[i].subOrderLineId) ??
                    const [],
                warranty: eligibility?.itemForLine(
                  plan.items[i].subOrderLineId,
                ),
                onOpenUnitClaims: onOpenUnitClaims,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CareItemRow extends StatelessWidget {
  const _CareItemRow({
    required this.item,
    required this.resolveAction,
    this.units = const [],
    this.warranty,
    this.onOpenUnitClaims,
  });

  final CareItem item;
  final CareActionResolver? resolveAction;

  /// The physical items tagged on this line. Empty on almost every line, and
  /// empty is what keeps the line-level path below untouched.
  final List<WarrantyUnitEligibility> units;

  /// This line's row in the warranty report, or null when the report has not
  /// arrived — while it loads, and after a 404 or an outage.
  ///
  /// Null is not "no warranty". It is "nobody has told us yet", and the two
  /// must render differently: one is a fact about the goods, the other is a
  /// fact about the request.
  final WarrantyEligibilityItem? warranty;
  final void Function(WarrantyUnitEligibility unit)? onOpenUnitClaims;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      for (final action in item.actions)
        if (resolveAction?.call(item, action) case final handler?)
          OutlinedButton(
            onPressed: () => handler(item),
            style: DesignTokens.outlinedButtonStyle(),
            child: Text(
              careActionLabel(action),
              style: DesignTokens.smallRegular.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
    ];
    final daysLeft = item.daysLeftToReturn;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.thumbnailUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              item.thumbnailUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 44,
                height: 44,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(
                  Icons.image,
                  size: 18,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 14,
                ),
              ),
              if (item.variantLabel != null)
                Text(
                  item.variantLabel!,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              if (item.guidance.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s4),
                Text(
                  item.guidance,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
              // Where the goods carry markers the warranty belongs to each
              // physical item, so the single line chip would be a merge of
              // three separate answers. Where they do not — almost always —
              // this branch is not taken and the chip renders exactly as it
              // always has.
              if (units.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s8),
                UnitWarrantyList(units: units, onOpenUnit: onOpenUnitClaims),
              ] else if (item.warrantyEndsUtc case final warrantyEnds?) ...[
                const SizedBox(height: DesignTokens.s8),
                _WarrantyChip(
                  ends: warrantyEnds,
                  inProgress: item.hasOpenWarrantyClaim,
                ),
              ]
              // No tagged items, no coverage date — and, until now, nothing
              // at all. A buyer who was shown this feature saw a blank where
              // it should be, which reads as a broken screen rather than as
              // an answer.
              //
              // The report itself carries the answer: the server writes one
              // sentence per line, and for a line nobody attached a policy to
              // it is "No seller warranty was attached when this item was
              // purchased." It is rendered verbatim, because a client that
              // rephrases a warranty position is a client that eventually
              // states one that is not true.
              //
              // There is deliberately no branch for a null [warranty]. A
              // report that has not arrived is not evidence that cover is
              // absent, and this card is supplementary by design: it says
              // nothing while it does not know, exactly as it does while the
              // care plan itself is loading.
              else if (warranty?.statusExplanation.trim() case final note?
                  when note.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s8),
                _NoWarrantyNote(note: note),
              ],
              if (item.isReturnWindowOpen && daysLeft != null) ...[
                const SizedBox(height: DesignTokens.s8),
                _DaysLeftChip(days: daysLeft),
              ],
              if (buttons.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s8),
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s8,
                  children: buttons,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WarrantyChip extends StatelessWidget {
  const _WarrantyChip({required this.ends, required this.inProgress});

  final DateTime ends;
  final bool inProgress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: DesignTokens.s4,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreen.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 14,
          color: DesignTokens.primaryGreen,
        ),
        const SizedBox(width: DesignTokens.s4),
        // A coverage date must stay readable in full, so the label wraps
        // inside the pill rather than being ellipsised or shrunk.
        Flexible(
          child: Text(
            inProgress
                ? 'Warranty claim in progress'
                : 'Warranty to '
                      '${DateFormat('MMM d, y').format(ends.toLocal())}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// What a line says about its warranty when it has no coverage date and no
/// tagged items — the state that used to render nothing at all.
///
/// Muted, not green, and carrying no shield: this is the platform reporting
/// that it looked and found nothing, not a badge of cover. The sentence is the
/// server's own, rendered verbatim.
class _NoWarrantyNote extends StatelessWidget {
  const _NoWarrantyNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Warranty: $note',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline,
          size: 14,
          color: DesignTokens.textMuted,
        ),
        const SizedBox(width: DesignTokens.s4),
        // The sentence wraps in full. Truncating "No seller warranty was
        // attached…" to its first words is how an absence starts reading as
        // a presence.
        Expanded(
          child: Text(
            note,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DaysLeftChip extends StatelessWidget {
  const _DaysLeftChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final color = days <= 3
        ? DesignTokens.warning500
        : DesignTokens.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, size: 14, color: color),
          const SizedBox(width: DesignTokens.s4),
          // A day count must not be truncated into ambiguity, so it wraps.
          Flexible(
            child: Text(
              daysLeftToReturnLabel(days),
              style: DesignTokens.smallRegular.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "N days left to return"; the backend counts days up, so 0 only appears
/// on the final day.
String daysLeftToReturnLabel(int days) {
  if (days <= 0) return 'Last day to return';
  if (days == 1) return '1 day left to return';
  return '$days days left to return';
}

String careActionLabel(CareAction action) => switch (action) {
  CareAction.track => 'Track package',
  CareAction.returnItem => 'Start a return',
  CareAction.review => 'Write a review',
  CareAction.reorder => 'Buy again',
  CareAction.getHelp => 'Get help',
  CareAction.warrantyClaim => 'Use warranty',
  CareAction.warrantyStatus => 'View warranty claim',
};
