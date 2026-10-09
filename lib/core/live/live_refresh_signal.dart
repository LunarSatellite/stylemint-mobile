import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which part of the app a change concerns. A screen listens for the
/// scopes whose data it shows.
enum LiveScope {
  /// The buyer's orders: order detail, Track Orders, the confirm card.
  buyerOrders,

  /// The vendor's orders: the list and the sub-order detail.
  vendorOrders,

  /// The rider's jobs: the job screen and the dashboard.
  courierJobs,

  /// The rider's open delivery offers.
  courierOffers,
}

/// "Something about an order or a delivery changed — re-read what is on
/// screen." One shape for every source: a foreground or tapped push, a
/// SignalR `live` event, and a (re)connect of the live channel.
///
/// Carries only ids, never state: the screens re-read from the API, which
/// is the source of truth. Ids are optional — a screen that cannot tell
/// whether a change is about what it shows re-reads anyway, because a
/// missed update is worse than one extra GET.
class LiveSignal {
  const LiveSignal({
    required this.type,
    required this.scopes,
    this.orderId,
    this.orderNumber,
    this.subOrderId,
    this.hopId,
    this.packageNumber,
  });

  /// The live channel (re)connected: events may have been missed while it
  /// was down, so every open order and delivery screen re-reads.
  const LiveSignal.reconnected()
    : type = reconnectedType,
      scopes = const [
        LiveScope.buyerOrders,
        LiveScope.vendorOrders,
        LiveScope.courierJobs,
        LiveScope.courierOffers,
      ],
      orderId = null,
      orderNumber = null,
      subOrderId = null,
      hopId = null,
      packageNumber = null;

  static const reconnectedType = 'live.reconnected';

  final String type;
  final List<LiveScope> scopes;
  final String? orderId;
  final String? orderNumber;
  final String? subOrderId;
  final String? hopId;
  final String? packageNumber;

  bool concerns(Set<LiveScope> wanted) => scopes.any(wanted.contains);

  /// Whether this signal may be about the order [orderId] / [orderNumber]
  /// with sub-orders [subOrderIds]. True when it names none of them (a
  /// reconnect, or a payload without ids).
  bool mayConcernOrder({
    String? orderId,
    String? orderNumber,
    Iterable<String> subOrderIds = const [],
  }) {
    final named =
        this.orderId != null ||
        this.orderNumber != null ||
        subOrderId != null;
    if (!named) return true;
    return (this.orderId != null && this.orderId == orderId) ||
        (this.orderNumber != null && this.orderNumber == orderNumber) ||
        (subOrderId != null && subOrderIds.contains(subOrderId));
  }

  /// Which screens a change of [type] concerns, or null for a type this app
  /// does not refresh on (unknown types are ignored, per the realtime
  /// contract).
  static List<LiveScope>? scopesFor(String type) {
    switch (type) {
      // Live (SignalR) events.
      case 'order.updated':
        return const [LiveScope.buyerOrders, LiveScope.vendorOrders];
      case 'delivery.updated':
        return const [
          LiveScope.buyerOrders,
          LiveScope.vendorOrders,
          LiveScope.courierJobs,
        ];
      case 'delivery.offer':
        return const [LiveScope.courierOffers];
      // Delivery pushes (delivery-select / delivery-complete contracts).
      case 'delivery.request':
      case 'delivery.not_selected':
        return const [LiveScope.courierOffers];
      case 'delivery.interest':
        return const [LiveScope.vendorOrders];
      case 'delivery.selected':
        return const [
          LiveScope.courierOffers,
          LiveScope.courierJobs,
          LiveScope.vendorOrders,
          LiveScope.buyerOrders,
        ];
      case 'delivery.confirm_request':
        return const [LiveScope.buyerOrders, LiveScope.courierJobs];
      case 'delivery.delivered':
        return const [
          LiveScope.buyerOrders,
          LiveScope.vendorOrders,
          LiveScope.courierJobs,
        ];
    }
    // Order notifications (order.placed / packed / shipped / delivered /
    // cancelled …): the buyer's and the vendor's views of that order.
    if (type.startsWith('order.')) {
      return const [LiveScope.buyerOrders, LiveScope.vendorOrders];
    }
    return null;
  }

  /// From a push payload's `data`. The type is read from `type`, falling
  /// back to the template key the server may send instead; null for a push
  /// that is not about an order or a delivery.
  static LiveSignal? fromPushData(Map<String, dynamic> data) {
    final type = _typeOf(data);
    if (type == null) return null;
    final scopes = scopesFor(type);
    if (scopes == null) return null;
    return LiveSignal(
      type: type,
      scopes: scopes,
      orderId: _id(data['orderId']),
      orderNumber: _id(data['orderNumber']),
      subOrderId: _id(data['subOrderId']),
      hopId: _id(data['hopId']),
      packageNumber: _id(data['packageNumber']),
    );
  }

  /// From the argument of the hub's `live` method:
  /// `{ type, occurredUtc, data: { orderId, subOrderId, orderNumber, state,
  /// hopId, packageNumber } }`. Unknown keys are ignored; null for an
  /// unknown type or a malformed argument.
  static LiveSignal? fromLiveEvent(Object? argument) {
    if (argument is! Map) return null;
    final type = _text(argument['type'])?.toLowerCase();
    if (type == null) return null;
    final scopes = scopesFor(type);
    if (scopes == null) return null;
    final data = argument['data'];
    final map = data is Map ? data : const <Object?, Object?>{};
    return LiveSignal(
      type: type,
      scopes: scopes,
      orderId: _id(map['orderId']),
      orderNumber: _id(map['orderNumber']),
      subOrderId: _id(map['subOrderId']),
      hopId: _id(map['hopId']),
      packageNumber: _id(map['packageNumber']),
    );
  }

  static String? _typeOf(Map<String, dynamic> data) {
    for (final key in const ['type', 'templateKey', 'template', 'category']) {
      final value = _text(data[key])?.toLowerCase();
      if (value != null) return value;
    }
    return null;
  }

  static String? _text(Object? value) {
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  static String? _id(Object? value) => _text(value);

  @override
  String toString() => 'LiveSignal($type, $scopes)';
}

/// Every [LiveSignal], for the screens on display. Nothing is buffered: a
/// screen that was not listening re-reads when it opens.
class LiveRefreshBus {
  final StreamController<LiveSignal> _controller =
      StreamController<LiveSignal>.broadcast();

  Stream<LiveSignal> get signals => _controller.stream;

  void publish(LiveSignal signal) {
    if (!_controller.isClosed) _controller.add(signal);
  }

  Future<void> dispose() => _controller.close();
}

final liveRefreshBusProvider = Provider<LiveRefreshBus>((ref) {
  final bus = LiveRefreshBus();
  ref.onDispose(bus.dispose);
  return bus;
});
