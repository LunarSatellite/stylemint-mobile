import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class OrderInvoiceDto {
  const OrderInvoiceDto({
    required this.invoiceNumber,
    required this.orderNumber,
    required this.issuedUtc,
    required this.placedUtc,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotalAmount,
    required this.shippingTotalAmount,
    required this.taxTotalAmount,
    required this.grandTotalAmount,
    required this.currency,
    required this.items,
  });

  factory OrderInvoiceDto.fromJson(Map<String, dynamic> json) {
    final shipTo = json['shipTo'] as Map<String, dynamic>? ?? const {};
    final addressParts = [
      shipTo['addressLine1'] as String? ?? '',
      shipTo['landmark'] as String? ?? '',
      shipTo['city'] as String? ?? '',
      shipTo['state'] as String? ?? '',
      shipTo['zipCode'] as String? ?? '',
    ].where((part) => part.isNotEmpty);
    return OrderInvoiceDto(
      invoiceNumber: json['invoiceNumber'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      issuedUtc: DateTime.parse(json['issuedUtc'] as String),
      placedUtc: DateTime.parse(json['placedUtc'] as String),
      shippingAddress: addressParts.join(', '),
      paymentMethod: _paymentMethodLabel(json['paymentMethod'] as int? ?? 4),
      paymentStatus: json['paymentStatus'] as String? ?? '',
      subtotalAmount: (json['subtotalAmount'] as num? ?? 0).toDouble(),
      shippingTotalAmount: (json['shippingTotalAmount'] as num? ?? 0)
          .toDouble(),
      taxTotalAmount: (json['taxTotalAmount'] as num? ?? 0).toDouble(),
      grandTotalAmount: (json['grandTotalAmount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'NPR',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                OrderInvoiceLineDto.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String invoiceNumber;
  final String orderNumber;
  final DateTime issuedUtc;
  final DateTime placedUtc;
  final String shippingAddress;
  final String paymentMethod;
  final String paymentStatus;
  final double subtotalAmount;
  final double shippingTotalAmount;
  final double taxTotalAmount;
  final double grandTotalAmount;
  final String currency;
  final List<OrderInvoiceLineDto> items;

  OrderInvoice toDomain() => OrderInvoice(
    invoiceNumber: invoiceNumber,
    orderNumber: orderNumber,
    issuedAt: issuedUtc,
    placedAt: placedUtc,
    shippingAddress: shippingAddress,
    receiverName: '',
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
    subtotal: Money(amount: subtotalAmount, currency: currency),
    shipping: Money(amount: shippingTotalAmount, currency: currency),
    tax: Money(amount: taxTotalAmount, currency: currency),
    total: Money(amount: grandTotalAmount, currency: currency),
    items: items.map((item) => item.toDomain(currency)).toList(growable: false),
  );

  static String _paymentMethodLabel(int method) => switch (method) {
    1 => 'Visa/Mastercard',
    2 => 'PayPal',
    3 => 'eSewa',
    4 => 'Cash on Delivery',
    _ => 'Unknown',
  };
}

class OrderInvoiceLineDto {
  const OrderInvoiceLineDto({
    required this.productTitleSnapshot,
    required this.variantLabelSnapshot,
    required this.quantity,
    required this.unitPriceAmount,
    required this.lineSubtotalAmount,
  });

  factory OrderInvoiceLineDto.fromJson(Map<String, dynamic> json) =>
      OrderInvoiceLineDto(
        productTitleSnapshot: json['productTitleSnapshot'] as String? ?? '',
        variantLabelSnapshot: json['variantLabelSnapshot'] as String?,
        quantity: json['quantity'] as int? ?? 0,
        unitPriceAmount: (json['unitPriceAmount'] as num? ?? 0).toDouble(),
        lineSubtotalAmount: (json['lineSubtotalAmount'] as num? ?? 0)
            .toDouble(),
      );

  final String productTitleSnapshot;
  final String? variantLabelSnapshot;
  final int quantity;
  final double unitPriceAmount;
  final double lineSubtotalAmount;

  OrderInvoiceLine toDomain(String currency) => OrderInvoiceLine(
    productTitle: productTitleSnapshot,
    variantLabel: variantLabelSnapshot,
    quantity: quantity,
    unitPrice: Money(amount: unitPriceAmount, currency: currency),
    lineSubtotal: Money(amount: lineSubtotalAmount, currency: currency),
  );
}
