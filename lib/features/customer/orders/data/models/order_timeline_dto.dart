import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';

part 'order_timeline_dto.freezed.dart';
part 'order_timeline_dto.g.dart';

/// `TimelineStepDto` (Orders contract §3). `step` and `status` stay ints on
/// the wire and map to enums in [toDomain], so unknown values never throw.
@freezed
abstract class TimelineStepDto with _$TimelineStepDto {
  const factory TimelineStepDto({
    @Default(0) int step,
    @Default('') String key,
    @Default(3) int status,
    DateTime? occurredUtc,
    String? note,
  }) = _TimelineStepDto;

  const TimelineStepDto._();

  factory TimelineStepDto.fromJson(Map<String, dynamic> json) =>
      _$TimelineStepDtoFromJson(json);

  TimelineStep toDomain() => TimelineStep(
    step: BuyerTimelineStep.fromValue(step),
    key: key,
    status: TimelineStepStatus.fromValue(status),
    occurredUtc: occurredUtc,
    note: note,
  );
}

/// `SubOrderTimelineDto` — one vendor's slice of the order.
@freezed
abstract class SubOrderTimelineDto with _$SubOrderTimelineDto {
  const factory SubOrderTimelineDto({
    @Default('') String subOrderId,
    @Default('') String vendorAccountId,
    String? vendorName,
    @Default(0) int itemsCount,
    @Default(0) int currentStep,
    @Default(false) bool isTerminal,
    String? carrier,
    String? trackingNumber,
    @Default('legacy_unsealed') String deliveryProofStatus,
    DateTime? estimatedDeliveryUtc,
    @Default(<TimelineStepDto>[]) List<TimelineStepDto> steps,
  }) = _SubOrderTimelineDto;

  const SubOrderTimelineDto._();

  factory SubOrderTimelineDto.fromJson(Map<String, dynamic> json) =>
      _$SubOrderTimelineDtoFromJson(json);

  SubOrderTimeline toDomain() => SubOrderTimeline(
    subOrderId: subOrderId,
    vendorAccountId: vendorAccountId,
    vendorName: vendorName,
    itemsCount: itemsCount,
    currentStep: BuyerTimelineStep.fromValue(currentStep),
    isTerminal: isTerminal,
    carrier: carrier,
    trackingNumber: trackingNumber,
    deliveryProofStatus: DeliveryProofStatus.fromWire(deliveryProofStatus),
    estimatedDeliveryUtc: estimatedDeliveryUtc,
    steps: steps.map((s) => s.toDomain()).toList(growable: false),
  );
}

/// `OrderTimelineDto` — `GET /v1/orders/{orderNumber}/timeline`.
@freezed
abstract class OrderTimelineDto with _$OrderTimelineDto {
  const factory OrderTimelineDto({
    required String orderNumber,
    required DateTime placedUtc,
    @Default(0) int orderState,
    @Default(<SubOrderTimelineDto>[]) List<SubOrderTimelineDto> subOrders,
  }) = _OrderTimelineDto;

  const OrderTimelineDto._();

  factory OrderTimelineDto.fromJson(Map<String, dynamic> json) =>
      _$OrderTimelineDtoFromJson(json);

  OrderTimeline toDomain() => OrderTimeline(
    orderNumber: orderNumber,
    orderState: orderState,
    placedUtc: placedUtc,
    subOrders: subOrders.map((s) => s.toDomain()).toList(growable: false),
  );
}
