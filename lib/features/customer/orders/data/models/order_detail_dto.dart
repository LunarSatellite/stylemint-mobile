import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

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
  }) = _OrderDetailItemDto;

  const OrderDetailItemDto._();

  factory OrderDetailItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailItemDtoFromJson(json);

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
    @Default(<OrderDetailItemDto>[]) List<OrderDetailItemDto> lines,
  }) = _SubOrderDto;

  const SubOrderDto._();

  factory SubOrderDto.fromJson(Map<String, dynamic> json) =>
      _$SubOrderDtoFromJson(json);
}

/// Maps the `shipTo` `ShippingAddressSnapshot`.
@freezed
abstract class ShippingAddressSnapshotDto with _$ShippingAddressSnapshotDto {
  const factory ShippingAddressSnapshotDto({
    @Default('') String receiverName,
    @Default('') String receiverPhone,
    @Default('') String addressLine1,
    String? landmark,
    @Default('') String city,
    @Default('') String state,
    @Default('') String zipCode,
    @Default('') String country,
  }) = _ShippingAddressSnapshotDto;

  const ShippingAddressSnapshotDto._();

  factory ShippingAddressSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$ShippingAddressSnapshotDtoFromJson(json);

  String toDisplayString() {
    final parts = [
      addressLine1,
      if (landmark != null) landmark!,
      city,
      state,
      zipCode,
    ].where((p) => p.isNotEmpty);
    return parts.join(', ');
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
    @Default(0) double grandTotalAmount,
    @Default('NPR') String grandTotalCurrency,
  }) = _OrderDetailDto;

  const OrderDetailDto._();

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailDtoFromJson(json);

  OrderDetail toDomain() {
    final overallStatus = _statusFromState(state);
    final trackingNumber = subOrders
        .map((s) => s.trackingNumber)
        .firstWhere((t) => t != null && t.isNotEmpty, orElse: () => null);

    return OrderDetail(
      id: id,
      orderNumber: orderNumber,
      status: overallStatus,
      placedAt: placedUtc,
      // Not returned by this endpoint — approximate until a real ETA field
      // ships (delivery-routing module).
      estimatedDelivery: placedUtc.add(const Duration(days: 7)),
      items: subOrders
          .expand(
            (s) => s.lines.map(
              (l) => l.toDomain(s.id, _subOrderStateLabel(s.state)),
            ),
          )
          .toList(growable: false),
      subtotal: Money(amount: subtotalAmount, currency: subtotalCurrency),
      shipping: Money(
        amount: shippingTotalAmount,
        currency: shippingTotalCurrency,
      ),
      tax: Money(amount: taxTotalAmount, currency: taxTotalCurrency),
      total: Money(amount: grandTotalAmount, currency: grandTotalCurrency),
      shippingAddress: shipTo.toDisplayString(),
      receiverName: shipTo.receiverName,
      receiverPhone: shipTo.receiverPhone,
      paymentMethod: _paymentMethodLabel(paymentMethod),
      trackingNumber: trackingNumber,
      canCancel: overallStatus == OrderTrackStatus.preparingForShipping,
      canReturn: overallStatus == OrderTrackStatus.delivered,
    );
  }

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
      default:
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
