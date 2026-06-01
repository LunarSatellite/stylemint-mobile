import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class LedgerEntryTile extends StatelessWidget {
  const LedgerEntryTile({super.key, required this.entry});

  final EarningsLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPositive = entry.type != LedgerEntryType.payout;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          _EntryIcon(type: entry.type),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.description, style: DesignTokens.mediumSemibold),
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
              color: isPositive
                  ? DesignTokens.primaryGreen
                  : DesignTokens.colorError,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _EntryIcon extends StatelessWidget {
  const _EntryIcon({required this.type});

  final LedgerEntryType type;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (type) {
      LedgerEntryType.commission => (Icons.shopping_bag, DesignTokens.primaryGreen),
      LedgerEntryType.payout => (Icons.account_balance_wallet, DesignTokens.warning500),
      LedgerEntryType.bonus => (Icons.stars, DesignTokens.colorInfo),
      LedgerEntryType.adjustment => (Icons.tune, DesignTokens.textMuted),
    };

    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
