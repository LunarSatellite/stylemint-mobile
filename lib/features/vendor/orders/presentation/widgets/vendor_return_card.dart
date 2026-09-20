import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/returns/return_evidence_section.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One return request in the vendor's returns workspace — the seller's
/// return detail. Public so tests can prove it renders the evidence snapshot
/// exactly as the buyer's return detail does.
class VendorReturnCard extends StatelessWidget {
  const VendorReturnCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
    super.key,
  });

  final VendorReturnRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (request.state) {
      VendorReturnRequestState.submitted => (
        'Needs review',
        DesignTokens.warning500,
      ),
      VendorReturnRequestState.approved => (
        'Awaiting return',
        DesignTokens.primaryGreen,
      ),
      VendorReturnRequestState.rejected => (
        'Rejected',
        DesignTokens.colorError,
      ),
      VendorReturnRequestState.completed => (
        'Refund started',
        DesignTokens.primaryGreen,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.productTitleSnapshot,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: DesignTokens.smallRegular.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${request.orderNumber} · Qty ${request.quantity}'
            '${request.variantLabelSnapshot == null ? '' : ' · '
                      '${request.variantLabelSnapshot}'}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(request.reason, style: DesignTokens.smallRegular),
          if (request.rejectionNote != null) ...[
            const SizedBox(height: 8),
            Text(
              request.rejectionNote!,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.colorError,
              ),
            ),
          ],
          if (request.evidence != null) ...[
            const SizedBox(height: 12),
            // The buyer sees this exact widget, with this exact wording, on
            // their own return detail. Same facts, same findings, both sides.
            ReturnEvidenceSection(evidence: request.evidence),
          ],
          if (request.state == VendorReturnRequestState.submitted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onApprove,
                    child: Text(busy ? 'Working…' : 'Approve'),
                  ),
                ),
              ],
            ),
          ],
          if (request.state == VendorReturnRequestState.approved) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onComplete,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Received · complete & refund'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
