import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_event_history.dart';

part 'order_event_history_dto.freezed.dart';
part 'order_event_history_dto.g.dart';

/// `OrderEventDto` — one recorded fact. `occurredUtc` is nullable here even
/// though the backend always sends it: a missing stamp must drop the stamp,
/// never be back-filled from `placedUtc` or from a neighbouring event.
@freezed
abstract class OrderEventDto with _$OrderEventDto {
  const factory OrderEventDto({
    @Default(0) int sequence,
    @Default('') String code,
    @Default('') String statement,
    DateTime? occurredUtc,
    String? subOrderId,
    String? vendorName,
    @Default('') String source,
    String? detail,
  }) = _OrderEventDto;

  const OrderEventDto._();

  factory OrderEventDto.fromJson(Map<String, dynamic> json) =>
      _$OrderEventDtoFromJson(json);

  OrderEvent toDomain() => OrderEvent(
    sequence: sequence,
    code: code,
    statement: statement,
    occurredUtc: occurredUtc,
    subOrderId: subOrderId,
    vendorName: vendorName,
    source: source,
    detail: detail,
  );
}

/// `OrderEventSourceDto` — the health of one source consulted.
@freezed
abstract class OrderEventSourceDto with _$OrderEventSourceDto {
  const factory OrderEventSourceDto({
    @Default('') String name,
    @Default('unavailable') String status,
    String? note,
  }) = _OrderEventSourceDto;

  const OrderEventSourceDto._();

  factory OrderEventSourceDto.fromJson(Map<String, dynamic> json) =>
      _$OrderEventSourceDtoFromJson(json);

  OrderEventSource toDomain() => OrderEventSource(
    name: name,
    status: OrderEventSourceStatus.fromWire(status),
    note: note,
  );
}

/// `OrderEventHistoryDto` — `GET /v1/orders/{orderNumber}/events`.
@freezed
abstract class OrderEventHistoryDto with _$OrderEventHistoryDto {
  const factory OrderEventHistoryDto({
    @Default('') String orderNumber,
    @Default(0) int orderState,
    DateTime? placedUtc,
    @Default(<OrderEventDto>[]) List<OrderEventDto> events,
    @Default(<OrderEventSourceDto>[]) List<OrderEventSourceDto> sources,
  }) = _OrderEventHistoryDto;

  const OrderEventHistoryDto._();

  factory OrderEventHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$OrderEventHistoryDtoFromJson(json);

  /// Kept in the order the backend sent, which is oldest first. The client
  /// does not re-sort: `sequence` is the backend's own ordering and second-
  /// guessing it would mean inferring a chronology we were handed.
  OrderEventHistory toDomain() => OrderEventHistory(
    orderNumber: orderNumber,
    orderState: orderState,
    placedUtc: placedUtc,
    events: events.map((e) => e.toDomain()).toList(growable: false),
    sources: sources.map((s) => s.toDomain()).toList(growable: false),
  );
}
