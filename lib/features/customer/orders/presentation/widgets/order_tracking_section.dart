import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/order_timeline_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Pull-to-refresh on order detail: reloads the order (keyed by the route's
/// [routeOrderId]) and its timeline in place, and asks the supplementary
/// cards to check again.
Future<void> refreshOrderDetail(
  WidgetRef ref, {
  required String routeOrderId,
  required OrderDetail order,
}) async {
  final trackingNumber = order.trackingNumber;
  if (trackingNumber != null && trackingNumber.startsWith('SM-D-')) {
    ref
      ..invalidate(deliveryStoryProvider(trackingNumber))
      ..invalidate(deliveryRiskProvider(trackingNumber))
      ..invalidate(packageSealProvider(trackingNumber))
      ..invalidate(custodyProofProvider(trackingNumber));
  }
  ref.invalidate(orderCarePlanProvider(order.orderNumber));
  await Future.wait([
    ref
        .read(orderDetailNotifierProvider(routeOrderId).notifier)
        .refresh(routeOrderId),
    ref
        .read(orderTimelineNotifierProvider(order.orderNumber).notifier)
        .refresh(),
  ]);
}

/// Order detail's tracking block: the backend timeline when it loads, else
/// [fallback] (the older timeline derived from order state).
class OrderTrackingSection extends ConsumerWidget {
  const OrderTrackingSection({
    required this.orderNumber,
    required this.fallback,
    super.key,
    this.supplement,
  });

  final String orderNumber;

  /// Shown when the timeline call fails or returns no sub-orders.
  final Widget fallback;

  /// Optional card shown under the timeline (e.g. live delivery updates).
  final Widget? supplement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderTimelineNotifierProvider(orderNumber));
    return state.when(
      initial: () => const OrderTrackingTimelineSkeleton(),
      loadInProgress: () => const OrderTrackingTimelineSkeleton(),
      loadFailure: (_) => fallback,
      loadSuccess: (timeline) {
        if (timeline.subOrders.isEmpty) return fallback;
        final extra = supplement;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderTimelineSection(timeline: timeline),
            if (extra != null) ...[
              const SizedBox(height: DesignTokens.s16),
              extra,
            ],
          ],
        );
      },
    );
  }
}
