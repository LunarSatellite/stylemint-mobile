import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// The return pickup notifications (return pickup contract §7), read from a
/// push payload's `data`: `return.accepted` and every `return_pickup.*`.
///
/// Kept apart from `DeliveryPushType` so the forward delivery flow, and every
/// switch over it, is untouched. A `return_pickup.*` type this app does not
/// know yet still routes — by its return id — rather than being dropped.
///
/// Since the return fixes contract (A.11, C) each one carries `data.audience`
/// — who it was written for — and that alone decides where a tap lands. An
/// older server sends none; [routeFor] then falls back to the caller's guess.
class ReturnPickupPush {
  const ReturnPickupPush({
    required this.type,
    this.returnRequestId,
    this.hopId,
    this.audience,
  });

  final String type;
  final String? returnRequestId;
  final String? hopId;

  /// Who the notice was written for; null from an older server, or for an
  /// audience this app does not know.
  final ReturnPickupAudience? audience;

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
      audience: ReturnPickupAudience.fromWire(data['audience']),
    );
  }

  static String? _id(Object? value) {
    final raw = value?.toString().trim();
    return raw == null || raw.isEmpty ? null : raw;
  }

  /// Where tapping it goes: the seller's returns, the rider's job (or
  /// dashboard), or the buyer's return.
  ///
  /// [audience] wins. Without it [rider] and [vendor] — the caller's guess
  /// from the account — decide, rider first.
  String routeFor({required bool vendor, required bool rider}) =>
      switch (audience ?? _guess(vendor: vendor, rider: rider)) {
        ReturnPickupAudience.rider => switch (hopId) {
          final id? => RouteNames.courierJobPath(id),
          null => RouteNames.courier,
        },
        ReturnPickupAudience.seller => RouteNames.vendorOrdersReturns,
        ReturnPickupAudience.buyer => switch (returnRequestId) {
          final id? => '${RouteNames.myReturns}/${Uri.encodeComponent(id)}',
          null => RouteNames.myReturns,
        },
      };

  static ReturnPickupAudience _guess({
    required bool vendor,
    required bool rider,
  }) {
    if (rider) return ReturnPickupAudience.rider;
    if (vendor) return ReturnPickupAudience.seller;
    return ReturnPickupAudience.buyer;
  }
}

/// `data.audience` on a return notice (return fixes contract A.11).
enum ReturnPickupAudience {
  buyer,
  seller,
  rider;

  /// Null for a missing or unknown value, so the caller falls back.
  static ReturnPickupAudience? fromWire(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'buyer' => ReturnPickupAudience.buyer,
        'seller' => ReturnPickupAudience.seller,
        'rider' => ReturnPickupAudience.rider,
        _ => null,
      };
}
