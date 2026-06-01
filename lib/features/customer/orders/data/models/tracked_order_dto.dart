import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'tracked_order_dto.freezed.dart';
part 'tracked_order_dto.g.dart';

/// DTO for a tracked order from `/v1/orders`.
@freezed
abstract class TrackedOrderDto with _$TrackedOrderDto {
  const factory TrackedOrderDto({
    required String id,
    required String orderNumber,
    required double amount,
    required DateTime placedAt,
    required int itemCount,
    required String status, // server status code; mapped to OrderTrackStatus
    @Default('NPR') String currency,
  }) = _TrackedOrderDto;

  const TrackedOrderDto._();

  factory TrackedOrderDto.fromJson(Map<String, dynamic> json) =>
      _$TrackedOrderDtoFromJson(json);

  TrackedOrder toDomain() => TrackedOrder(
    id: id,
    orderNumber: orderNumber,
    total: Money(amount: amount, currency: currency),
    placedAt: placedAt,
    itemCount: itemCount,
    status: _statusFromCode(status),
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
