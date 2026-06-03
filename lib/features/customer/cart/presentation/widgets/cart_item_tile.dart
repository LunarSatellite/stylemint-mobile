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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16,
            vertical: DesignTokens.s12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s12),
                child: Image.network(
                  item.productImageUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: DesignTokens.bgAppBodyLight,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: DesignTokens.iconLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
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
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      formatMoney(item.unitPrice),
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                    if (!item.isInStock)
                      Padding(
                        padding: const EdgeInsets.only(top: DesignTokens.s4),
                        child: Text(
                          'Out of stock',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.colorError,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _QuantityStepper(
                quantity: item.quantity,
                onIncrement: item.isInStock ? onIncrement : null,
                onDecrement: onDecrement,
              ),
            ],
          ),
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
      // Spec: filled gray stepper (#3F3F46), fully rounded, ~28px tall, no outline.
      height: 28,
      decoration: BoxDecoration(
        color: DesignTokens.buttonGrayFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onPressed: onDecrement,
          ),
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
          _StepperButton(
            icon: Icons.add,
            onPressed: onIncrement,
          ),
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
