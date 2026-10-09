import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// The delivery-partner notifications, read from a push payload's `data`.
///
/// Unlike the general push payload (see `push_destination.dart`), these keys
/// ARE pinned: the delivery-selection contract names `type` and the ids that
/// travel with each one. So they are routed by type here rather than by a
/// guessed `url` key — a rider tapping "A vendor near you needs a rider" must
/// land on the offers screen even though the server sends no link.
enum DeliveryPushType {
  /// To riders: a vendor near you needs a rider. Carries `offerId`.
  request('delivery.request'),

  /// To the vendor: a rider tapped "I'm interested". Carries `subOrderId`.
  interest('delivery.interest'),

  /// To the chosen rider. Carries `packageId` and `hopId`.
  selected('delivery.selected'),

  /// To riders who were interested and not chosen. Carries `offerId`.
  notSelected('delivery.not_selected'),

  /// To the buyer, when the rider taps "Complete ride" at the door. Carries
  /// `orderId` and `subOrderId`; opens the order with "Confirm delivery".
  confirmRequest('delivery.confirm_request'),

  /// To the vendor and the rider once the recipient confirmed. Carries
  /// `subOrderId` and `hopId`.
  delivered('delivery.delivered');

  const DeliveryPushType(this.wire);

  final String wire;

  /// Null for anything that is not a delivery notification — most pushes are
  /// not, and they keep going through the generic destination path.
  static DeliveryPushType? fromWire(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    for (final type in values) {
      if (type.wire == raw) return type;
    }
    return null;
  }
}

/// One delivery notification, as the app needs it.
class DeliveryPushEvent {
  const DeliveryPushEvent({
    required this.type,
    this.offerId,
    this.subOrderId,
    this.packageId,
    this.hopId,
    this.orderId,
    this.orderNumber,
  });

  final DeliveryPushType type;
  final String? offerId;
  final String? subOrderId;
  final String? packageId;
  final String? hopId;
  final String? orderId;

  /// Not in the contract, but preferred when a server sends it: the buyer's
  /// order screen is addressed by order number, and the id has to be looked
  /// up first.
  final String? orderNumber;

  /// Null when [data] is not a delivery notification.
  static DeliveryPushEvent? fromData(Map<String, dynamic> data) {
    final type = DeliveryPushType.fromWire(data['type']);
    if (type == null) return null;
    return DeliveryPushEvent(
      type: type,
      offerId: _id(data['offerId']),
      subOrderId: _id(data['subOrderId']),
      packageId: _id(data['packageId']),
      hopId: _id(data['hopId']),
      orderId: _id(data['orderId']),
      orderNumber: _id(data['orderNumber']),
    );
  }

  static String? _id(Object? value) {
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  /// Where tapping this notification goes, as a go_router location, for a
  /// rider or a buyer. See [routeFor] for the one type whose landing depends
  /// on who received it.
  String? get route => routeFor(vendor: false);

  /// Where tapping this notification goes.
  ///
  /// [vendor] only matters for `delivery.delivered`, which the vendor and
  /// the rider both receive with the same payload: the vendor opens the
  /// sub-order (now Delivered), the rider their dashboard.
  String? routeFor({required bool vendor}) => switch (type) {
    DeliveryPushType.request => RouteNames.courierOffers,
    DeliveryPushType.notSelected => RouteNames.courierOffers,
    // Straight to the job on the in-app map. Without a hop id, the
    // dashboard — whose map draws the first unfinished hop, this one.
    DeliveryPushType.selected => switch (hopId) {
      final id? => RouteNames.courierJobPath(id),
      null => RouteNames.courier,
    },
    DeliveryPushType.interest => _vendorOrder(partnerSheet: true),
    // The order, whose "Confirm delivery" card is the point of this push.
    // The order number when sent; the id otherwise, which the order screen
    // resolves.
    DeliveryPushType.confirmRequest => switch (orderNumber ?? orderId) {
      final id? => '/orders/${Uri.encodeComponent(id)}',
      null => RouteNames.orders,
    },
    DeliveryPushType.delivered =>
      vendor ? _vendorOrder(partnerSheet: false) : RouteNames.courier,
  };

  /// The vendor's sub-order, or their orders list without an id — a better
  /// landing than a guess.
  String _vendorOrder({required bool partnerSheet}) => switch (subOrderId) {
    final id? =>
      '/vendor/orders/${Uri.encodeComponent(id)}'
          '${partnerSheet ? '?${RouteNames.partnerSheetQuery}=1' : ''}',
    null => RouteNames.vendorOrders,
  };
}

/// Delivery notifications as they arrive, for screens that want to refresh
/// the moment something changes rather than on their next poll.
///
/// Fed by the app's FCM listeners (foreground and tapped). Screens subscribe
/// while they are on screen; nothing is buffered, because a screen that was
/// not listening re-reads on open anyway.
class DeliveryPushBus {
  final StreamController<DeliveryPushEvent> _controller =
      StreamController<DeliveryPushEvent>.broadcast();

  Stream<DeliveryPushEvent> get events => _controller.stream;

  void publish(DeliveryPushEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

final deliveryPushBusProvider = Provider<DeliveryPushBus>((ref) {
  final bus = DeliveryPushBus();
  ref.onDispose(bus.dispose);
  return bus;
});
