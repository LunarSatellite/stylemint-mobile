import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The claim history of one physical item, for the buyer who owns it.
///
/// Keyed by the binding id, never by the marker value. The server reads the
/// unit's whole identity chain, so a tag that was corrected once still shows
/// one garment's history rather than two halves.
Future<void> showUnitWarrantyClaimsSheet(
  BuildContext context, {
  required String unitMarkerBindingId,
  required String markerReference,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DesignTokens.bgAppBody,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => _UnitWarrantyClaimsList(
    unitMarkerBindingId: unitMarkerBindingId,
    markerReference: markerReference,
  ),
);

class _UnitWarrantyClaimsList extends ConsumerWidget {
  const _UnitWarrantyClaimsList({
    required this.unitMarkerBindingId,
    required this.markerReference,
  });

  final String unitMarkerBindingId;
  final String markerReference;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(
      unitWarrantyClaimsProvider(unitMarkerBindingId),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This item’s claims', style: DesignTokens.titleMedium),
            if (markerReference.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                markerReference,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s12),
            claims.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('Could not load this item’s claims.'),
              data: (items) => items.isEmpty
                  ? Text(
                      'No claims on this item.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    )
                  : Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(
                          color: DesignTokens.borderDefault,
                        ),
                        itemBuilder: (_, index) =>
                            _UnitClaimRow(claim: items[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitClaimRow extends StatelessWidget {
  const _UnitClaimRow({required this.claim});

  final WarrantyClaim claim;

  @override
  Widget build(BuildContext context) {
    final unit = claim.unit;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap so the claim number and its state do not fight for one line
          // at 320dp with text at 1.3x.
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                claim.claimNumber,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                unitClaimStateLabel(claim.state),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          if (claim.description.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              claim.description,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ],
          if (unit != null && !unit.isLive) ...[
            const SizedBox(height: DesignTokens.s4),
            _SupersededNote(unit: unit),
          ],
        ],
      ),
    );
  }
}

/// A claim filed against a tag that was later corrected.
///
/// The claim keeps naming the item it was filed against; it is not moved onto
/// the replacement. Saying so out loud is the point — a silent redirect would
/// be the platform deciding, after the fact, that the buyer meant a different
/// garment.
class _SupersededNote extends StatelessWidget {
  const _SupersededNote({required this.unit});

  final WarrantyClaimUnit unit;

  @override
  Widget build(BuildContext context) {
    final when = unit.supersededUtc;
    final corrected = when == null
        ? 'The tag on this item was corrected after this claim was filed.'
        : 'The tag on this item was corrected on '
              '${DateFormat('MMM d, y').format(when.toLocal())}, after this '
              'claim was filed.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s8),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tag corrected',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            '$corrected The claim still refers to the item it was filed '
            'against, and carries on as it was.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

String unitClaimStateLabel(WarrantyClaimState state) => switch (state) {
  WarrantyClaimState.submitted => 'Submitted',
  WarrantyClaimState.approved => 'Approved',
  WarrantyClaimState.rejected => 'Rejected',
  WarrantyClaimState.repairInProgress => 'Repair in progress',
  WarrantyClaimState.replacementInProgress => 'Replacement in progress',
  WarrantyClaimState.resolved => 'Resolved',
  WarrantyClaimState.cancelled => 'Cancelled',
  // A state this build does not know is named as unknown rather than guessed
  // into one of the others.
  WarrantyClaimState.unknown => 'Status not recognised',
};
