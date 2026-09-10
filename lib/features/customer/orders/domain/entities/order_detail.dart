import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class OrderDetailItem {
  const OrderDetailItem({
    this.id = '',
    this.subOrderId = '',
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.variantName,
    required this.qty,
    required this.unitPrice,
    required this.status,
  });

  /// SubOrderLine id — required by the return-request endpoint. Empty for
  /// items sourced from the invoice projection (no return flow there).
  final String id;

  /// Parent SubOrder id — required by the return-request endpoint.
  final String subOrderId;
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
    this.receiverName = '',
    this.receiverPhone = '',
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
  final String receiverName;
  final String receiverPhone;
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

/// Immutable receipt projection returned by `GET /v1/orders/{number}/invoice`.
/// Unlike [OrderDetail], this is the source of truth for an invoice: payment
/// state, item prices, and totals are all snapshotted by the backend.
class OrderInvoiceLine {
  const OrderInvoiceLine({
    required this.productTitle,
    required this.variantLabel,
    required this.quantity,
    required this.unitPrice,
    required this.lineSubtotal,
  });

  final String productTitle;
  final String? variantLabel;
  final int quantity;
  final Money unitPrice;
  final Money lineSubtotal;
}

class OrderInvoice {
  const OrderInvoice({
    required this.invoiceNumber,
    required this.orderNumber,
    required this.issuedAt,
    required this.placedAt,
    required this.shippingAddress,
    required this.receiverName,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.total,
    required this.items,
  });

  final String invoiceNumber;
  final String orderNumber;
  final DateTime issuedAt;
  final DateTime placedAt;
  final String shippingAddress;
  final String receiverName;
  final String paymentMethod;
  final String paymentStatus;
  final Money subtotal;
  final Money shipping;
  final Money tax;
  final Money total;
  final List<OrderInvoiceLine> items;

  OrderDetail toOrderDetail() => OrderDetail(
    id: orderNumber,
    orderNumber: orderNumber,
    status: OrderTrackStatus.preparingForShipping,
    placedAt: placedAt,
    estimatedDelivery: placedAt,
    items: items
        .map(
          (item) => OrderDetailItem(
            productId: item.productTitle,
            productName: item.productTitle,
            imageUrl: '',
            variantName: item.variantLabel ?? '',
            qty: item.quantity,
            unitPrice: item.unitPrice,
            status: paymentStatus,
          ),
        )
        .toList(growable: false),
    subtotal: subtotal,
    shipping: shipping,
    tax: tax,
    total: total,
    shippingAddress: shippingAddress,
    receiverName: receiverName,
    paymentMethod: paymentMethod,
    canCancel: false,
    canReturn: false,
  );
}
