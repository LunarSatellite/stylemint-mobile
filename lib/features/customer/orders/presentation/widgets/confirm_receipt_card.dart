import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/parcel_code_scan_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Scan the parcel to confirm it arrived."
///
/// Shown for **every** order whose parcel may be with the buyer, not only
/// those on StyleMint's own delivery network. The existing
/// [DeliveryAcceptanceCard] — the condition report with photos and a
/// per-item check — is rendered behind `trackingNumber.startsWith('SM-D-')`,
/// because it is backed by a Delivery-module package row that only in-house
/// parcels have. An order handed to any other carrier therefore had no way
/// for the receiver to confirm anything at all, and sat in Shipped until a
/// vendor or a courier webhook closed it.
///
/// This card talks to Orders instead of Delivery, so it works for any
/// sub-order: `POST /v1/orders/sub-orders/{id}/confirm-receipt`. The server
/// compares the scanned value against the sub-order's tracking number and
/// rejects a mismatch, so the camera reports and the server decides.
class ConfirmReceiptCard extends ConsumerStatefulWidget {
  const ConfirmReceiptCard({required this.order, super.key});

  final OrderDetail order;

  /// Whether this order is at a point where the buyer could plausibly be
  /// holding the parcel. Delivered is excluded: it is already closed, and
  /// confirming again would be a no-op the buyer should not be invited to.
  static bool isOfferedFor(OrderDetail order) =>
      order.status == OrderTrackStatus.inTransit ||
      order.status == OrderTrackStatus.outForDelivery;

  @override
  ConsumerState<ConfirmReceiptCard> createState() => _ConfirmReceiptCardState();
}

class _ConfirmReceiptCardState extends ConsumerState<ConfirmReceiptCard> {
  bool _busy = false;

  Future<void> _scanAndConfirm() async {
    if (_busy) return;

    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ParcelCodeScanScreen(
          expectedTrackingNumber: widget.order.trackingNumber ?? '',
        ),
      ),
    );
    if (scanned == null || !mounted) return;

    setState(() => _busy = true);

    // Distinct sub-orders on this order. The order detail model carries one
    // tracking number for the whole order, so a genuinely multi-vendor,
    // multi-parcel order cannot be told apart here — each sub-order is
    // offered the scanned code and the server rejects the ones it does not
    // belong to. Surfacing per-sub-order tracking would let this target just
    // one, and is the right follow-up.
    final subOrderIds = widget.order.items
        .map((item) => item.subOrderId)
        .where((id) => id.isNotEmpty)
        .toSet();

    if (subOrderIds.isEmpty) {
      setState(() => _busy = false);
      SmSnackbar.error(
        context,
        "This order can't be confirmed yet. Please try again shortly.",
      );
      return;
    }

    final repository = ref.read(ordersRepositoryProvider);
    var confirmed = false;
    String? firstError;

    for (final subOrderId in subOrderIds) {
      final result = await repository.confirmReceipt(
        subOrderId: subOrderId,
        scannedCode: scanned,
      );
      result.fold(
        (failure) => firstError ??= failure.isConflict
            ? 'This parcel was already confirmed.'
            : "That code doesn't match this delivery.",
        (_) => confirmed = true,
      );
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (confirmed) {
      SmSnackbar.success(context, 'Thanks — we have marked this as received.');
      await ref
          .read(orderDetailNotifierProvider(widget.order.id).notifier)
          .loadOrder(widget.order.id);
      return;
    }
    SmSnackbar.error(
      context,
      firstError ?? "That code doesn't match this delivery.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.s12),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text('Has it arrived?', style: DesignTokens.h3),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Scan the code on the parcel to confirm you received it. '
            'This starts your return window.',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _scanAndConfirm,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner_rounded),
              label: Text(_busy ? 'Confirming…' : 'Scan to confirm receipt'),
            ),
          ),
        ],
      ),
    );
  }
}
