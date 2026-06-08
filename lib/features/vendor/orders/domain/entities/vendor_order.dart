import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

enum VendorOrderStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  processing('Processing'),
  shipped('Shipped'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  returned('Returned');

  const VendorOrderStatus(this.label);

  final String label;
}

class VendorOrderItem {
  const VendorOrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

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
  }) {
    return VendorOrderItem(
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
      other.productId == productId &&
      other.productName == productName &&
      other.imageUrl == imageUrl &&
      other.quantity == quantity &&
      other.unitPrice == unitPrice;

  @override
  int get hashCode => Object.hash(
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
    this.placedAt,
    this.shippingMethod,
    this.trackingNumber,
    this.shippedAt,
    this.deliveredAt,
    this.customerName,
    this.shippingAddress,
    this.items = const [],
  });

  final String id;
  final String orderNumber;

  /// Number of line items (backend list `itemCount`). The list endpoint does
  /// not return the lines themselves; [items] stays empty until a vendor
  /// detail endpoint ships.
  final int itemCount;
  final Money total;
  final VendorOrderStatus status;

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

  /// BACKEND GAP: not on /v1/vendor/sub-orders (deferred to a detail endpoint).
  final String? customerName;
  final String? shippingAddress;
  final List<VendorOrderItem> items;

  VendorOrder copyWith({
    String? id,
    String? orderNumber,
    int? itemCount,
    Money? total,
    VendorOrderStatus? status,
    DateTime? placedAt,
    String? shippingMethod,
    String? trackingNumber,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    String? customerName,
    String? shippingAddress,
    List<VendorOrderItem>? items,
  }) {
    return VendorOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      itemCount: itemCount ?? this.itemCount,
      total: total ?? this.total,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      shippingMethod: shippingMethod ?? this.shippingMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      customerName: customerName ?? this.customerName,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
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
      other.placedAt == placedAt &&
      other.shippingMethod == shippingMethod &&
      other.trackingNumber == trackingNumber &&
      other.shippedAt == shippedAt &&
      other.deliveredAt == deliveredAt &&
      other.customerName == customerName &&
      other.shippingAddress == shippingAddress;

  @override
  int get hashCode => Object.hash(
        id,
        orderNumber,
        itemCount,
        Object.hashAll(items),
        total,
        status,
        placedAt,
        shippingMethod,
        trackingNumber,
        shippedAt,
        deliveredAt,
        customerName,
        shippingAddress,
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
