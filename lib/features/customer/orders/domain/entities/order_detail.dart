import 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
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

/// Where the money for a cancelled part of an order stands. Read from the
/// sub-order's `refundStatus`.
enum CancelledPartRefund {
  pending('Refund processing'),
  completed('Refunded'),
  failed('Refund failed — contact support'),
  notCharged('You were not charged'),
  unknown('');

  const CancelledPartRefund(this.label);
  final String label;

  static CancelledPartRefund fromWire(String? wire) =>
      switch (wire?.toLowerCase()) {
        'pending' => CancelledPartRefund.pending,
        'completed' => CancelledPartRefund.completed,
        'failed' => CancelledPartRefund.failed,
        'notcharged' => CancelledPartRefund.notCharged,
        _ => CancelledPartRefund.unknown,
      };
}

/// One seller's part of the order that will not arrive because it was
/// cancelled — by the seller (rejected) or otherwise.
class CancelledOrderPart {
  const CancelledOrderPart({
    required this.subOrderId,
    required this.cancelledBySeller,
    required this.reason,
    required this.refund,
    required this.itemNames,
    this.amount,
  });

  final String subOrderId;
  final bool cancelledBySeller;

  /// The seller's reason in plain words (and their note, when given); empty
  /// when none was recorded.
  final String reason;
  final CancelledPartRefund refund;
  final List<String> itemNames;
  final Money? amount;

  String get headline =>
      cancelledBySeller ? 'Cancelled by the seller' : 'Cancelled';
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
    this.taxIncluded = true,
    required this.total,
    required this.shippingAddress,
    this.fulfillmentChannel = OrderFulfillmentChannel.delivery,
    this.collectedAt,
    this.receiverName = '',
    this.receiverPhone = '',
    required this.paymentMethod,
    this.trackingNumber,
    required this.canCancel,
    required this.canReturn,
    this.submittedReturnId,
    this.delivery,
    this.cancelledParts = const <CancelledOrderPart>[],
    this.creditAgreementId,
  });

  /// Parts of this order that were cancelled (one per seller). On a mixed
  /// order the rest is still on its way; when every part is here the whole
  /// order is cancelled.
  final List<CancelledOrderPart> cancelledParts;

  /// True when every cancelled part was cancelled by its seller.
  bool get cancelledBySellers =>
      cancelledParts.isNotEmpty &&
      cancelledParts.every((p) => p.cancelledBySeller);

  /// The StyleMint-rider delivery behind this order, when there is one. Its
  /// [OrderDelivery.awaitingConfirmation] puts "Your parcel is at the door —
  /// confirm delivery" at the top of the order screen.
  final OrderDelivery? delivery;

  /// Set once a return is submitted from this screen: the new return's id,
  /// or an empty string when the backend response didn't carry one.
  final String? submittedReturnId;

  final String id;
  final String orderNumber;
  final OrderTrackStatus status;
  final DateTime placedAt;
  final DateTime estimatedDelivery;
  final List<OrderDetailItem> items;
  final Money subtotal;
  final Money shipping;
  final Money tax;

  /// [tax] is the VAT inside the prices — true of every order since catalogue
  /// prices included VAT — so it is part of [total], not added to it. False on
  /// an older order that was charged VAT on top: there it is one of the lines
  /// [total] adds up.
  final bool taxIncluded;
  final Money total;

  /// The ship-to line. **Empty on a collection order**, because checkout
  /// recorded no address for one — the buyer is going to the counter. Empty
  /// means absent and the screen omits the block rather than filling it.
  final String shippingAddress;

  /// How this order reaches the buyer. Decides which timeline the screen is
  /// allowed to draw when the backend timeline is unavailable.
  final OrderFulfillmentChannel fulfillmentChannel;

  /// When the buyer collected at the counter; null on a delivery.
  final DateTime? collectedAt;

  bool get isCollection => fulfillmentChannel.isCollection;

  final String receiverName;
  final String receiverPhone;
  final String paymentMethod;
  final String? trackingNumber;
  final bool canCancel;
  final bool canReturn;

  /// The payment plan (EMI, pay later) this order is bought on. Null when the
  /// server did not say — one that predates the field; empty when it said
  /// the order was paid outright.
  final String? creditAgreementId;

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
    bool? taxIncluded,
    Money? total,
    String? shippingAddress,
    OrderFulfillmentChannel? fulfillmentChannel,
    DateTime? collectedAt,
    String? paymentMethod,
    String? trackingNumber,
    bool? canCancel,
    bool? canReturn,
    String? submittedReturnId,
    OrderDelivery? delivery,
  }) {
    return OrderDetail(
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      cancelledParts: cancelledParts,
      creditAgreementId: creditAgreementId,
      delivery: delivery ?? this.delivery,
      submittedReturnId: submittedReturnId ?? this.submittedReturnId,
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      placedAt: placedAt ?? this.placedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      shipping: shipping ?? this.shipping,
      tax: tax ?? this.tax,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      total: total ?? this.total,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      fulfillmentChannel: fulfillmentChannel ?? this.fulfillmentChannel,
      collectedAt: collectedAt ?? this.collectedAt,
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
    this.taxIncluded = true,
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

  /// See [OrderDetail.taxIncluded].
  final bool taxIncluded;
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
    taxIncluded: taxIncluded,
    total: total,
    shippingAddress: shippingAddress,
    receiverName: receiverName,
    paymentMethod: paymentMethod,
    canCancel: false,
    canReturn: false,
  );
}
