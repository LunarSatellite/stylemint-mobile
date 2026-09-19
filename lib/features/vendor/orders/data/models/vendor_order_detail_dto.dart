import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
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
    final state = (json['state'] as num?)?.toInt() ?? 1;

    return VendorOrder(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as String? ?? '',
      itemCount: (json['itemCount'] as num?)?.toInt() ?? lines.length,
      total: Money(
        amount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0,
        currency: currency,
      ),
      status: vendorOrderStatusFromState(state),
      stateCode: state,
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
    // `lines[].id` is the sub-order line id the per-unit binding routes
    // take. It was already on the wire and simply not read.
    subOrderLineId: (l['id'] as String?) ?? '',
    productId: (l['productVariantId'] as String?) ?? '',
    productName: (l['productTitleSnapshot'] as String?) ?? '',
    imageUrl: absoluteMediaUrl((l['thumbnailUrlSnapshot'] as String?) ?? ''),
    quantity: (l['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: Money(
      amount: (l['unitPriceAmount'] as num?)?.toDouble() ?? 0,
      currency: (l['unitPriceCurrency'] as String?) ?? 'NPR',
    ),
  );

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;

  /// The customer's own directions when they exist, else the legacy postal
  /// parts joined — skipping every empty one, so a null city never becomes
  /// "null" or a stray comma. Location-captured addresses carry no postal
  /// text at all, so the note (or the point) is all there is to show.
  static String? _formatAddress(Map<String, dynamic>? a) {
    if (a == null) return null;
    final note = ((a['locationNote'] as String?) ?? '').trim();
    if (note.isNotEmpty) return note;
    final lat = (a['latitude'] as num?)?.toDouble();
    final lng = (a['longitude'] as num?)?.toDouble();
    final parts = <String>[
      (a['addressLine1'] as String?) ?? '',
      (a['city'] as String?) ?? '',
      [
        (a['state'] as String?) ?? '',
        (a['zipCode'] as String?) ?? '',
      ].where((s) => s.isNotEmpty).join(' '),
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(', ');
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }
    final link = ((a['mapsLink'] as String?) ?? '').trim();
    return link.isEmpty ? null : link;
  }
}
