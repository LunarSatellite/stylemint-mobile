import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onSaveForLater,
    super.key,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDelete;
  final VoidCallback onSaveForLater;

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
                vertical: DesignTokens.s16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image — fixed square so every row's text column
                  // starts on the same left edge, with a branded placeholder
                  // that occupies the box before the bitmap lands so nothing
                  // reflows on load.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                    child: SizedBox(
                      width: DesignTokens.thumbSmall,
                      height: DesignTokens.thumbSmall,
                      child: MallNetworkImage(url: item.productImageUrl),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  // Everything to the right of the thumbnail is one column:
                  // name + price share the top line (the two things a shopper
                  // checks), details step down beneath them, and the controls
                  // sit at the bottom with room to be real targets.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: DesignTokens.mediumSemibold,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.s8),
                            // The price shrinks to fit rather than
                            // ellipsising or pushing past the tile — the same
                            // treatment the cart's Grand Total gets.
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  formatMoney(item.unitPrice),
                                  style: DesignTokens.moneyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          item.variantName,
                          style: DesignTokens.smallRegular,
                        ),
                        if (item.creatorHandle != null) ...[
                          const SizedBox(height: DesignTokens.s4),
                          Text(
                            'From: @${item.creatorHandle}'
                            '${item.commissionRate != null ? ' (${(item.commissionRate! * 100).round()}% Commission)' : ''}',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        ],
                        if (!item.isInStock) ...[
                          const SizedBox(height: DesignTokens.s6),
                          Text(
                            'Out of stock',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.colorError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: DesignTokens.s12),
                        // Wrap, not Row: at 320dp x 1.3 the stepper and the
                        // link no longer share a line, and a Row would
                        // overflow rather than stack them.
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: DesignTokens.s8,
                          runSpacing: DesignTokens.s8,
                          children: [
                            _QuantityStepper(
                              quantity: item.quantity,
                              onIncrement: item.isInStock ? onIncrement : null,
                              onDecrement: onDecrement,
                            ),
                            _SaveForLaterButton(onTap: onSaveForLater),
                          ],
                        ),
                      ],
                    ),
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

class _SaveForLaterButton extends StatelessWidget {
  const _SaveForLaterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.s8,
            horizontal: DesignTokens.s6,
          ),
          child: Text(
            'Save for later',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
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
    return Material(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onPressed: onDecrement),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: DesignTokens.s24),
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: DesignTokens.mediumSemibold,
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
    return InkResponse(
      onTap: onPressed,
      radius: DesignTokens.minTouchTarget / 2,
      child: SizedBox(
        // iOS HIG minimum — the old 28dp pill was a hairline target.
        width: DesignTokens.minTouchTarget,
        height: DesignTokens.minTouchTarget,
        child: Icon(
          icon,
          size: DesignTokens.iconSmall,
          color: onPressed != null
              ? DesignTokens.textWhite
              : DesignTokens.iconLight,
        ),
      ),
    );
  }
}
