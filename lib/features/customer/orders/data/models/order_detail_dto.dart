import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'order_detail_dto.freezed.dart';
part 'order_detail_dto.g.dart';

@freezed
abstract class OrderDetailItemDto with _$OrderDetailItemDto {
  const factory OrderDetailItemDto({
    required String productId,
    required String productName,
    required String imageUrl,
    required String variantName,
    required int qty,
    required double unitPriceAmount,
    required String status,
    @Default('NPR') String currency,
  }) = _OrderDetailItemDto;

  const OrderDetailItemDto._();

  factory OrderDetailItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailItemDtoFromJson(json);

  OrderDetailItem toDomain() => OrderDetailItem(
    productId: productId,
    productName: productName,
    imageUrl: imageUrl,
    variantName: variantName,
    qty: qty,
    unitPrice: Money(amount: unitPriceAmount, currency: currency),
    status: status,
  );
}

@freezed
abstract class OrderDetailDto with _$OrderDetailDto {
  const factory OrderDetailDto({
    required String id,
    required String orderNumber,
    required String status,
    required DateTime placedAt,
    required DateTime estimatedDelivery,
    required List<OrderDetailItemDto> items,
    required double subtotalAmount,
    required double shippingAmount,
    required double taxAmount,
    required double totalAmount,
    required String shippingAddress,
    required String paymentMethod,
    @Default('NPR') String currency,
    String? trackingNumber,
    @Default(false) bool canCancel,
    @Default(false) bool canReturn,
  }) = _OrderDetailDto;

  const OrderDetailDto._();

  factory OrderDetailDto.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailDtoFromJson(json);

  OrderDetail toDomain() => OrderDetail(
    id: id,
    orderNumber: orderNumber,
    status: _statusFromCode(status),
    placedAt: placedAt,
    estimatedDelivery: estimatedDelivery,
    items: items.map((dto) => dto.toDomain()).toList(growable: false),
    subtotal: Money(amount: subtotalAmount, currency: currency),
    shipping: Money(amount: shippingAmount, currency: currency),
    tax: Money(amount: taxAmount, currency: currency),
    total: Money(amount: totalAmount, currency: currency),
    shippingAddress: shippingAddress,
    paymentMethod: paymentMethod,
    trackingNumber: trackingNumber,
    canCancel: canCancel,
    canReturn: canReturn,
  );

  static OrderTrackStatus _statusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'preparing_for_shipping':
      case 'preparing':
        return OrderTrackStatus.preparingForShipping;
      case 'in_transit':
      case 'shipping':
        return OrderTrackStatus.inTransit;
      case 'out_for_delivery':
        return OrderTrackStatus.outForDelivery;
      case 'delivered':
        return OrderTrackStatus.delivered;
      case 'cancelled':
        return OrderTrackStatus.cancelled;
      default:
        return OrderTrackStatus.preparingForShipping;
    }
  }
}
