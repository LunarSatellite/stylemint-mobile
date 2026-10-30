import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/delivery_confirm_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_handover_confirm.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_reason_category_picker.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_delivery_partner_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/live_refresh.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the rider sheet for a return. Overridable so widget tests need no
/// bottom sheet.
typedef ReturnRiderSheetOpener =
    Future<void> Function(
      BuildContext context, {
      required String returnRequestId,
      bool reopen,
    });

/// Reads one approved return's rider pickup and hands its card the panel and
/// whether "Mark received" must wait. Anything else — not approved, no
/// pickup, an older backend — builds the card exactly as before.
class VendorReturnPickupScope extends ConsumerWidget {
  const VendorReturnPickupScope({
    required this.request,
    required this.builder,
    super.key,
  });

  final VendorReturnRequest request;
  final Widget Function(Widget? pickupPanel, bool completeLocked) builder;

  /// Stands in for a return that has no pickup yet.
  static ReturnPickup noPickupYet(String returnRequestId) => ReturnPickup(
    id: '',
    returnRequestId: returnRequestId,
    trackingNumber: '',
    status: ReturnPickupStatus.requested,
    originAddressLine: '',
    destinationAddressLine: '',
    requestedUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    mode: ReturnPickupMode.legacy,
  );

  /// From the list row alone, when the pickup itself could not be read: a
  /// rider stage other than "received" holds completion back — Cancelled
  /// too, as the server still refuses it (return fixes contract C).
  static bool lockedByListStage(String? pickupStage) {
    final stage = ReturnPickupStage.fromWire(pickupStage);
    return stage != null &&
        stage != ReturnPickupStage.unknown &&
        stage != ReturnPickupStage.receivedBySeller;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (request.state != VendorReturnRequestState.approved) {
      return builder(null, false);
    }
    final provider = vendorReturnPickupProvider(request.id);
    final read = ref.watch(provider);
    // No pickup on a backend that has rider pickups (the row carries the
    // `pickupStage` key): offer "Find a rider", as for a Legacy return.
    final pickup =
        read.asData?.value ??
        (read.hasValue && request.pickupAware && request.pickupStage == null
            ? noPickupYet(request.id)
            : null);
    final showPanel = pickup != null && (pickup.isRider || pickup.isLegacy);
    final locked =
        pickup?.blocksSellerCompletion ?? lockedByListStage(request.pickupStage);
    final stage = pickup?.stage;
    final card = builder(
      showPanel
          ? VendorReturnPickupPanel(returnRequestId: request.id, pickup: pickup)
          : null,
      locked,
    );
    if (!showPanel) return card;
    return LiveRefresh(
      scopes: const {LiveScope.vendorOrders},
      interval: stage == null || stage.isSettled
          ? null
          : const Duration(seconds: 20),
      onRefresh: () async {
        ref.invalidate(provider);
        await ref.read(provider.future);
      },
      child: card,
    );
  }
}

/// The seller's side of a rider return pickup, on the return's card
/// (return pickup contract §3 and §9): who is being asked, choosing a rider,
/// "Try again" when nobody came, "Find a rider" on a Legacy return, and
/// scanning the rider's code when they bring it back.
class VendorReturnPickupPanel extends ConsumerWidget {
  const VendorReturnPickupPanel({
    required this.returnRequestId,
    required this.pickup,
    this.openSheet = showVendorReturnPickupSheet,
    this.scanner = scanRiderDeliveryQr,
    super.key,
  });

  final String returnRequestId;
  final ReturnPickup pickup;
  final ReturnRiderSheetOpener openSheet;
  final DeliveryQrScanner scanner;

  static const actionKey = ValueKey<String>('vendor-return-pickup-action');

  /// The seller's headline for where the pickup stands.
  static String headline(ReturnPickup pickup) {
    final rider = pickup.rider?.displayName;
    if (pickup.isLegacy &&
        (pickup.stage == null || pickup.stage == ReturnPickupStage.unknown)) {
      return 'No rider asked yet';
    }
    return switch (pickup.stage) {
      ReturnPickupStage.searchingRider => 'Asking riders near the buyer',
      ReturnPickupStage.ridersInterested => 'Riders are interested. Choose one',
      ReturnPickupStage.noRiders => 'No rider yet',
      ReturnPickupStage.riderAssigned =>
        rider == null ? 'A rider is going to the buyer' : '$rider is going to the buyer',
      ReturnPickupStage.awaitingBuyerConfirmation => 'Rider is at the buyer',
      ReturnPickupStage.collected => 'Rider is bringing your return',
      ReturnPickupStage.awaitingSellerConfirmation =>
        "Rider is here. Scan the rider's code",
      ReturnPickupStage.receivedBySeller =>
        'Return received. Check it, then mark it received',
      ReturnPickupStage.attemptFailed => "Rider couldn't collect",
      ReturnPickupStage.cancelled => 'Return cancelled',
      ReturnPickupStage.needsSupport => "We're looking into it",
      ReturnPickupStage.unknown || null => pickup.status.label,
    };
  }

  /// The one button for where the pickup stands, or null.
  static ({String label, bool reopen})? actionFor(ReturnPickup pickup) {
    final stage = pickup.stage;
    if (pickup.isLegacy &&
        (stage == null || stage == ReturnPickupStage.unknown)) {
      return (label: 'Find a rider', reopen: true);
    }
    if (!pickup.isRider && !pickup.isLegacy) return null;
    return switch (stage) {
      ReturnPickupStage.searchingRider => (label: 'See riders', reopen: false),
      ReturnPickupStage.ridersInterested => (
        label: 'Choose a rider',
        reopen: false,
      ),
      ReturnPickupStage.noRiders ||
      ReturnPickupStage.attemptFailed => (label: 'Try again', reopen: true),
      _ => null,
    };
  }

  static String? fareLine(ReturnPickupFare? fare) {
    if (fare == null) return null;
    final amount = fare.amount;
    return switch (fare.payer) {
      ReturnFarePayer.seller =>
        amount == null
            ? 'You pay the pickup.'
            : 'You pay the pickup: ${formatFare(amount)}.',
      ReturnFarePayer.buyer => 'The buyer pays the pickup from the refund.',
      ReturnFarePayer.unknown => null,
    };
  }

  void _refresh(WidgetRef ref) {
    ref
      ..invalidate(vendorReturnPickupProvider(returnRequestId))
      ..invalidate(vendorReturnsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = pickup.stage;
    final action = actionFor(pickup);
    final fare = fareLine(pickup.fare);
    final rider = pickup.rider;
    final atShop =
        pickup.isRider &&
        (stage == ReturnPickupStage.collected ||
            stage == ReturnPickupStage.awaitingSellerConfirmation);
    final negative =
        stage == ReturnPickupStage.cancelled ||
        stage == ReturnPickupStage.attemptFailed ||
        stage == ReturnPickupStage.noRiders;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.two_wheeler_rounded,
                size: 18,
                color: negative
                    ? DesignTokens.warning500
                    : DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  headline(pickup),
                  style: DesignTokens.mediumSemibold,
                ),
              ),
            ],
          ),
          if (rider != null && stage != null && stage.riderOnJob) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              [
                rider.displayName,
                if (rider.rating case final r?) '★ ${r.toStringAsFixed(1)}',
                ?rider.vehicle,
              ].join(' · '),
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textLight),
            ),
          ],
          if (stage == ReturnPickupStage.attemptFailed &&
              pickup.failedAttempts > 0) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Attempt ${pickup.failedAttempts} of ${pickup.maxAttempts}.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
          if (fare != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              fare,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: DesignTokens.s12),
            FilledButton.icon(
              key: actionKey,
              onPressed: () async {
                await openSheet(
                  context,
                  returnRequestId: returnRequestId,
                  reopen: action.reopen,
                );
                _refresh(ref);
              },
              icon: const Icon(Icons.two_wheeler_rounded),
              label: Text(action.label),
            ),
          ],
          if (atShop) ...[
            const SizedBox(height: DesignTokens.s12),
            ReturnHandoverConfirm(
              confirmKey: 'vendor-return-$returnRequestId',
              packageNumber: pickup.trackingNumber,
              seller: true,
              scanner: scanner,
              onConfirmed: () async => _refresh(ref),
            ),
          ],
        ],
      ),
    );
  }
}
