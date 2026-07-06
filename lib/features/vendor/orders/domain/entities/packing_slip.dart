/// Vendor §3D read-only projection of GET
/// /v1/vendor/sub-orders/{subOrderId}/packing-slip. Shape isn't published in
/// Swagger yet, so parsing (in the repository) is defensive/best-effort.
class PackingSlip {
  const PackingSlip({
    required this.orderId,
    required this.orderNumber,
    this.receiverName,
    this.shippingAddress,
    this.carrier,
    this.items = const [],
  });

  final String orderId;
  final String orderNumber;
  final String? receiverName;
  final String? shippingAddress;
  final String? carrier;
  final List<PackingSlipItem> items;
}

class PackingSlipItem {
  const PackingSlipItem({required this.productName, required this.quantity});

  final String productName;
  final int quantity;
}
