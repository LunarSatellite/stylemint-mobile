import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_confirm_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_handover_confirm.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_reason_category_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The buyer's side of a rider return pickup (return pickup contract §3):
/// where it stands, who is coming, the handover scan when the rider is at
/// the door, and the buyer's two actions — cancel, and send a rider again.
///
/// Only for a pickup that carries a `stage`; an older payload keeps the
/// plain status card on the return screen.
class ReturnPickupSection extends ConsumerWidget {
  const ReturnPickupSection({
    required this.pickup,
    required this.onChanged,
    this.scanner = scanRiderDeliveryQr,
    super.key,
  });

  final ReturnPickup pickup;

  /// Re-reads the return and the pickup after anything changed.
  final Future<void> Function() onChanged;
  final DeliveryQrScanner scanner;

  static const sendAgainKey = ValueKey<String>('return-pickup-send-again');
  static const cancelKey = ValueKey<String>('return-pickup-cancel');
  static const confirmCancelKey = ValueKey<String>(
    'return-pickup-confirm-cancel',
  );

  /// The buyer's headline for [stage].
  static String headline(ReturnPickup pickup) {
    final rider = pickup.rider?.displayName;
    return switch (pickup.stage) {
      ReturnPickupStage.searchingRider ||
      ReturnPickupStage.ridersInterested =>
        'Finding a rider to collect your return',
      ReturnPickupStage.noRiders => 'Still looking for a rider',
      ReturnPickupStage.riderAssigned =>
        rider == null
            ? 'A rider is coming to collect it'
            : '$rider is coming to collect it',
      ReturnPickupStage.awaitingBuyerConfirmation =>
        "Scan the rider's code to hand over",
      ReturnPickupStage.collected ||
      ReturnPickupStage.awaitingSellerConfirmation =>
        'On the way to the seller',
      ReturnPickupStage.receivedBySeller =>
        'The seller has it. Refund after inspection',
      ReturnPickupStage.attemptFailed => "Rider couldn't collect",
      ReturnPickupStage.cancelled => 'Return cancelled',
      ReturnPickupStage.needsSupport => "We're looking into it",
      ReturnPickupStage.unknown || null => pickup.status.label,
    };
  }

  /// Who pays the rider, in one line; null when the server did not say.
  static String? fareLine(ReturnPickupFare? fare) {
    if (fare == null) return null;
    switch (fare.payer) {
      case ReturnFarePayer.seller:
        return 'No pickup fee: the seller pays it.';
      case ReturnFarePayer.buyer:
        final amount = fare.amount;
        final upTo = fare.upTo;
        if (amount != null && fare.isFinal) {
          return 'Pickup fee ${formatFare(amount)} comes off your refund.';
        }
        if (amount != null && upTo != null) {
          return 'Pickup fee about ${formatFare(amount)} '
              '(up to ${formatFare(upTo)}) comes off your refund.';
        }
        if (upTo != null) {
          return 'Up to ${formatFare(upTo)} will be deducted from your '
              'refund for the pickup.';
        }
        return 'The pickup fee comes off your refund.';
      case ReturnFarePayer.unknown:
        return null;
    }
  }

  Future<void> _sendAgain(BuildContext context, WidgetRef ref) async {
    final result = await ref
        .read(returnPickupActionsNotifierProvider.notifier)
        .sendAgain(pickup.returnRequestId);
    if (!context.mounted) return;
    result.fold(
      (failure) =>
          SmSnackbar.error(context, NetworkExceptions.getMessage(failure)),
      (_) => SmSnackbar.success(context, "We're asking riders again."),
    );
    await onChanged();
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        title: const Text('Cancel this return?'),
        content: const Text(
          'You keep the item and no refund is made. The rider is told.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep the return'),
          ),
          FilledButton(
            key: confirmCancelKey,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel return'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(returnPickupActionsNotifierProvider.notifier)
        .cancel(pickup.returnRequestId);
    if (!context.mounted) return;
    result.fold(
      (failure) => SmSnackbar.error(
        context,
        NetworkExceptions.getMessage(failure).isEmpty
            ? "Couldn't cancel. The rider may already have it."
            : NetworkExceptions.getMessage(failure),
      ),
      (_) => SmSnackbar.success(context, 'Return cancelled.'),
    );
    await onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(returnPickupActionsNotifierProvider);
    final stage = pickup.stage;
    final rider = pickup.rider;
    final fare = fareLine(pickup.fare);
    final negative =
        stage == ReturnPickupStage.cancelled ||
        stage == ReturnPickupStage.attemptFailed;
    final done = stage == ReturnPickupStage.receivedBySeller;
    final color = negative
        ? DesignTokens.colorError
        : done
        ? DesignTokens.primaryGreen
        : DesignTokens.warning500;
    final canSendAgain =
        pickup.canRetry ||
        (stage == ReturnPickupStage.attemptFailed && pickup.isRider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                done
                    ? Icons.inventory_2_outlined
                    : negative
                    ? Icons.error_outline_rounded
                    : Icons.two_wheeler_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline(pickup), style: DesignTokens.mediumSemibold),
                  if (pickup.trackingNumber.isNotEmpty)
                    Text(
                      pickup.trackingNumber,
                      style: DesignTokens.smallDescription.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (rider != null && stage != null && stage.riderOnJob) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            [
              rider.displayName,
              if (rider.rating case final r?) '★ ${r.toStringAsFixed(1)}',
              ?rider.vehicle,
            ].join(' · '),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
        if (stage == ReturnPickupStage.attemptFailed &&
            pickup.failedAttempts > 0) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Attempt ${pickup.failedAttempts} of ${pickup.maxAttempts}. '
            'Be home when the next rider comes.',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
        if (fare != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            fare,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
        if (stage == ReturnPickupStage.awaitingBuyerConfirmation) ...[
          const SizedBox(height: DesignTokens.s12),
          ReturnHandoverConfirm(
            confirmKey: 'return-${pickup.returnRequestId}',
            packageNumber: pickup.trackingNumber,
            scanner: scanner,
            onConfirmed: onChanged,
          ),
        ],
        if (canSendAgain) ...[
          const SizedBox(height: DesignTokens.s12),
          FilledButton.icon(
            key: sendAgainKey,
            onPressed: busy ? null : () => _sendAgain(context, ref),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Send a rider again'),
          ),
        ],
        if (pickup.canCancel) ...[
          const SizedBox(height: DesignTokens.s8),
          TextButton(
            key: cancelKey,
            style: TextButton.styleFrom(
              foregroundColor: DesignTokens.colorError,
            ),
            onPressed: busy ? null : () => _cancel(context, ref),
            child: const Text('Cancel return'),
          ),
        ],
      ],
    );
  }
}

/// "Item Rs 2,500 − pickup Rs 150 = refund Rs 2,350".
class ReturnRefundBreakdownLine extends StatelessWidget {
  const ReturnRefundBreakdownLine({required this.breakdown, super.key});

  final ReturnRefundBreakdown breakdown;

  static String text(ReturnRefundBreakdown b) =>
      b.pickupFareDeducted.amount > 0
      ? 'Item ${formatFare(b.itemTotal)} − pickup '
            '${formatFare(b.pickupFareDeducted)} = refund '
            '${formatFare(b.refundAmount)}'
      : 'Refund ${formatFare(b.refundAmount)}';

  @override
  Widget build(BuildContext context) =>
      Text(text(breakdown), style: DesignTokens.mediumSemibold);
}
