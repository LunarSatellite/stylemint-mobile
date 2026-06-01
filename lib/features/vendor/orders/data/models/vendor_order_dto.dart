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

@freezed
abstract class VendorOrderDto with _$VendorOrderDto {
  const factory VendorOrderDto({
    required String id,
    required String orderNumber,
    required String customerName,
    required List<VendorOrderItemDto> items,
    required double totalAmount,
    required String status,
    required DateTime placedAt,
    required String shippingAddress,
    @Default('NPR') String currency,
  }) = _VendorOrderDto;

  const VendorOrderDto._();

  factory VendorOrderDto.fromJson(Map<String, dynamic> json) =>
      _$VendorOrderDtoFromJson(json);

  VendorOrder toDomain() => VendorOrder(
        id: id,
        orderNumber: orderNumber,
        customerName: customerName,
        items: items.map((dto) => dto.toDomain()).toList(growable: false),
        total: Money(amount: totalAmount, currency: currency),
        status: _statusFromCode(status),
        placedAt: placedAt,
        shippingAddress: shippingAddress,
      );

  static VendorOrderStatus _statusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'pending':
        return VendorOrderStatus.pending;
      case 'confirmed':
        return VendorOrderStatus.confirmed;
      case 'processing':
        return VendorOrderStatus.processing;
      case 'shipped':
        return VendorOrderStatus.shipped;
      case 'delivered':
        return VendorOrderStatus.delivered;
      case 'cancelled':
      case 'canceled':
        return VendorOrderStatus.cancelled;
      case 'returned':
        return VendorOrderStatus.returned;
      default:
        return VendorOrderStatus.pending;
    }
  }
}
