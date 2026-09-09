/// Vendor §3D read-only projection of GET
/// /v1/vendor/sub-orders/{subOrderId}/packing-slip (backend PackingSlipDto).
class PackingSlip {
  const PackingSlip({
    required this.orderId,
    required this.orderNumber,
    this.packingSlipNumber,
    this.receiverName,
    this.shippingAddress,
    this.carrier,
    this.trackingNumber,
    this.items = const [],
  });

  final String orderId;
  final String orderNumber;
  final String? packingSlipNumber;
  final String? receiverName;
  final String? shippingAddress;
  final String? carrier;
  final String? trackingNumber;
  final List<PackingSlipItem> items;
}

class PackingSlipItem {
  const PackingSlipItem({required this.productName, required this.quantity});

  final String productName;
  final int quantity;
}
