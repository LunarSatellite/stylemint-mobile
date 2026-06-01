import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TipHistoryTile extends StatelessWidget {
  const TipHistoryTile({super.key, required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(tip.senderAvatarUrl),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tip.senderName, style: DesignTokens.mediumSemibold),
                if (tip.message.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(tip.message,
                      style: DesignTokens.smallRegular,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 2),
                Text(_formatDate(tip.createdAt),
                    style: DesignTokens.tiny),
              ],
            ),
          ),
          Text(formatMoney(tip.amount),
              style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
