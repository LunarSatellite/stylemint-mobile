import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// The return pickup notifications (return pickup contract §7), read from a
/// push payload's `data`: `return.accepted` and every `return_pickup.*`.
///
/// Kept apart from `DeliveryPushType` so the forward delivery flow, and every
/// switch over it, is untouched. A `return_pickup.*` type this app does not
/// know yet still routes — by its return id — rather than being dropped.
class ReturnPickupPush {
  const ReturnPickupPush({required this.type, this.returnRequestId, this.hopId});

  final String type;
  final String? returnRequestId;
  final String? hopId;

  static const accepted = 'return.accepted';
  static const interest = 'return_pickup.interest';
  static const noRiders = 'return_pickup.no_riders';
  static const riderAssigned = 'return_pickup.rider_assigned';
  static const confirmRequest = 'return_pickup.confirm_request';
  static const collected = 'return_pickup.collected';
  static const received = 'return_pickup.received';
  static const attemptFailed = 'return_pickup.attempt_failed';
  static const cancelled = 'return_pickup.cancelled';

  /// Null when [data] is not a return pickup notification.
  static ReturnPickupPush? fromData(Map<String, dynamic> data) {
    final type = data['type']?.toString().trim().toLowerCase();
    if (type == null ||
        (type != accepted && !type.startsWith('return_pickup.'))) {
      return null;
    }
    return ReturnPickupPush(
      type: type,
      returnRequestId: _id(data['returnRequestId']),
      hopId: _id(data['hopId']),
    );
  }

  static String? _id(Object? value) {
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  /// Where tapping it goes: the seller's returns, the rider's job (or
  /// dashboard), or the buyer's return.
  String routeFor({required bool vendor, required bool rider}) {
    if (rider) {
      return switch (hopId) {
        final id? => RouteNames.courierJobPath(id),
        null => RouteNames.courier,
      };
    }
    if (vendor) return RouteNames.vendorOrders;
    return switch (returnRequestId) {
      final id? => '${RouteNames.myReturns}/${Uri.encodeComponent(id)}',
      null => RouteNames.myReturns,
    };
  }
}
