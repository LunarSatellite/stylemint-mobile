import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The next-step buttons for a vendor sub-order's current backend state:
/// - Paid / AwaitingFulfillment: Accept and Reject
/// - Accepted: Mark packed
/// - Packed: Hand over, or the existing Mark as Shipped (ready-to-ship)
/// - HandedOver / Shipped / InTransit / OutForDelivery: Mark as Delivered
///
/// Renders nothing for states with no vendor step.
class VendorOrderActionBar extends StatelessWidget {
  const VendorOrderActionBar({
    required this.stateCode,
    required this.onAction,
    super.key,
    this.pendingAction,
    this.busy = false,
  });

  final int stateCode;
  final ValueChanged<VendorOrderAction> onAction;

  /// The action whose request is in flight; its button shows a spinner.
  final VendorOrderAction? pendingAction;

  /// Disables every button while any action runs.
  final bool busy;

  static String labelFor(VendorOrderAction action) => switch (action) {
    VendorOrderAction.accept => 'Accept',
    VendorOrderAction.reject => 'Reject',
    VendorOrderAction.markPacked => 'Mark packed',
    VendorOrderAction.handOver => 'Hand over',
    VendorOrderAction.readyToShip => 'Mark as Shipped',
    VendorOrderAction.markDelivered => 'Mark as Delivered',
  };

  static Key keyFor(VendorOrderAction action) =>
      ValueKey('vendor-action-${action.name}');

  @override
  Widget build(BuildContext context) {
    final actions = vendorActionsForState(stateCode);
    if (actions.isEmpty) return const SizedBox.shrink();

    Widget button(VendorOrderAction action, _Emphasis emphasis) =>
        _ActionButton(
          key: keyFor(action),
          label: labelFor(action),
          emphasis: emphasis,
          loading: pendingAction == action,
          onPressed: busy ? null : () => onAction(action),
        );

    if (actions.contains(VendorOrderAction.accept)) {
      return Row(
        children: [
          Expanded(child: button(VendorOrderAction.reject, _Emphasis.danger)),
          const SizedBox(width: DesignTokens.s12),
          Expanded(child: button(VendorOrderAction.accept, _Emphasis.primary)),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          button(actions[i], i == 0 ? _Emphasis.primary : _Emphasis.secondary),
        ],
      ],
    );
  }
}

enum _Emphasis { primary, secondary, danger }

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.emphasis,
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final _Emphasis emphasis;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (emphasis) {
      _Emphasis.primary => (
        DesignTokens.primaryGreen,
        DesignTokens.buttonPrimaryText,
      ),
      _Emphasis.secondary => (
        DesignTokens.bgAppBodyLight,
        DesignTokens.textWhite,
      ),
      _Emphasis.danger => (
        DesignTokens.colorError.withValues(alpha: 0.14),
        DesignTokens.colorError,
      ),
    };
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: loading ? '$label, in progress' : null,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(
            alpha: emphasis == _Emphasis.primary ? 0.45 : 0.6,
          ),
          disabledForegroundColor: foreground.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        child: loading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
