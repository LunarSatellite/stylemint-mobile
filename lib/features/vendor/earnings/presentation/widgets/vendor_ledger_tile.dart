import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorLedgerTile extends StatelessWidget {
  const VendorLedgerTile({super.key, required this.entry});

  final VendorEarningsLedger entry;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (entry.type) {
      VendorLedgerType.sale => (Icons.shopping_bag, DesignTokens.primaryGreen),
      VendorLedgerType.refund => (Icons.undo, DesignTokens.colorError),
      VendorLedgerType.payout => (Icons.account_balance_wallet, DesignTokens.colorInfo),
      VendorLedgerType.fee => (Icons.receipt_long, DesignTokens.warning500),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description.isNotEmpty
                      ? entry.description
                      : entry.type.name,
                  style: DesignTokens.mediumSemibold,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  _formatDate(entry.createdAt),
                  style: DesignTokens.tiny,
                ),
              ],
            ),
          ),
          MoneyText(
            entry.amount,
            style: DesignTokens.oneLinerSemibold.copyWith(
              color: _amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Color get _amountColor {
    return switch (entry.type) {
      VendorLedgerType.sale => DesignTokens.primaryGreen,
      VendorLedgerType.refund => DesignTokens.colorError,
      VendorLedgerType.payout => DesignTokens.colorInfo,
      VendorLedgerType.fee => DesignTokens.warning500,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
