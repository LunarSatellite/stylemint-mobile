import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_pill.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/tracking_step_list.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Buyer copy for each timeline step.
abstract final class BuyerStepCopy {
  /// Pill / headline label.
  static String label(BuyerTimelineStep step) => switch (step) {
    BuyerTimelineStep.placed => 'Order placed',
    BuyerTimelineStep.confirmed => 'Confirmed',
    BuyerTimelineStep.preparing => 'Preparing',
    BuyerTimelineStep.pickedUp => 'Picked up',
    BuyerTimelineStep.inTransit => 'In transit',
    BuyerTimelineStep.outForDelivery => 'Out for delivery',
    BuyerTimelineStep.delivered => 'Delivered',
    BuyerTimelineStep.cancelled => 'Cancelled',
    BuyerTimelineStep.returned => 'Returned',
    BuyerTimelineStep.unknown => 'Update',
  };

  /// Editorial headline for the card, in the buyer's words.
  static String headline(BuyerTimelineStep step) => switch (step) {
    BuyerTimelineStep.placed => 'Waiting for the seller',
    BuyerTimelineStep.confirmed => 'The seller is on it',
    BuyerTimelineStep.preparing => 'Being packed',
    BuyerTimelineStep.pickedUp => 'With the courier',
    BuyerTimelineStep.inTransit => 'On its way',
    BuyerTimelineStep.outForDelivery => 'Arriving today',
    BuyerTimelineStep.delivered => 'Delivered',
    BuyerTimelineStep.cancelled => 'Cancelled',
    BuyerTimelineStep.returned => 'Returned',
    BuyerTimelineStep.unknown => 'Tracking update',
  };

  /// Row title, keyed by the step (falls back to the wire key).
  static String title(TimelineStep step) => switch (step.step) {
    BuyerTimelineStep.placed => 'Order placed',
    BuyerTimelineStep.confirmed => 'Confirmed by the seller',
    BuyerTimelineStep.preparing => 'Preparing your order',
    BuyerTimelineStep.pickedUp => 'Picked up by the courier',
    BuyerTimelineStep.inTransit => 'In transit',
    BuyerTimelineStep.outForDelivery => 'Out for delivery',
    BuyerTimelineStep.delivered => 'Delivered',
    BuyerTimelineStep.cancelled => 'Order cancelled',
    BuyerTimelineStep.returned => 'Returned',
    BuyerTimelineStep.unknown => _humanise(step.key),
  };

  /// One line under the current step.
  static String? currentHint(BuyerTimelineStep step) => switch (step) {
    BuyerTimelineStep.placed => 'Waiting for the seller to confirm.',
    BuyerTimelineStep.confirmed => 'The seller has accepted your order.',
    BuyerTimelineStep.preparing => 'Your items are being packed.',
    BuyerTimelineStep.pickedUp => 'Your parcel is with the courier.',
    BuyerTimelineStep.inTransit => 'Moving through the delivery network.',
    BuyerTimelineStep.outForDelivery => 'A rider is bringing it to you today.',
    _ => null,
  };

  static OrderPillTone tone(BuyerTimelineStep step) => switch (step) {
    BuyerTimelineStep.placed ||
    BuyerTimelineStep.confirmed ||
    BuyerTimelineStep.preparing => OrderPillTone.info,
    BuyerTimelineStep.pickedUp ||
    BuyerTimelineStep.inTransit ||
    BuyerTimelineStep.outForDelivery => OrderPillTone.progress,
    BuyerTimelineStep.delivered => OrderPillTone.success,
    BuyerTimelineStep.cancelled => OrderPillTone.negative,
    BuyerTimelineStep.returned => OrderPillTone.caution,
    BuyerTimelineStep.unknown => OrderPillTone.neutral,
  };

  static String _humanise(String key) {
    final words = key.trim().split('_').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'Update';
    final sentence = words.join(' ');
    return sentence[0].toUpperCase() + sentence.substring(1);
  }
}

/// Tracking card for one sub-order: a status headline and pill, the ETA
/// ("Arriving by Thu 17 Sep") when known, carrier and tracking number, then
/// the vertical steps. Timestamps are shown in Asia/Kathmandu.
class OrderTrackingTimeline extends StatelessWidget {
  const OrderTrackingTimeline({
    required this.timeline,
    super.key,
    this.showVendor = false,
  });

  final SubOrderTimeline timeline;

  /// Shows "From {vendor} · N items" — used when an order has several
  /// sub-orders.
  final bool showVendor;

  static List<TrackingStepVm> stepsFor(SubOrderTimeline timeline) => [
    for (final step in timeline.steps)
      TrackingStepVm(
        title: BuyerStepCopy.title(step),
        state: switch (step.status) {
          TimelineStepStatus.done => TrackingStepState.done,
          TimelineStepStatus.current => TrackingStepState.current,
          TimelineStepStatus.upcoming => TrackingStepState.upcoming,
        },
        subtitle: step.status == TimelineStepStatus.current
            ? BuyerStepCopy.currentHint(step.step)
            : null,
        timestamp: step.occurredUtc == null
            ? null
            : formatNptDateTime(step.occurredUtc!),
        note: step.note,
        tone: switch (step.step) {
          BuyerTimelineStep.cancelled => TrackingStepTone.negative,
          BuyerTimelineStep.returned => TrackingStepTone.caution,
          _ => TrackingStepTone.progress,
        },
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final eta = timeline.estimatedDeliveryUtc;
    final showEta = eta != null && !timeline.isTerminal;
    final carrierLine = [
      if (timeline.carrier?.trim().isNotEmpty ?? false)
        timeline.carrier!.trim(),
      if (timeline.trackingNumber?.trim().isNotEmpty ?? false)
        timeline.trackingNumber!.trim(),
    ].join(' · ');
    final vendor = timeline.vendorName?.trim() ?? '';
    final seller = vendor.isEmpty ? 'the seller' : vendor;
    final items = timeline.itemsCount == 1
        ? '1 item'
        : '${timeline.itemsCount} items';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eyebrow and pill share a line when they fit; a long vendor
            // name or a large text scale moves the pill to its own line.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                MallEyebrow(
                  showVendor ? 'From $seller · $items' : 'Tracking',
                  maxLines: 2,
                ),
                OrderStatusPill(
                  label: BuyerStepCopy.label(timeline.currentStep),
                  tone: BuyerStepCopy.tone(timeline.currentStep),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Semantics(
              header: true,
              child: Text(
                BuyerStepCopy.headline(timeline.currentStep),
                style: DesignTokens.displaySection,
              ),
            ),
            if (showEta) ...[
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  const Icon(
                    Icons.event_available_rounded,
                    size: 18,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Text(
                      'Arriving by ${formatNptWeekday(eta)}',
                      style: DesignTokens.mediumSemibold,
                    ),
                  ),
                ],
              ),
            ],
            if (carrierLine.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(carrierLine, style: DesignTokens.smallRegular),
            ],
            const SizedBox(height: DesignTokens.s20),
            if (timeline.deliveryProofStatus !=
                DeliveryProofStatus.legacyUnsealed) ...[
              _DeliveryProofBadge(status: timeline.deliveryProofStatus),
              const SizedBox(height: DesignTokens.s20),
            ],
            TrackingStepList(steps: stepsFor(timeline)),
          ],
        ),
      ),
    );
  }
}

class _DeliveryProofBadge extends StatelessWidget {
  const _DeliveryProofBadge({required this.status});

  final DeliveryProofStatus status;

  @override
  Widget build(BuildContext context) {
    final verified = status == DeliveryProofStatus.verified;
    final color = verified
        ? DesignTokens.primaryGreen
        : DesignTokens.colorError;
    final title = verified
        ? 'Verified delivery history'
        : 'Delivery proof needs review';
    final detail = verified
        ? 'Each custody update is cryptographically linked. Changes would be detected.'
        : 'The custody proof did not verify. Contact support before accepting the parcel.';

    return Semantics(
      container: true,
      label: '$title. $detail',
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          border: Border.all(color: color.withValues(alpha: .28)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              verified ? Icons.verified_user_outlined : Icons.gpp_bad_outlined,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DesignTokens.smallRegular.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// All sub-order timelines of one order. The vendor header appears only when
/// the order is split across several sellers.
class OrderTimelineSection extends StatelessWidget {
  const OrderTimelineSection({required this.timeline, super.key});

  final OrderTimeline timeline;

  @override
  Widget build(BuildContext context) {
    final subOrders = timeline.subOrders;
    final several = subOrders.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < subOrders.length; i++) ...[
          if (i > 0) const SizedBox(height: DesignTokens.s12),
          OrderTrackingTimeline(timeline: subOrders[i], showVendor: several),
        ],
      ],
    );
  }
}

/// Loading placeholder with the timeline card's footprint.
class OrderTrackingTimelineSkeleton extends StatelessWidget {
  const OrderTrackingTimelineSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading tracking',
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DesignTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmSkeleton.line(width: 72, height: 10),
              const SizedBox(height: DesignTokens.s12),
              const SmSkeleton.line(width: 160, height: 22),
              const SizedBox(height: DesignTokens.s20),
              for (var i = 0; i < 4; i++) ...[
                const Row(
                  children: [
                    SmSkeleton.circle(diameter: 18),
                    SizedBox(width: DesignTokens.s12),
                    Expanded(child: SmSkeleton.line()),
                  ],
                ),
                const SizedBox(height: DesignTokens.s20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
