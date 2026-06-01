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
    required this.customerName,
    required this.items,
    required this.total,
    required this.status,
    required this.placedAt,
    required this.shippingAddress,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final List<VendorOrderItem> items;
  final Money total;
  final VendorOrderStatus status;
  final DateTime placedAt;
  final String shippingAddress;

  VendorOrder copyWith({
    String? id,
    String? orderNumber,
    String? customerName,
    List<VendorOrderItem>? items,
    Money? total,
    VendorOrderStatus? status,
    DateTime? placedAt,
    String? shippingAddress,
  }) {
    return VendorOrder(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      total: total ?? this.total,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      shippingAddress: shippingAddress ?? this.shippingAddress,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorOrder &&
      other.id == id &&
      other.orderNumber == orderNumber &&
      other.customerName == customerName &&
      _listEquals(other.items, items) &&
      other.total == total &&
      other.status == status &&
      other.placedAt == placedAt &&
      other.shippingAddress == shippingAddress;

  @override
  int get hashCode => Object.hash(
        id,
        orderNumber,
        customerName,
        Object.hashAll(items),
        total,
        status,
        placedAt,
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
