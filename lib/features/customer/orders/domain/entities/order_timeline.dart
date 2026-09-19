/// Buyer tracking timeline — `GET /v1/orders/{orderNumber}/timeline`
/// (Orders contract §3). One [SubOrderTimeline] per vendor.
library;

import 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';

export 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';

/// Backend `BuyerTimelineStep` (explicit ints 1..11). [unknown] keeps a newer
/// backend value from crashing an older app.
///
/// 10 and 11 exist only on the collection path; 4, 5 and 6 exist only on the
/// delivery path. No sub-order is ever on both.
enum BuyerTimelineStep {
  placed(1),
  confirmed(2),
  preparing(3),
  pickedUp(4),
  inTransit(5),
  outForDelivery(6),
  delivered(7),
  cancelled(8),
  returned(9),

  /// The seller says the goods are waiting at the counter.
  readyForCollection(10),

  /// The buyer took the goods across the counter. Terminal on the
  /// collection path.
  collected(11),
  unknown(0);

  const BuyerTimelineStep(this.value);

  final int value;

  static BuyerTimelineStep fromValue(int value) => BuyerTimelineStep.values
      .firstWhere((s) => s.value == value, orElse: () => unknown);

  /// Cancelled and Returned end the journey on a branch of their own.
  bool get isBranch => this == cancelled || this == returned;

  /// The three steps a courier performs. A collection order reaches none of
  /// them, and showing any of them on one was a live defect: three journeys
  /// nobody made, rendered as completed fact. Named here so the rule can be
  /// asserted rather than remembered.
  static const Set<BuyerTimelineStep> courierOnly = {
    pickedUp,
    inTransit,
    outForDelivery,
  };
}

/// Backend `TimelineStepStatus`: 1 done, 2 current, 3 upcoming. An unknown
/// value reads as upcoming so it never claims progress that didn't happen.
enum TimelineStepStatus {
  done,
  current,
  upcoming;

  static TimelineStepStatus fromValue(int value) => switch (value) {
    1 => done,
    2 => current,
    _ => upcoming,
  };
}

class TimelineStep {
  const TimelineStep({
    required this.step,
    required this.key,
    required this.status,
    this.occurredUtc,
    this.note,
  });

  final BuyerTimelineStep step;

  /// Stable snake_case key (e.g. `picked_up`), used for copy lookup.
  final String key;
  final TimelineStepStatus status;
  final DateTime? occurredUtc;

  /// Handover note on PickedUp; cancellation note on Cancelled.
  final String? note;
}

enum DeliveryProofStatus {
  verified,
  legacyUnsealed,
  invalid;

  static DeliveryProofStatus fromWire(String value) => switch (value) {
    'verified' => verified,
    'invalid' => invalid,
    _ => legacyUnsealed,
  };
}

class SubOrderTimeline {
  const SubOrderTimeline({
    required this.subOrderId,
    required this.vendorAccountId,
    required this.itemsCount,
    required this.currentStep,
    required this.isTerminal,
    required this.steps,
    this.deliveryProofStatus = DeliveryProofStatus.legacyUnsealed,
    this.vendorName,
    this.carrier,
    this.trackingNumber,
    this.estimatedDeliveryUtc,
    this.fulfillmentChannel = OrderFulfillmentChannel.delivery,
    this.collectedUtc,
    this.collectionLocationName,
  });

  final String subOrderId;
  final String vendorAccountId;

  /// Brand name; null when the backend couldn't resolve it.
  final String? vendorName;
  final int itemsCount;
  final BuyerTimelineStep currentStep;

  /// True for Delivered, Cancelled and Returned.
  final bool isTerminal;
  final String? carrier;
  final String? trackingNumber;

  /// Null when unknown or terminal.
  final DateTime? estimatedDeliveryUtc;
  final DeliveryProofStatus deliveryProofStatus;
  final List<TimelineStep> steps;

  /// Which path this sub-order is on. Decides what the screen may say, not
  /// merely how it looks.
  final OrderFulfillmentChannel fulfillmentChannel;

  /// When the buyer took the goods at the counter. Null on a delivery.
  final DateTime? collectedUtc;

  /// The counter's name, when the backend could resolve one.
  ///
  /// **Null is a normal answer** — the location may never have been
  /// recorded, may no longer exist, or may never have been named. The screen
  /// then says when it was collected and not where, because it does not
  /// know where.
  final String? collectionLocationName;

  bool get isCollection => fulfillmentChannel.isCollection;

  bool get isCancelled => currentStep == BuyerTimelineStep.cancelled;
  bool get isReturned => currentStep == BuyerTimelineStep.returned;
}

class OrderTimeline {
  const OrderTimeline({
    required this.orderNumber,
    required this.orderState,
    required this.placedUtc,
    required this.subOrders,
  });

  final String orderNumber;

  /// Backend `OrderState` int.
  final int orderState;
  final DateTime placedUtc;
  final List<SubOrderTimeline> subOrders;
}
