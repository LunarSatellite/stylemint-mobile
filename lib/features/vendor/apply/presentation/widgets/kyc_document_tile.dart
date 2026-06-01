import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class KycDocumentTile extends StatelessWidget {
  const KycDocumentTile({
    super.key,
    required this.document,
    this.onUpload,
    this.onRetry,
  });

  final KYCDocument? document;
  final VoidCallback? onUpload;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final hasDoc = document != null;
    final status = document?.status;
    final isPending = status == KYCDocumentStatus.pending;
    final isVerified = status == KYCDocumentStatus.verified;
    final isRejected = status == KYCDocumentStatus.rejected;

    final statusColor = isVerified
        ? DesignTokens.colorSuccess
        : isRejected
            ? DesignTokens.colorError
            : DesignTokens.secondaryYellow;

    final statusLabel = isVerified
        ? 'Verified'
        : isRejected
            ? 'Rejected'
            : 'Pending';

    final statusIcon = isVerified
        ? Icons.check_circle
        : isRejected
            ? Icons.error_outline
            : Icons.hourglass_top;

    final actionLabel = hasDoc
        ? (isRejected ? 'Retry' : 'Replace')
        : 'Upload';

    return Container(
      decoration: DesignTokens.cardDecoration(
        borderColor: isVerified
            ? DesignTokens.primaryGreen.withOpacity(0.3)
            : isRejected
                ? DesignTokens.colorError.withOpacity(0.3)
                : null,
      ),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconForType(document?.type),
              color: hasDoc ? DesignTokens.textWhite : DesignTokens.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDoc ? document!.fileName : _labelForType(document?.type),
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: hasDoc ? DesignTokens.textWhite : DesignTokens.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (hasDoc)
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: DesignTokens.smallRegular.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Not uploaded',
                    style: DesignTokens.smallRegular,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: hasDoc && isRejected ? onRetry : onUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s6,
              ),
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                actionLabel,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(KYCDocumentType? type) {
    switch (type) {
      case KYCDocumentType.pan:
        return Icons.credit_card_outlined;
      case KYCDocumentType.citizenship:
        return Icons.badge_outlined;
      case KYCDocumentType.businessReg:
        return Icons.business_outlined;
      case KYCDocumentType.taxDoc:
        return Icons.receipt_long_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _labelForType(KYCDocumentType? type) {
    switch (type) {
      case KYCDocumentType.pan:
        return 'PAN Card';
      case KYCDocumentType.citizenship:
        return 'Citizenship';
      case KYCDocumentType.businessReg:
        return 'Business Registration';
      case KYCDocumentType.taxDoc:
        return 'Tax Document';
      default:
        return 'Document';
    }
  }
}
