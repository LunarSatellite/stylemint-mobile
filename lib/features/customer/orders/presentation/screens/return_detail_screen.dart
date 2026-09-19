import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/replacement_shipment.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/customer_returns_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/orders_load_error_view.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/return_status_pill.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/tracking_step_list.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';

/// Copy shown while a return has no refund linked (contract §4: always null
/// today).
const String refundPendingCopy = 'Refund status will appear here';

/// Return detail (`/orders/returns/:returnId`): product, reason, photos, the
/// state timeline and refund status.
class ReturnDetailScreen extends ConsumerWidget {
  const ReturnDetailScreen({required this.returnId, super.key});

  final String returnId;

  /// Steps for the return's state: Submitted → Approved → Completed, or
  /// Submitted → Rejected.
  static List<TrackingStepVm> stepsFor(CustomerReturn r) {
    final times = <ReturnRequestStatus, DateTime?>{
      for (final entry in r.timeline) entry.status: entry.occurredUtc,
    };
    String? at(ReturnRequestStatus status, [DateTime? fallback]) {
      final time = times[status] ?? fallback;
      return time == null ? null : formatNptDateTime(time);
    }

    final submitted = TrackingStepVm(
      title: 'Return submitted',
      state:
          r.status == ReturnRequestStatus.submitted ||
              r.status == ReturnRequestStatus.unknown
          ? TrackingStepState.current
          : TrackingStepState.done,
      subtitle: 'The seller is reviewing your request.',
      timestamp: at(ReturnRequestStatus.submitted, r.submittedUtc),
    );

    return switch (r.status) {
      ReturnRequestStatus.rejected => [
        submitted,
        TrackingStepVm(
          title: 'Return rejected',
          state: TrackingStepState.done,
          tone: TrackingStepTone.negative,
          timestamp: at(ReturnRequestStatus.rejected, r.resolvedUtc),
          note: r.rejectionNote,
        ),
      ],
      ReturnRequestStatus.approved => [
        submitted,
        TrackingStepVm(
          title: 'Approved by the seller',
          state: TrackingStepState.current,
          subtitle: 'Send the item back as the seller instructs.',
          timestamp: at(ReturnRequestStatus.approved),
        ),
        const TrackingStepVm(
          title: 'Return completed',
          state: TrackingStepState.upcoming,
        ),
      ],
      ReturnRequestStatus.completed => [
        submitted,
        TrackingStepVm(
          title: 'Approved by the seller',
          state: TrackingStepState.done,
          timestamp: at(ReturnRequestStatus.approved),
        ),
        TrackingStepVm(
          title: 'Return completed',
          state: TrackingStepState.done,
          timestamp: at(ReturnRequestStatus.completed, r.resolvedUtc),
        ),
      ],
      ReturnRequestStatus.submitted || ReturnRequestStatus.unknown => [
        submitted,
        const TrackingStepVm(
          title: 'Approved by the seller',
          state: TrackingStepState.upcoming,
        ),
        const TrackingStepVm(
          title: 'Return completed',
          state: TrackingStepState.upcoming,
        ),
      ],
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = returnDetailNotifierProvider(returnId);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final pickup = ref.watch(returnPickupProvider(returnId)).asData?.value;
    final replacementShipment = ref
        .watch(replacementShipmentProvider(returnId))
        .asData
        ?.value;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Return details',
          style: DesignTokens.sectionInnerTitle,
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: notifier.refresh,
          child: state.when(
            initial: () => const _DetailSkeleton(),
            loadInProgress: () => const _DetailSkeleton(),
            loadFailure: (failure) => OrdersScrollableState(
              child: OrdersLoadErrorView(
                failure: failure,
                onRetry: notifier.load,
                subject: 'this return',
              ),
            ),
            loadSuccess: (r) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s8,
                DesignTokens.s16,
                DesignTokens.s32,
              ),
              children: [
                _ProductCard(customerReturn: r),
                const SizedBox(height: DesignTokens.s12),
                _Section(
                  label: 'Reason',
                  child: Text(
                    r.reason.trim().isEmpty ? 'No reason given' : r.reason,
                    style: DesignTokens.mediumRegular,
                  ),
                ),
                if (r.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s12),
                  _Section(
                    label: 'Photos',
                    child: _PhotoStrip(urls: r.photoUrls),
                  ),
                ],
                const SizedBox(height: DesignTokens.s12),
                _Section(
                  label: 'Progress',
                  child: TrackingStepList(steps: stepsFor(r)),
                ),
                if (pickup != null) ...[
                  const SizedBox(height: DesignTokens.s12),
                  _Section(
                    label: 'Return pickup',
                    child: _ReturnPickupCard(pickup: pickup),
                  ),
                ],
                const SizedBox(height: DesignTokens.s12),
                if (r.resolution == CustomerReturnResolution.replacement)
                  _Section(
                    label: 'Replacement',
                    child: _ReplacementStatus(
                      customerReturn: r,
                      shipment: replacementShipment,
                    ),
                  )
                else
                  _Section(
                    label: 'Refund',
                    child: _RefundStatus(refundStatus: r.refundStatus),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.customerReturn});

  final CustomerReturn customerReturn;

  @override
  Widget build(BuildContext context) {
    final r = customerReturn;
    final variant = r.product.variantLabel?.trim();
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                child: SizedBox(
                  width: 72,
                  height: 90,
                  child: MallNetworkImage(url: r.product.thumbnailUrl),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ReturnStatusPill(status: r.status),
                    const SizedBox(height: DesignTokens.s8),
                    Text(
                      r.product.title.isEmpty ? 'Item' : r.product.title,
                      style: DesignTokens.mediumSemibold,
                    ),
                    if (variant != null && variant.isNotEmpty)
                      Text(variant, style: DesignTokens.smallRegular),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      'Qty ${r.quantity} · '
                      '${formatMoney(r.product.unitPrice)} each',
                      style: DesignTokens.smallDescription.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                    Text(
                      'Submitted ${formatNptDate(r.submittedUtc)}',
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.orderNumber.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primaryGreen,
                minimumSize: const Size(
                  DesignTokens.minTouchTarget,
                  DesignTokens.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: () =>
                  context.push('${RouteNames.orders}/${r.orderNumber}'),
              icon: const Icon(Icons.receipt_long_outlined, size: 18),
              label: Text('Order #${r.orderNumber}'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: MallEyebrow(label)),
          const SizedBox(height: DesignTokens.s12),
          child,
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s8),
        itemBuilder: (context, i) => Semantics(
          button: true,
          label: 'Return photo ${i + 1} of ${urls.length}',
          child: InkWell(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            onTap: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => Dialog(
                backgroundColor: DesignTokens.bgAppFoundation,
                insetPadding: const EdgeInsets.all(DesignTokens.s16),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.s12),
                      child: InteractiveViewer(
                        child: MallNetworkImage(
                          url: urls[i],
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 4,
                      end: 4,
                      child: IconButton(
                        tooltip: 'Close',
                        icon: const Icon(
                          Icons.close_rounded,
                          color: DesignTokens.textWhite,
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              child: SizedBox.square(
                dimension: 96,
                child: MallNetworkImage(url: urls[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnPickupCard extends StatelessWidget {
  const _ReturnPickupCard({required this.pickup});

  final ReturnPickup pickup;

  @override
  Widget build(BuildContext context) {
    final complete = pickup.status == ReturnPickupStatus.receivedByVendor;
    return Semantics(
      label:
          'Return pickup ${pickup.status.label}, tracking ${pickup.trackingNumber}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      (complete
                              ? DesignTokens.primaryGreen
                              : DesignTokens.warning500)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  complete
                      ? Icons.inventory_2_outlined
                      : Icons.local_shipping_outlined,
                  color: complete
                      ? DesignTokens.primaryGreen
                      : DesignTokens.warning500,
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup.status.label,
                      style: DesignTokens.mediumSemibold,
                    ),
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
          const SizedBox(height: DesignTokens.s12),
          Text(
            complete
                ? 'Your item reached the seller. Refund settlement is shown below.'
                : 'Pickup from ${pickup.originAddressLine} · returning to ${pickup.destinationAddressLine}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundStatus extends StatelessWidget {
  const _RefundStatus({required this.refundStatus});

  final String? refundStatus;

  @override
  Widget build(BuildContext context) {
    final status = refundStatus?.trim();
    final pending = status == null || status.isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          pending ? Icons.hourglass_empty_rounded : Icons.payments_outlined,
          size: 18,
          color: pending ? DesignTokens.textMuted : DesignTokens.primaryGreen,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(
            pending ? refundPendingCopy : status,
            style: pending
                ? DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  )
                : DesignTokens.mediumSemibold,
          ),
        ),
      ],
    );
  }
}

class _ReplacementStatus extends ConsumerWidget {
  const _ReplacementStatus({required this.customerReturn, this.shipment});

  final CustomerReturn customerReturn;
  final ReplacementShipment? shipment;

  Future<void> _payBalance(BuildContext context, WidgetRef ref) async {
    final method = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: Text('Secure payment', style: DesignTokens.sectionInnerTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 3),
            child: const ListTile(
              leading: Icon(Icons.account_balance_wallet_outlined),
              title: Text('eSewa'),
              subtitle: Text('Pay the exact replacement balance'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 2),
            child: const ListTile(
              leading: Icon(Icons.public_rounded),
              title: Text('PayPal'),
              subtitle: Text('Continue securely with PayPal'),
            ),
          ),
        ],
      ),
    );
    if (method == null || !context.mounted) return;

    try {
      final response = await ref
          .read(apiClientProvider)
          .post(
            '/v1/orders/returns/' + customerReturn.id + '/replacement-payment',
            data: {'method': method},
            options: Options(
              headers: {
                'requiresToken': true,
                'Idempotency-Key':
                    'replacement-' +
                    customerReturn.id +
                    '-' +
                    DateTime.now().millisecondsSinceEpoch.toString(),
              },
            ),
          );
      final data = response as Map<String, dynamic>;
      final redirect = data['redirectUrl'] as String?;
      if (redirect != null && redirect.isNotEmpty) {
        await launchUrl(
          Uri.parse(redirect),
          mode: LaunchMode.inAppBrowserView,
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment started. Shipment unlocks only after verified payment.',
          ),
        ),
      );
      await ref
          .read(returnDetailNotifierProvider(customerReturn.id).notifier)
          .refresh();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start payment. Please try again.'),
        ),
      );
    }
  }

  String get _stateLabel =>
      shipment?.status.label ??
      switch (customerReturn.replacementState) {
        CustomerReplacementState.inventoryHeld => 'Replacement reserved',
        CustomerReplacementState.awaitingReturnedItem =>
          'Waiting for your return',
        CustomerReplacementState.readyToShip => 'Ready to ship',
        CustomerReplacementState.shipped => 'Replacement on the way',
        CustomerReplacementState.delivered => 'Replacement delivered',
        CustomerReplacementState.cancelled => 'Replacement cancelled',
        CustomerReplacementState.awaitingBalancePayment =>
          'Balance payment needed',
        CustomerReplacementState.none => 'Replacement requested',
      };

  int get _activeStep {
    final outbound = shipment?.status;
    if (outbound == ReplacementShipmentStatus.readyToShip) return 2;
    if (outbound == ReplacementShipmentStatus.shipped) return 3;
    if (outbound == ReplacementShipmentStatus.delivered) return 4;
    if (outbound == ReplacementShipmentStatus.cancelled) return -1;
    return switch (customerReturn.replacementState) {
      CustomerReplacementState.none => 0,
      CustomerReplacementState.inventoryHeld => 0,
      CustomerReplacementState.awaitingReturnedItem => 1,
      CustomerReplacementState.readyToShip => 2,
      CustomerReplacementState.shipped => 3,
      CustomerReplacementState.delivered => 4,
      CustomerReplacementState.cancelled => -1,
      CustomerReplacementState.awaitingBalancePayment => 2,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difference = customerReturn.replacementPriceDifferenceAmount ?? 0;
    final differenceRefund = difference < 0 ? difference.abs() : 0.0;
    final balanceDue = difference > 0 ? difference : 0.0;
    final currency =
        customerReturn.replacementUnitPrice?.currency ??
        customerReturn.product.unitPrice.currency;
    const labels = ['Reserved', 'Return', 'Ready', 'Shipped', 'Delivered'];
    final cancelled =
        customerReturn.replacementState == CustomerReplacementState.cancelled ||
        shipment?.status == ReplacementShipmentStatus.cancelled;

    return Semantics(
      label: 'Replacement status $_stateLabel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      (cancelled
                              ? DesignTokens.colorError
                              : DesignTokens.primaryGreen)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  cancelled ? Icons.cancel_outlined : Icons.autorenew_rounded,
                  color: cancelled
                      ? DesignTokens.colorError
                      : DesignTokens.primaryGreen,
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_stateLabel, style: DesignTokens.mediumSemibold),
                    if (shipment != null)
                      Text(
                        shipment!.trackingNumber,
                        style: DesignTokens.smallDescription.copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    if (customerReturn.replacementUnitPrice != null)
                      Text(
                        'New item · ' +
                            formatMoney(customerReturn.replacementUnitPrice!),
                        style: DesignTokens.smallDescription.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!cancelled) ...[
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= _activeStep
                                ? DesignTokens.primaryGreen
                                : DesignTokens.bgAppBodyLight,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.tiny.copyWith(
                            color: i <= _activeStep
                                ? DesignTokens.textWhite
                                : DesignTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < labels.length - 1)
                    Container(
                      width: 8,
                      height: 2,
                      color: i < _activeStep
                          ? DesignTokens.primaryGreen
                          : DesignTokens.bgAppBodyLight,
                    ),
                ],
              ],
            ),
          ],
          const SizedBox(height: DesignTokens.s12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DesignTokens.s12),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppFoundation,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            ),
            child: Text(
              differenceRefund > 0
                  ? 'You will receive ' +
                        currency +
                        ' ' +
                        differenceRefund.toStringAsFixed(2) +
                        ' back for the price difference.'
                  : balanceDue > 0
                  ? 'Pay only ' +
                        currency +
                        ' ' +
                        balanceDue.toStringAsFixed(2) +
                        ' before your replacement ships.'
                  : 'Even exchange · no additional payment or refund needed.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
          if (balanceDue > 0 &&
              customerReturn.replacementPaymentStatus != 'Completed') ...[
            const SizedBox(height: DesignTokens.s12),
            FilledButton.icon(
              onPressed: () => _payBalance(context, ref),
              icon: const Icon(Icons.lock_outline_rounded),
              label: Text(
                customerReturn.replacementPaymentStatus == 'Pending'
                    ? 'Continue secure payment'
                    : 'Pay replacement balance',
              ),
            ),
          ],
          if (differenceRefund > 0) ...[
            const SizedBox(height: DesignTokens.s12),
            _RefundStatus(refundStatus: customerReturn.refundStatus),
          ],
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading return',
      liveRegion: true,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: const [
          Row(
            children: [
              SmSkeleton.box(width: 72, height: 90),
              SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmSkeleton.line(width: 80, height: 18, radius: 9),
                    SizedBox(height: DesignTokens.s12),
                    SmSkeleton.line(),
                    SizedBox(height: DesignTokens.s8),
                    SmSkeleton.line(width: 120, height: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.s24),
          SmSkeleton.box(height: 88),
          SizedBox(height: DesignTokens.s12),
          SmSkeleton.box(height: 160),
        ],
      ),
    );
  }
}
