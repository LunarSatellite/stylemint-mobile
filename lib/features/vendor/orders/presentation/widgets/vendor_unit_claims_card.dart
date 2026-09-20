import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/warranty_claim_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `GET v1/vendor/warranties/units/{bindingId}/claims` — the claims this
/// seller's own orders carry against one physical item.
///
/// ## What an empty list means, and what it does not
///
/// The route answers with the same empty list for a binding that does not
/// exist, a binding belonging to another seller, and this seller's own unit
/// that has never been claimed on. That is deliberate on the backend: a vendor
/// holding a binding id must not be able to learn whether it names a real
/// unit, or whose. So this card says "no claims on this item" and stops. It
/// must never editorialise that into "no such item" or "not your item",
/// because it cannot tell, and guessing is how a screen tells a seller
/// something that is not true.
class VendorUnitClaimsCard extends ConsumerStatefulWidget {
  const VendorUnitClaimsCard({
    required this.unitMarkerBindingId,
    super.key,
  });

  /// The opaque binding id. The route follows the unit's whole identity chain
  /// server-side, so any binding in the chain returns the same history.
  final String unitMarkerBindingId;

  static const String heading = 'Warranty claims on this item';
  static const String emptyBody = 'No claims on this item.';
  static const String failedBody = 'Could not load claims for this item.';
  static const String retryLabel = 'Try again';

  @override
  ConsumerState<VendorUnitClaimsCard> createState() =>
      _VendorUnitClaimsCardState();
}

class _VendorUnitClaimsCardState extends ConsumerState<VendorUnitClaimsCard> {
  List<WarrantyClaim> _claims = const [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(Future<void>.microtask(_load));
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final raw = await ref
          .read(apiClientProvider)
          .get(
            '/v1/vendor/warranties/units/'
            '${Uri.encodeComponent(widget.unitMarkerBindingId)}/claims',
          );
      final rows = (raw as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(WarrantyClaimDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      if (mounted) setState(() => _claims = rows);
    } on Object catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: DesignTokens.s16),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            VendorUnitClaimsCard.heading,
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s8),
          if (_loading)
            Text(
              'Loading…',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            )
          else if (_failed) ...[
            Text(
              VendorUnitClaimsCard.failedBody,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            OutlinedButton(
              onPressed: () => unawaited(_load()),
              style: DesignTokens.outlinedButtonStyle(),
              child: const Text(VendorUnitClaimsCard.retryLabel),
            ),
          ] else if (_claims.isEmpty)
            Text(
              VendorUnitClaimsCard.emptyBody,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            )
          else
            for (final claim in _claims) _VendorUnitClaimRow(claim: claim),
        ],
      ),
    );
  }
}

class _VendorUnitClaimRow extends StatelessWidget {
  const _VendorUnitClaimRow({required this.claim});

  final WarrantyClaim claim;

  @override
  Widget build(BuildContext context) {
    final unit = claim.unit;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap so nothing collides at 320dp with text at 1.3x.
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
                vendorUnitClaimStateLabel(claim.state),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              Text(
                'Filed ${DateFormat('MMM d, y').format(
                  claim.submittedUtc.toLocal(),
                )}',
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
            // A claim filed before a tag was corrected keeps naming the
            // binding it was filed against. The seller sees that plainly
            // rather than the claim being quietly moved onto the replacement.
            Text(
              unit.supersededUtc == null
                  ? 'Filed against a binding that has since been corrected. '
                        'The claim still names that binding.'
                  : 'Filed against a binding corrected on '
                        '${DateFormat('MMM d, y').format(
                          unit.supersededUtc!.toLocal(),
                        )}. The claim still names that binding.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.warning300,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String vendorUnitClaimStateLabel(WarrantyClaimState state) => switch (state) {
  WarrantyClaimState.submitted => 'Submitted',
  WarrantyClaimState.approved => 'Approved',
  WarrantyClaimState.rejected => 'Rejected',
  WarrantyClaimState.repairInProgress => 'Repair in progress',
  WarrantyClaimState.replacementInProgress => 'Replacement in progress',
  WarrantyClaimState.resolved => 'Resolved',
  WarrantyClaimState.cancelled => 'Cancelled',
  WarrantyClaimState.unknown => 'Status not recognised',
};
