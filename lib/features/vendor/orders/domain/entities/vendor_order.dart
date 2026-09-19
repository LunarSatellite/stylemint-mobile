import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';

enum VendorOrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  processing('Processing'),
  accepted('Accepted'),
  packed('Packed'),
  handedOver('Handed over'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  returned('Returned');

  const VendorOrderStatus(this.label);

  final String label;
}

/// Backend `SubOrderState` ints (Orders contract §1).
abstract final class SubOrderStateCode {
  static const pending = 1;
  static const paid = 2;
  static const awaitingFulfillment = 3;
  static const readyToShip = 4;
  static const awaitingTracking = 5;
  static const shipped = 6;
  static const delivered = 7;
  static const cancelled = 8;
  static const returned = 9;
  static const inTransit = 10;
  static const outForDelivery = 11;
  static const accepted = 12;
  static const packed = 13;
  static const handedOver = 14;
}

/// SubOrderState int -> UI status. The legacy vendor-workflow states
/// (Paid/AwaitingFulfillment/ReadyToShip/AwaitingTracking) collapse to
/// Confirmed/Processing and courier states to Shipped; the seller steps keep
/// their own labels. An unknown int reads as Pending rather than throwing.
VendorOrderStatus vendorOrderStatusFromState(int state) => switch (state) {
  SubOrderStateCode.pending => VendorOrderStatus.pending,
  SubOrderStateCode.paid => VendorOrderStatus.confirmed,
  SubOrderStateCode.awaitingFulfillment ||
  SubOrderStateCode.readyToShip ||
  SubOrderStateCode.awaitingTracking => VendorOrderStatus.processing,
  SubOrderStateCode.accepted => VendorOrderStatus.accepted,
  SubOrderStateCode.packed => VendorOrderStatus.packed,
  SubOrderStateCode.handedOver => VendorOrderStatus.handedOver,
  SubOrderStateCode.shipped ||
  SubOrderStateCode.inTransit ||
  SubOrderStateCode.outForDelivery => VendorOrderStatus.shipped,
  SubOrderStateCode.delivered => VendorOrderStatus.delivered,
  SubOrderStateCode.cancelled => VendorOrderStatus.cancelled,
  SubOrderStateCode.returned => VendorOrderStatus.returned,
  _ => VendorOrderStatus.pending,
};

/// A state-changing step a vendor can take from the order detail screen.
enum VendorOrderAction {
  accept,
  reject,
  markPacked,
  handOver,
  readyToShip,
  markDelivered,

  /// Counter handover on a collection sub-order: the buyer walked in and
  /// took the goods. Terminates at Delivered, exactly as a courier delivery
  /// does, so the return window and review eligibility start the same way.
  markCollected,
}

/// The next actions allowed from a backend state (Orders contract §1,
/// "Allowed transitions"), primary action first.
///
/// [channel] defaults to delivery, so every existing caller keeps the
/// delivery path it already had. On a collection sub-order the courier
/// steps are gone — there is no handover to a rider and no "mark as
/// delivered", because the backend refuses both — and the counter handover
/// takes their place.
List<VendorOrderAction> vendorActionsForState(
  int state, {
  OrderFulfillmentChannel channel = OrderFulfillmentChannel.delivery,
}) {
  if (channel.isCollection) return _collectionActionsForState(state);
  return switch (state) {
    SubOrderStateCode.paid || SubOrderStateCode.awaitingFulfillment => const [
      VendorOrderAction.accept,
      VendorOrderAction.reject,
    ],
    SubOrderStateCode.accepted => const [VendorOrderAction.markPacked],
    SubOrderStateCode.packed => const [
      VendorOrderAction.handOver,
      VendorOrderAction.readyToShip,
    ],
    SubOrderStateCode.handedOver ||
    SubOrderStateCode.shipped ||
    SubOrderStateCode.inTransit ||
    SubOrderStateCode.outForDelivery => const [VendorOrderAction.markDelivered],
    _ => const [],
  };
}

/// The collection path. `SubOrder.MarkCollected` is legal from Paid,
/// AwaitingFulfillment, Accepted, Packed, ReadyToShip and AwaitingTracking,
/// so the counter handover is offered from each of them — a buyer who walks
/// in early is still a buyer holding the goods, and the seller should not
/// have to walk the order forward first to record that.
///
/// `readyToShip` keeps its transition but reads as "ready for collection"
/// here: it is the seller telling the buyer the goods are waiting.
List<VendorOrderAction> _collectionActionsForState(int state) =>
    switch (state) {
      SubOrderStateCode.paid || SubOrderStateCode.awaitingFulfillment => const [
        VendorOrderAction.accept,
        VendorOrderAction.reject,
      ],
      SubOrderStateCode.accepted => const [
        VendorOrderAction.markPacked,
      ],
      SubOrderStateCode.packed => const [
        VendorOrderAction.readyToShip,
        VendorOrderAction.markCollected,
      ],
      SubOrderStateCode.readyToShip ||
      SubOrderStateCode.awaitingTracking => const [
        VendorOrderAction.markCollected,
      ],
      _ => const [],
    };

/// Why the counter handover cannot be taken on this sub-order, or null when
/// it can.
///
/// The control is not simply hidden on a delivery order. A seller who was
/// expecting to hand something across a counter is owed the reason, and
/// "the button is not there" is not a reason — it reads as a bug. The same
/// sentence is what the backend refuses with (422), so the screen and the
/// server tell one story.
String? collectionHandoverRefusal({
  required int state,
  required OrderFulfillmentChannel channel,
}) {
  if (!channel.isCollection) {
    return 'This order is being delivered by courier. '
        'Handing over at the counter applies only to collection orders.';
  }
  if (state == SubOrderStateCode.delivered) return null;
  if (_collectionActionsForState(state).contains(
    VendorOrderAction.markCollected,
  )) {
    return null;
  }
  return 'This order cannot be handed over from its current status.';
}

/// Backend `VendorRejectionReason` (contract §2, reject).
enum VendorRejectionReason {
  outOfStock(1, 'Out of stock'),
  cannotFulfillInTime(2, 'Can’t fulfil in time'),
  pricingError(3, 'Pricing error'),
  addressNotServiceable(4, 'Can’t deliver to this address'),
  suspectedFraud(5, 'Suspected fraud'),
  other(6, 'Other');

  const VendorRejectionReason(this.code, this.label);

  final int code;
  final String label;

  /// A note is required for [other].
  bool get requiresNote => this == other;
}

/// Maximum length of the reject note and handover note (contract §2).
const int vendorNoteMaxLength = 200;

/// Contract §2 handover limits.
const int vendorCarrierMaxLength = 100;
const int vendorTrackingMaxLength = 200;

/// Client-side bucketing for the "Your Orders" tabs and the Ready-to-Ship
/// screen. The backend's list-filter `status` query values aren't confirmed
/// against Swagger, so screens fetch unfiltered and bucket locally using the
/// same collapsed status the DTOs already compute.
extension VendorOrderStatusBucketing on VendorOrderStatus {
  /// Candidates for the "Mark as Shipped" action. The backend's SubOrder
  /// state machine allows the ReadyToShip transition from
  /// AwaitingFulfillment (collapsed into `processing` here) and from Packed —
  /// Pending/Paid orders reject with "Cannot transition SubOrder from Pending
  /// to ReadyToShip."
  bool get isToShip =>
      this == VendorOrderStatus.processing || this == VendorOrderStatus.packed;

  /// Orders visible on the "Your Orders" list before shipment — broader than
  /// [isToShip] since Pending/Confirmed orders are real (just not yet
  /// actionable). Used for the "To Ship" tab bucket, not the action button.
  bool get isPreShipment =>
      this == VendorOrderStatus.pending ||
      this == VendorOrderStatus.confirmed ||
      this == VendorOrderStatus.processing ||
      this == VendorOrderStatus.accepted ||
      this == VendorOrderStatus.packed;

  /// Handed over to a courier or further along the delivery. "In Transit"
  /// and "Shipped" show the same set until the backend exposes a finer
  /// distinction.
  bool get isInTransit =>
      this == VendorOrderStatus.shipped || this == VendorOrderStatus.handedOver;

  bool get isCompleted =>
      this == VendorOrderStatus.delivered ||
      this == VendorOrderStatus.cancelled ||
      this == VendorOrderStatus.returned;
}

extension VendorOrderTrackingBucketing on VendorOrder {
  /// Vendor has progressed the order into fulfillment but hasn't attached a
  /// tracking number yet ("Orders Awaiting Tracking"). The backend collapses
  /// AwaitingFulfillment/ReadyToShip/AwaitingTracking into one `processing`
  /// status, so this can't be perfectly distinguished from "not yet marked
  /// ready to ship" — best-effort bucket until backend exposes finer state.
  bool get isWaitingTracking =>
      status == VendorOrderStatus.processing && trackingNumber == null;

  /// Paid or awaiting fulfillment: can be accepted (alone or in bulk).
  bool get canAccept => vendorActionsForState(
    stateCode,
  ).contains(VendorOrderAction.accept);
}

class VendorOrderItem {
  const VendorOrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.subOrderLineId = '',
  });

  /// The sub-order line's own id (`lines[].id` on the detail payload).
  ///
  /// Empty on a list row, because the list endpoint returns no lines at all.
  /// Empty means *unknown*, and the per-unit tagging action is simply not
  /// offered for a line with no id rather than guessing one.
  final String subOrderLineId;

  final String productId;
  final String productName;
  final String imageUrl;
  final int quantity;
  final Money unitPrice;

  VendorOrderItem copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    int? quantity,
    Money? unitPrice,
    String? subOrderLineId,
  }) {
    return VendorOrderItem(
      subOrderLineId: subOrderLineId ?? this.subOrderLineId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorOrderItem &&
      other.subOrderLineId == subOrderLineId &&
      other.productId == productId &&
      other.productName == productName &&
      other.imageUrl == imageUrl &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice;

  @override
  int get hashCode => Object.hash(
    subOrderLineId,
    productId,
    productName,
    imageUrl,
    quantity,
    unitPrice,
  );
}

class VendorOrder {
  const VendorOrder({
    required this.id,
    required this.orderNumber,
    required this.itemCount,
    required this.total,
    required this.status,
    this.stateCode = 0,
    this.placedAt,
    this.shippingMethod,
    this.trackingNumber,
    this.shippedAt,
    this.deliveredAt,
    this.customerName,
    this.shippingAddress,
    this.items = const [],
    this.fulfillmentChannel = OrderFulfillmentChannel.delivery,
    this.collectedAt,
  });

  final String id;
  final String orderNumber;

  /// Number of line items (backend list `itemCount`). The list endpoint does
  /// not return the lines themselves; [items] stays empty until a vendor
  /// detail endpoint ships.
  final int itemCount;
  final Money total;
  final VendorOrderStatus status;

  /// Raw backend `SubOrderState` int ([SubOrderStateCode]); drives which
  /// next actions are offered. 0 for sample rows.
  final int stateCode;

  /// Backend `placedUtc`.
  final DateTime? placedAt;

  /// Real carrier (backend `carrier`) once the vendor marks the order shipped;
  /// null pre-shipment.
  final String? shippingMethod;

  /// Backend `trackingNumber` (null until shipped).
  final String? trackingNumber;

  /// Backend `shippedUtc` / `deliveredUtc`.
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  /// Backend list `receiverName`, denormalized for the vendor order row.
  final String? customerName;

  /// Null on a collection order, and deliberately so: checkout records an
  /// empty address for one because there is no address. Rendering anything
  /// here would be inventing a destination.
  final String? shippingAddress;
  final List<VendorOrderItem> items;

  /// How this order reaches the buyer (backend `fulfillmentChannel`).
  /// Decides which seller steps exist at all.
  final OrderFulfillmentChannel fulfillmentChannel;

  /// When the buyer took the goods at the counter (backend `collectedUtc`).
  /// Null on a delivery, and null on a collection nobody has handed over yet.
  final DateTime? collectedAt;

  bool get isCollection => fulfillmentChannel.isCollection;

  VendorOrder copyWith({
    String? id,
    String? orderNumber,
    int? itemCount,
    Money? total,
    VendorOrderStatus? status,
    int? stateCode,
    DateTime? placedAt,
    String? shippingMethod,
    String? trackingNumber,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? customerName,
    String? shippingAddress,
    List<VendorOrderItem>? items,
    OrderFulfillmentChannel? fulfillmentChannel,
    DateTime? collectedAt,
  }) {
    return VendorOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      itemCount: itemCount ?? this.itemCount,
      total: total ?? this.total,
      status: status ?? this.status,
      stateCode: stateCode ?? this.stateCode,
      placedAt: placedAt ?? this.placedAt,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      customerName: customerName ?? this.customerName,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      fulfillmentChannel: fulfillmentChannel ?? this.fulfillmentChannel,
      collectedAt: collectedAt ?? this.collectedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorOrder &&
      other.id == id &&
      other.orderNumber == orderNumber &&
      other.itemCount == itemCount &&
      _listEquals(other.items, items) &&
      other.total == total &&
      other.status == status &&
      other.stateCode == stateCode &&
      other.placedAt == placedAt &&
      other.shippingMethod == shippingMethod &&
      other.trackingNumber == trackingNumber &&
      other.shippedAt == shippedAt &&
      other.deliveredAt == deliveredAt &&
      other.customerName == customerName &&
      other.shippingAddress == shippingAddress &&
      other.fulfillmentChannel == fulfillmentChannel &&
      other.collectedAt == collectedAt;

  @override
  int get hashCode => Object.hash(
    id,
    orderNumber,
    itemCount,
    Object.hashAll(items),
    total,
    status,
    stateCode,
    placedAt,
    shippingMethod,
    trackingNumber,
    shippedAt,
    deliveredAt,
    customerName,
    shippingAddress,
    fulfillmentChannel,
    collectedAt,
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
