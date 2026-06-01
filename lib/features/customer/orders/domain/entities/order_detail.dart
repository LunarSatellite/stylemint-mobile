import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class OrderDetailItem {
  const OrderDetailItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.status,
  });

  final String productId;
  final String productName;
  final String imageUrl;
  final String variantName;
  final int qty;
  final Money unitPrice;
  final String status;
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.placedAt,
    required this.estimatedDelivery,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.shippingAddress,
    required this.paymentMethod,
    this.trackingNumber,
    required this.canCancel,
    required this.canReturn,
  });

  final String id;
  final String orderNumber;
  final OrderTrackStatus status;
  final DateTime placedAt;
  final DateTime estimatedDelivery;
  final List<OrderDetailItem> items;
  final Money subtotal;
  final Money shipping;
  final Money tax;
  final Money total;
  final String shippingAddress;
  final String paymentMethod;
  final String? trackingNumber;
  final bool canCancel;
  final bool canReturn;

  OrderDetail copyWith({
    String? id,
    String? orderNumber,
    OrderTrackStatus? status,
    DateTime? placedAt,
    DateTime? estimatedDelivery,
    List<OrderDetailItem>? items,
    Money? subtotal,
    Money? shipping,
    Money? tax,
    Money? total,
    String? shippingAddress,
    String? paymentMethod,
    String? trackingNumber,
    bool? canCancel,
    bool? canReturn,
  }) {
    return OrderDetail(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      canCancel: canCancel ?? this.canCancel,
      canReturn: canReturn ?? this.canReturn,
    );
  }
}
