import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    super.key,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: DesignTokens.s20),
        color: DesignTokens.colorError,
        child: const Icon(Icons.delete_outline, color: DesignTokens.textWhite),
      ),
      child: Container(
        color: DesignTokens.bgAppFoundation,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(DesignTokens.s12),
                    child: Image.network(
                      item.productImageUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        color: DesignTokens.bgAppBodyLight,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: DesignTokens.iconLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          item.variantName,
                          style: DesignTokens.smallRegular.copyWith(
                            fontSize: 11,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        if (item.creatorHandle != null) ...[
                          const SizedBox(height: DesignTokens.s4),
                          Text(
                            'From: @${item.creatorHandle}'
                            '${item.commissionRate != null ? ' (${(item.commissionRate! * 100).round()}% Commission)' : ''}',
                            style: DesignTokens.smallRegular.copyWith(
                              fontSize: 11,
                              color: DesignTokens.textLight,
                            ),
                          ),
                        ],
                        const SizedBox(height: DesignTokens.s4),
                        GestureDetector(
                          onTap: () {
                            // TODO(cart): save for later
                          },
                          child: Text(
                            'Save for later',
                            style: DesignTokens.smallRegular.copyWith(
                              fontSize: 12,
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                        if (!item.isInStock) ...[
                          const SizedBox(height: DesignTokens.s4),
                          Text(
                            'Out of stock',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.colorError,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  // Stepper + price stacked on the right
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _QuantityStepper(
                        quantity: item.quantity,
                        onIncrement: item.isInStock ? onIncrement : null,
                        onDecrement: onDecrement,
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      Text(
                        formatMoney(item.unitPrice),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              color: DesignTokens.borderDefault,
              height: 1,
              thickness: 1,
              indent: DesignTokens.s16,
              endIndent: DesignTokens.s16,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: DesignTokens.buttonGrayFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onPressed: onDecrement),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onPressed: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(DesignTokens.s4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 16,
          color: onPressed != null
              ? DesignTokens.textWhite
              : DesignTokens.iconLight,
        ),
      ),
    );
  }
}
