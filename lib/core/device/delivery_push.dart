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
  notSelected('delivery.not_selected');

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
  });

  final DeliveryPushType type;
  final String? offerId;
  final String? subOrderId;
  final String? packageId;
  final String? hopId;

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
    );
  }

  static String? _id(Object? value) {
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  /// Where tapping this notification goes, as a go_router location.
  ///
  /// Null only for an interest push with no sub-order id: there is no order to
  /// open, and the vendor's orders list is a better landing than a guess.
  String? get route => switch (type) {
    DeliveryPushType.request => RouteNames.courierOffers,
    DeliveryPushType.notSelected => RouteNames.courierOffers,
    // The dashboard IS the map: the gate lands a live courier on it, and the
    // map draws the first unfinished hop — the one this push assigned.
    DeliveryPushType.selected => RouteNames.courier,
    DeliveryPushType.interest => switch (subOrderId) {
      final id? => '/vendor/orders/${Uri.encodeComponent(id)}'
          '?${RouteNames.partnerSheetQuery}=1',
      null => RouteNames.vendorOrders,
    },
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
