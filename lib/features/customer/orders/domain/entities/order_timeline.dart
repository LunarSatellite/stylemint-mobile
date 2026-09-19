/// Buyer tracking timeline — `GET /v1/orders/{orderNumber}/timeline`
/// (Orders contract §3). One [SubOrderTimeline] per vendor.
library;

/// Backend `BuyerTimelineStep` (explicit ints 1..9). [unknown] keeps a newer
/// backend value from crashing an older app.
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
  unknown(0);

  const BuyerTimelineStep(this.value);

  final int value;

  static BuyerTimelineStep fromValue(int value) => BuyerTimelineStep.values
      .firstWhere((s) => s.value == value, orElse: () => unknown);

  /// Cancelled and Returned end the journey on a branch of their own.
  bool get isBranch => this == cancelled || this == returned;
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
