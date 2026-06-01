import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/entities/group_cart.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class GroupCartItemTile extends StatelessWidget {
  const GroupCartItemTile({super.key, required this.item, this.onRemove});

  final GroupCartItem item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              item.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: DesignTokens.mediumSemibold),
                const SizedBox(height: 4),
                Text('Added by ${item.addedByName}',
                    style: DesignTokens.smallRegular),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('x${item.quantity}', style: DesignTokens.mediumSemibold),
              const SizedBox(height: 4),
              Text(formatMoney(item.unitPrice),
                  style: DesignTokens.mediumRegular.copyWith(
                      color: DesignTokens.primaryGreen)),
            ],
          ),
          if (onRemove != null) ...[
            const SizedBox(width: DesignTokens.s8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: DesignTokens.colorError),
              iconSize: 20,
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}
