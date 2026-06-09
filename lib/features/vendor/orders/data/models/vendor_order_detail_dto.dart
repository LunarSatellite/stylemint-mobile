import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Maps the backend VendorSubOrderDetailDto (Orders module,
/// GET /v1/vendor/sub-orders/{subOrderId}). Unlike the list row this carries
/// the parent order number, ShipTo (incl. receiver name), and line items, so
/// the detail screen can render the full order. Parsed manually — `shipTo`
/// nests and amounts arrive as ints (System.Text.Json serializes whole
/// `decimal`s as ints).
class VendorOrderDetailDto {
  const VendorOrderDetailDto({required this.json});

  final Map<String, dynamic> json;

  factory VendorOrderDetailDto.fromJson(Map<String, dynamic> json) =>
      VendorOrderDetailDto(json: json);

  VendorOrder toDomain() {
    final shipTo = json['shipTo'] as Map<String, dynamic>?;
    final currency = json['subtotalCurrency'] as String? ?? 'NPR';
    final lines = (json['lines'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();

    return VendorOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? lines.length,
      total: Money(
        amount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0,
        currency: currency,
      ),
      status: _statusFromState((json['state'] as num?)?.toInt() ?? 1),
      placedAt: _parseDate(json['placedUtc']),
      shippingMethod: json['carrier'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      shippedAt: _parseDate(json['shippedUtc']),
      deliveredAt: _parseDate(json['deliveredUtc']),
      customerName: shipTo?['receiverName'] as String?,
      shippingAddress: _formatAddress(shipTo),
      items: lines.map(_lineToItem).toList(growable: false),
    );
  }

  static VendorOrderItem _lineToItem(Map<String, dynamic> l) => VendorOrderItem(
        productId: (l['productVariantId'] as String?) ?? '',
        productName: (l['productTitleSnapshot'] as String?) ?? '',
        imageUrl: (l['thumbnailUrlSnapshot'] as String?) ?? '',
        quantity: (l['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: Money(
          amount: (l['unitPriceAmount'] as num?)?.toDouble() ?? 0,
          currency: (l['unitPriceCurrency'] as String?) ?? 'NPR',
        ),
      );

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  /// "{line1}, {city}, {state} {zip}" — skips empty parts.
  static String? _formatAddress(Map<String, dynamic>? a) {
    if (a == null) return null;
    final parts = <String>[
      (a['addressLine1'] as String?) ?? '',
      (a['city'] as String?) ?? '',
      [(a['state'] as String?) ?? '', (a['zipCode'] as String?) ?? '']
          .where((s) => s.isNotEmpty)
          .join(' '),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// SubOrderState enum int -> UI status (mirrors VendorOrderDto).
  static VendorOrderStatus _statusFromState(int state) {
    switch (state) {
      case 1:
        return VendorOrderStatus.pending;
      case 2:
        return VendorOrderStatus.confirmed;
      case 3:
      case 4:
      case 5:
        return VendorOrderStatus.processing;
      case 6:
      case 10:
      case 11:
        return VendorOrderStatus.shipped;
      case 7:
        return VendorOrderStatus.delivered;
      case 8:
        return VendorOrderStatus.cancelled;
      case 9:
        return VendorOrderStatus.returned;
      default:
        return VendorOrderStatus.pending;
    }
  }
}
