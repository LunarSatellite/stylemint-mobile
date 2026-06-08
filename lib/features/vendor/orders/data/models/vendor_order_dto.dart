import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_order_dto.freezed.dart';
part 'vendor_order_dto.g.dart';

@freezed
abstract class VendorOrderItemDto with _$VendorOrderItemDto {
  const factory VendorOrderItemDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required int quantity,
    required double unitPriceAmount,
    @Default('NPR') String currency,
  }) = _VendorOrderItemDto;

  const VendorOrderItemDto._();

  factory VendorOrderItemDto.fromJson(Map<String, dynamic> json) =>
      _$VendorOrderItemDtoFromJson(json);

  VendorOrderItem toDomain() => VendorOrderItem(
        productId: productId,
        productName: productName,
        imageUrl: imageUrl,
        quantity: quantity,
        unitPrice: Money(amount: unitPriceAmount, currency: currency),
      );
}

/// Maps the backend VendorSubOrderListItemDto (Orders module,
/// GET /v1/vendor/sub-orders). `state` is the integer SubOrderState enum
/// (no string-enum converter is configured server-side). Amounts are `num`
/// because System.Text.Json serializes whole `decimal`s as ints.
@freezed
abstract class VendorOrderDto with _$VendorOrderDto {
  const factory VendorOrderDto({
    required String id,
    required String orderNumber,
    @JsonKey(name: 'state') @Default(1) int stateCode,
    @JsonKey(name: 'subtotalAmount') required num totalAmount,
    @JsonKey(name: 'subtotalCurrency') @Default('NPR') String currency,
    @Default(0) int itemCount,
    @JsonKey(name: 'carrier') String? shippingMethod,
    String? trackingNumber,
    @JsonKey(name: 'placedUtc') DateTime? placedAt,
    @JsonKey(name: 'shippedUtc') DateTime? shippedAt,
    @JsonKey(name: 'deliveredUtc') DateTime? deliveredAt,
  }) = _VendorOrderDto;

  const VendorOrderDto._();

  factory VendorOrderDto.fromJson(Map<String, dynamic> json) =>
      _$VendorOrderDtoFromJson(json);

  VendorOrder toDomain() => VendorOrder(
        id: id,
        orderNumber: orderNumber,
        itemCount: itemCount,
        total: Money(amount: totalAmount.toDouble(), currency: currency),
        status: _statusFromState(stateCode),
        placedAt: placedAt,
        shippingMethod: shippingMethod,
        trackingNumber: trackingNumber,
        shippedAt: shippedAt,
        deliveredAt: deliveredAt,
      );

  /// SubOrderState enum int -> UI status. The internal vendor-workflow states
  /// (Paid/AwaitingFulfillment/ReadyToShip/AwaitingTracking) collapse to
  /// Confirmed/Processing; transit states map to Shipped.
  static VendorOrderStatus _statusFromState(int state) {
    switch (state) {
      case 1: // Pending
        return VendorOrderStatus.pending;
      case 2: // Paid
        return VendorOrderStatus.confirmed;
      case 3: // AwaitingFulfillment
      case 4: // ReadyToShip
      case 5: // AwaitingTracking
        return VendorOrderStatus.processing;
      case 6: // Shipped
      case 10: // InTransit
      case 11: // OutForDelivery
        return VendorOrderStatus.shipped;
      case 7: // Delivered
        return VendorOrderStatus.delivered;
      case 8: // Cancelled
        return VendorOrderStatus.cancelled;
      case 9: // Returned
        return VendorOrderStatus.returned;
      default:
        return VendorOrderStatus.pending;
    }
  }
}
