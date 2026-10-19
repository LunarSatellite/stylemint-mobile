import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_delivery.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/service_line_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';

part 'order_detail_dto.freezed.dart';
part 'order_detail_dto.g.dart';

/// Maps a `SubOrderLineDto` (backend StyleMint.Modules.Orders). Line items
/// live nested under `subOrders[].lines[]`, one array per vendor — not a
/// flat top-level `items` array.
@freezed
abstract class OrderDetailItemDto with _$OrderDetailItemDto {
  const factory OrderDetailItemDto({
    @Default('') String id,
    required String productVariantId,
    @Default('') String productTitleSnapshot,
    String? variantLabelSnapshot,
    String? thumbnailUrlSnapshot,
    @Default(0) int quantity,
    @Default(0) double unitPriceAmount,
    @Default('NPR') String unitPriceCurrency,
    // Service cart contract v1 §4.1: a stay or trip line and its booking.
    // Read by hand; absent before the contract.
    Object? lineKind,
    Object? booking,
  }) = _OrderDetailItemDto;

  const OrderDetailItemDto._();

  factory OrderDetailItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailItemDtoFromJson(json);

  /// This line's booking, when it is a stay or trip.
  ServiceLine? get bookingLine => isServiceLineKind(lineKind) || booking != null
      ? readServiceLine(booking, lineId: id)
      : null;

  OrderDetailItem toDomain(String subOrderId, String subOrderStatusLabel) =>
      OrderDetailItem(
        id: id,
        subOrderId: subOrderId,
        productId: productVariantId,
        productName: productTitleSnapshot,
        imageUrl: thumbnailUrlSnapshot ?? '',
        variantName: variantLabelSnapshot ?? '',
        qty: quantity,
        unitPrice: Money(amount: unitPriceAmount, currency: unitPriceCurrency),
        status: subOrderStatusLabel,
      );
}

/// Maps `SubOrderDto` — one per vendor inside the order.
@freezed
abstract class SubOrderDto with _$SubOrderDto {
  const factory SubOrderDto({
    @Default('') String id,
    @Default(1) int state, // SubOrderState
    String? trackingNumber,
    // `OrderFulfillmentChannel` on the wire is a string ("Delivery" /
    // "StorePickup"). Kept raw and mapped where it is read, so an
    // unrecognised value degrades to delivery instead of throwing.
    @Default('Delivery') String fulfillmentChannel,
    DateTime? collectedUtc,
    // Cancellation facts (backend SubOrderDto). `cancelledBy` is the
    // SubOrderActorKind: 1=Vendor, 2=Customer, 3=System, 4=Courier, 5=Admin.
    int? cancelledBy,
    // VendorRejectionReason: 1=OutOfStock, 2=CannotFulfillInTime,
    // 3=PricingError, 4=AddressNotServiceable, 5=SuspectedFraud, 6=Other.
    int? vendorRejectionReasonCode,
    String? cancellationNote,
    // Pending / Completed / Failed / NotCharged.
    String? refundStatus,
    @Default(0) double subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    @Default(<OrderDetailItemDto>[]) List<OrderDetailItemDto> lines,
  }) = _SubOrderDto;

  const SubOrderDto._();

  factory SubOrderDto.fromJson(Map<String, dynamic> json) =>
      _$SubOrderDtoFromJson(json);

  static const _cancelled = 8;
  static const _actorVendor = 1;

  bool get isCancelled => state == _cancelled;
  bool get isCancelledBySeller => isCancelled && cancelledBy == _actorVendor;

  CancelledOrderPart toCancelledPart() {
    final reason = sellerReasonText(vendorRejectionReasonCode);
    final note = cancellationNote?.trim() ?? '';
    final parts = <String>[
      if (isCancelledBySeller && reason.isNotEmpty) reason,
      if (note.isNotEmpty && note != reason) note,
    ];
    return CancelledOrderPart(
      subOrderId: id,
      cancelledBySeller: isCancelledBySeller,
      reason: parts.join(' — '),
      refund: CancelledPartRefund.fromWire(refundStatus),
      itemNames: lines
          .map((l) => l.productTitleSnapshot)
          .where((t) => t.isNotEmpty)
          .toList(growable: false),
      amount: subtotalAmount > 0
          ? Money(amount: subtotalAmount, currency: subtotalCurrency)
          : null,
    );
  }

  /// The seller's reason in the buyer's words.
  static String sellerReasonText(int? code) => switch (code) {
    1 => 'Out of stock',
    2 => "The seller can't fulfil it in time",
    3 => 'Pricing error',
    4 => "The seller can't deliver to your address",
    5 => 'The seller could not verify the order',
    6 => 'Other',
    _ => '',
  };
}

/// Maps the `shipTo` `ShippingAddressSnapshot`.
///
/// The postal fields are **nullable**: addresses captured by location have no
/// street, city, state or postal code at all. They are `String?` rather than
/// `@Default('')` because a default only fills a *missing* key — an explicit
/// `"city": null` would throw and break the whole order detail screen.
@freezed
abstract class ShippingAddressSnapshotDto with _$ShippingAddressSnapshotDto {
  const factory ShippingAddressSnapshotDto({
    @Default('') String receiverName,
    @Default('') String receiverPhone,
    @Default('') String locationNote,
    String? mapsLink,
    double? latitude,
    double? longitude,
    String? addressLine1,
    String? landmark,
    String? city,
    String? state,
    String? zipCode,
    String? country,
  }) = _ShippingAddressSnapshotDto;

  const ShippingAddressSnapshotDto._();

  factory ShippingAddressSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressSnapshotDtoFromJson(json);

  /// One readable line for the order's ship-to address. Prefers the
  /// customer's own directions, falls back to whatever postal text the
  /// snapshot carries, then to the raw point. Every null/blank part is
  /// dropped, so a null city never renders as "null" or an empty line.
  String toDisplayString() {
    final note = locationNote.trim();
    if (note.isNotEmpty) return note;

    final parts = [
      addressLine1,
      landmark,
      city,
      state,
      zipCode,
    ].map((p) => p?.trim() ?? '').where((p) => p.isNotEmpty);
    if (parts.isNotEmpty) return parts.join(', ');

    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(5)}, '
          '${longitude!.toStringAsFixed(5)}';
    }
    final link = mapsLink?.trim() ?? '';
    if (link.isNotEmpty) return link;
    return 'Location saved';
  }
}

/// Maps `GET /v1/orders/{orderNumber}` — backend `OrderDto`
/// (StyleMint.Modules.Orders). Line items are nested under
/// `subOrders[].lines[]` (one sub-order per vendor); there is no flat
/// top-level `items`, `estimatedDelivery`, `status` string, or
/// `shippingAddress`/`paymentMethod` string field — those are all
/// derived here from the actual nested shape.
@freezed
abstract class OrderDetailDto with _$OrderDetailDto {
  const factory OrderDetailDto({
    required String id,
    required String orderNumber,
    @Default(1)
    int
    state, // OrderState: 1=Placed,2=Paid,3=Fulfilling,4=Completed,5=Cancelled
    required DateTime placedUtc,
    @Default(ShippingAddressSnapshotDto()) ShippingAddressSnapshotDto shipTo,
    @Default(4)
    int paymentMethod, // PaymentMethod: 1=Card,2=PayPal,3=Esewa,4=Cod
    @Default(<SubOrderDto>[]) List<SubOrderDto> subOrders,
    @Default(0) double subtotalAmount,
    @Default('NPR') String subtotalCurrency,
    @Default(0) double shippingTotalAmount,
    @Default('NPR') String shippingTotalCurrency,
    @Default(0) double taxTotalAmount,
    @Default('NPR') String taxTotalCurrency,
    // Whether the tax total is inside the prices (every order since prices
    // included VAT) or was charged on top (older orders). Absent, from a
    // backend that predates the flag, it reads as included — what every
    // screen said before.
    @Default(true) bool taxIncluded,
    @Default(0) double grandTotalAmount,
    @Default('NPR') String grandTotalCurrency,
    // The payment plan this order is bought on (EMI-after-delivery contract
    // v1). Absent from an older server → null ("not said"); present and
    // null → '' ("paid outright").
    @JsonKey(readValue: _readCreditAgreementId) String? creditAgreementId,
    // Service cart contract v1 §4.1.
    double? payAtVenueTotalAmount,
    @Default('NPR') String payAtVenueTotalCurrency,
  }) = _OrderDetailDto;

  const OrderDetailDto._();

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailDtoFromJson(json);

  /// [delivery] is the hand-read `delivery` block (see `OrderDeliveryJson`),
  /// passed in because it is not one of this DTO's generated fields.
  OrderDetail toDomain({OrderDelivery? delivery}) {
    // Stays and trips (service cart contract v1 §4.1) live in their own
    // sub-orders, with no address, delivery or return. The product part
    // decides the channel, the cancel and the return; the bookings are
    // listed apart, each cancelled through its own policy.
    final bookingLines = <ServiceLine>[
      for (final s in subOrders)
        for (final l in s.lines) ?l.bookingLine,
    ];
    final productSubOrders = subOrders
        .where((s) => s.fulfillmentChannel.toLowerCase() != 'service')
        .toList();
    // A parcel the buyer has just confirmed is Delivered on its sub-order
    // before the order itself is closed. With every sub-order delivered the
    // order reads as delivered, rather than "in transit" until the order
    // catches up.
    // A part the seller (or buyer) cancelled will never arrive: it neither
    // holds the order on "Preparing for Shipping" nor stops it reading as
    // delivered once everything still live has arrived.
    final live = subOrders.where((s) => !s.isCancelled).toList();
    final allCancelled = subOrders.isNotEmpty && live.isEmpty;
    final allDelivered =
        live.isNotEmpty && live.every((s) => s.state == _subOrderDelivered);
    final overallStatus = allCancelled
        ? OrderTrackStatus.cancelled
        : allDelivered && (state == 2 || state == 3)
        ? OrderTrackStatus.delivered
        : _statusFromState(state);
    // Checkout only offers collection when every line comes from one seller,
    // so a collection order is the whole order — but read it as "every
    // sub-order says so" rather than "the first one does", which keeps a
    // mixed order (which cannot exist today) on the delivery path instead of
    // silently hiding a real address.
    final channel =
        productSubOrders.isNotEmpty &&
            productSubOrders.every(
              (s) => OrderFulfillmentChannel.fromWire(
                s.fulfillmentChannel,
              ).isCollection,
            )
        ? OrderFulfillmentChannel.storePickup
        : OrderFulfillmentChannel.delivery;
    final collectedAt = subOrders
        .map((s) => s.collectedUtc)
        .firstWhere((d) => d != null, orElse: () => null);
    final trackingNumber = subOrders
        .map((s) => s.trackingNumber)
        .firstWhere((t) => t != null && t.isNotEmpty, orElse: () => null);

    return OrderDetail(
      id: id,
      orderNumber: orderNumber,
      creditAgreementId: creditAgreementId,
      status: overallStatus,
      placedAt: placedUtc,
      // Not returned by this endpoint — approximate until a real ETA field
      // ships (delivery-routing module).
      estimatedDelivery: placedUtc.add(const Duration(days: 7)),
      bookingLines: List.unmodifiable(bookingLines),
      payAtVenue: (payAtVenueTotalAmount ?? 0) > 0
          ? Money(
              amount: payAtVenueTotalAmount!,
              currency: payAtVenueTotalCurrency,
            )
          : null,
      items: subOrders
          .expand(
            (s) => s.lines.where((l) => l.bookingLine == null).map(
              (l) => l.toDomain(
                s.id,
                s.isCancelledBySeller
                    ? 'Cancelled by the seller'
                    : _subOrderStateLabel(s.state),
              ),
            ),
          )
          .toList(growable: false),
      subtotal: Money(amount: subtotalAmount, currency: subtotalCurrency),
      shipping: Money(
        amount: shippingTotalAmount,
        currency: shippingTotalCurrency,
      ),
      tax: Money(amount: taxTotalAmount, currency: taxTotalCurrency),
      taxIncluded: taxIncluded,
      total: Money(amount: grandTotalAmount, currency: grandTotalCurrency),
      // A collection order's shipTo is an empty snapshot, because there is
      // no address. toDisplayString() bottoms out at "Location saved",
      // which would print a destination nobody chose as fact. Absent
      // renders as absent.
      shippingAddress: channel.isCollection || productSubOrders.isEmpty
          ? ''
          : shipTo.toDisplayString(),
      fulfillmentChannel: channel,
      collectedAt: collectedAt,
      receiverName: shipTo.receiverName,
      receiverPhone: shipTo.receiverPhone,
      paymentMethod: _paymentMethodLabel(paymentMethod),
      trackingNumber: trackingNumber,
      // The whole-order cancel never touches stays and trips (§4.2).
      canCancel:
          overallStatus == OrderTrackStatus.preparingForShipping &&
          productSubOrders.isNotEmpty,
      canReturn:
          overallStatus == OrderTrackStatus.delivered &&
          productSubOrders.isNotEmpty,
      delivery: delivery,
      cancelledParts: productSubOrders
          .where((s) => s.isCancelled)
          .map((s) => s.toCancelledPart())
          .toList(growable: false),
    );
  }

  /// `SubOrderState.Delivered`.
  static const _subOrderDelivered = 7;

  static OrderTrackStatus _statusFromState(int state) {
    switch (state) {
      case 1: // Placed
      case 2: // Paid
        return OrderTrackStatus.preparingForShipping;
      case 3: // Fulfilling
        return OrderTrackStatus.inTransit;
      case 4: // Completed
        return OrderTrackStatus.delivered;
      case 5: // Cancelled
        return OrderTrackStatus.cancelled;
      default:
        return OrderTrackStatus.preparingForShipping;
    }
  }

  static String _subOrderStateLabel(int state) {
    switch (state) {
      case 6:
        return 'Shipped';
      case 7:
        return 'Delivered';
      case 8:
        return 'Cancelled';
      case 9:
        return 'Returned';
      case 10:
        return 'In Transit';
      case 11:
        return 'Out for Delivery';
      case 12: // Accepted (seller step)
        return 'Accepted';
      case 13: // Packed (seller step)
        return 'Packed';
      case 14: // HandedOver (seller step)
        return 'Handed over';
      default: // Pending..AwaitingTracking and any state this app doesn't know

        return 'Confirmed';
    }
  }

  static String _paymentMethodLabel(int code) {
    switch (code) {
      case 1:
        return 'Card';
      case 2:
        return 'PayPal';
      case 3:
        return 'eSewa';
      case 4:
        return 'Cash on Delivery';
      default:
        return 'Cash on Delivery';
    }
  }
}

/// `creditAgreementId` as sent, telling "not sent" (null) from "sent as
/// null" (''), so the order screen only looks a plan up when it may exist.
Object? _readCreditAgreementId(Map<dynamic, dynamic> json, String key) {
  if (!json.containsKey(key)) return null;
  final value = json[key];
  return value is String ? value.trim() : '';
}
