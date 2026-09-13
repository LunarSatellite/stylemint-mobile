/// Voyager "Post-Purchase Care" — per ordered item, where it is in the
/// customer's post-purchase journey, what they can do next and the return
/// deadline that matters. Backend `OrderCarePlanDto` / `CareItemDto`.
library;

/// Backend `CareStage` (Orders module enum, explicit ints 1..6).
enum CareStage {
  /// Not delivered yet.
  inProgress,

  /// Delivered and still inside the return window.
  returnWindowOpen,

  /// Delivered and the return window has passed.
  returnWindowClosed,

  /// A return request is being reviewed or has been approved.
  returnInProgress,

  /// The item was returned.
  returned,

  /// The item was cancelled.
  cancelled,

  /// A stage this app version doesn't know yet.
  unknown,
}

/// What the customer can do for an item right now. Wire values are
/// `track`, `return`, `review`, `reorder` and `get_help`.
enum CareAction { track, returnItem, review, reorder, getHelp }

class CareItem {
  const CareItem({
    required this.subOrderId,
    required this.subOrderLineId,
    required this.productVariantId,
    required this.title,
    required this.stage,
    required this.actions,
    required this.guidance,
    this.variantLabel,
    this.thumbnailUrl,
    this.deliveredUtc,
    this.returnWindowClosesUtc,
    this.daysLeftToReturn,
    this.trackingNumber,
  });

  final String subOrderId;

  /// Matches the order detail line id used by the return request flow.
  final String subOrderLineId;
  final String productVariantId;
  final String title;
  final String? variantLabel;
  final String? thumbnailUrl;
  final CareStage stage;
  final DateTime? deliveredUtc;
  final DateTime? returnWindowClosesUtc;

  /// Whole days left to request a return; set only while the window is open.
  final int? daysLeftToReturn;
  final String? trackingNumber;
  final List<CareAction> actions;

  /// One plain sentence telling the customer what matters next.
  final String guidance;

  bool get isReturnWindowOpen => stage == CareStage.returnWindowOpen;
}

class OrderCarePlan {
  const OrderCarePlan({
    required this.orderNumber,
    required this.items,
    this.generatedUtc,
    this.nextReturnDeadlineUtc,
  });

  final String orderNumber;
  final DateTime? generatedUtc;

  /// The soonest return window still open on this order, if any.
  final DateTime? nextReturnDeadlineUtc;
  final List<CareItem> items;
}
