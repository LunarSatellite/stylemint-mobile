import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';

/// Reads the `delivery` block the delivery-complete contract adds to the
/// buyer's order detail.
///
/// Hand-written next to the generated `OrderDetailDto` rather than added to
/// it: the block is optional and still being built server-side, and a
/// tolerant read here cannot break the order screen the way a strict
/// generated field could. The contract allows it on the order or on a
/// sub-order, so both are read — a sub-order waiting on the buyer wins,
/// since that is the one the screen has to act on.
abstract final class OrderDeliveryJson {
  static OrderDelivery? fromOrder(Map<String, dynamic> json) {
    final candidates = <OrderDelivery>[
      ?parse(json['delivery']),
      if (json['subOrders'] case final List<dynamic> subOrders)
        for (final sub in subOrders)
          if (sub is Map)
            ?parse(sub['delivery'], subOrderId: _text(sub['id'])),
    ];
    if (candidates.isEmpty) return null;
    return candidates.where((d) => d.awaitingConfirmation).firstOrNull ??
        candidates.first;
  }

  /// `{ packageNumber, status, riderName, awaitingConfirmation }`, or null
  /// when absent or not an object.
  static OrderDelivery? parse(Object? value, {String? subOrderId}) {
    if (value is! Map) return null;
    final awaiting = value['awaitingConfirmation'];
    return OrderDelivery(
      packageNumber: _text(value['packageNumber']) ?? '',
      status: _text(value['status']) ?? '',
      riderName: _text(value['riderName']),
      awaitingConfirmation:
          awaiting == true || awaiting?.toString().toLowerCase() == 'true',
      subOrderId: _text(value['subOrderId']) ?? subOrderId,
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
