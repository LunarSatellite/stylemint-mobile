import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'tracked_order_dto.freezed.dart';
part 'tracked_order_dto.g.dart';

/// Maps `GET /v1/orders` — backend `OrderListItemDto`
/// (StyleMint.Modules.Orders). Field names/types here are the actual wire
/// shape: total is `grandTotalAmount`/`grandTotalCurrency` (not `amount`/
/// `currency`), the placed timestamp is `placedUtc` (not `placedAt`), and
/// status is the numeric `OrderState` enum in a field named `state` (not a
/// string `status`) — the old guesses threw on `fromJson` for any non-empty
/// response.
@freezed
abstract class TrackedOrderDto with _$TrackedOrderDto {
  const factory TrackedOrderDto({
    required String id,
    required String orderNumber,
    @Default(0) double grandTotalAmount,
    @Default('NPR') String grandTotalCurrency,
    required DateTime placedUtc,
    @Default(0) int itemCount,
    @Default(1) int state, // OrderState: 1=Placed,2=Paid,3=Fulfilling,4=Completed,5=Cancelled
  }) = _TrackedOrderDto;

  const TrackedOrderDto._();

  factory TrackedOrderDto.fromJson(Map<String, dynamic> json) =>
      _$TrackedOrderDtoFromJson(json);

  TrackedOrder toDomain() => TrackedOrder(
    id: id,
    orderNumber: orderNumber,
    total: Money(amount: grandTotalAmount, currency: grandTotalCurrency),
    placedAt: placedUtc,
    itemCount: itemCount,
    status: _statusFromState(state),
  );

  // Backend OrderState is coarser than the mobile shipping-stage pill (it
  // doesn't yet track in-transit/out-for-delivery granularity — that lives
  // in the Delivery module) — best-effort mapping onto what exists today.
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
}
