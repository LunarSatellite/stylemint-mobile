import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_reason_category.dart';
import 'package:stylemint_mobile_frontend/shared/data/models/return_evidence_dto.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'customer_return_dto.freezed.dart';
part 'customer_return_dto.g.dart';

/// `ReturnProductSnapshotDto` (Orders contract §4).
@freezed
abstract class ReturnProductSnapshotDto with _$ReturnProductSnapshotDto {
  const factory ReturnProductSnapshotDto({
    @Default('') String productVariantId,
    @Default('') String title,
    String? variantLabel,
    String? thumbnailUrl,
    @Default(0) num unitPriceAmount,
    @Default('NPR') String unitPriceCurrency,
  }) = _ReturnProductSnapshotDto;

  const ReturnProductSnapshotDto._();

  factory ReturnProductSnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$ReturnProductSnapshotDtoFromJson(json);

  ReturnProductSnapshot toDomain() => ReturnProductSnapshot(
    productVariantId: productVariantId,
    title: title,
    variantLabel: variantLabel,
    thumbnailUrl: _media(thumbnailUrl),
    unitPrice: Money(
      amount: unitPriceAmount.toDouble(),
      currency: unitPriceCurrency,
    ),
  );
}

/// `ReturnTimelineEntryDto`.
@freezed
abstract class ReturnTimelineEntryDto with _$ReturnTimelineEntryDto {
  const factory ReturnTimelineEntryDto({
    @Default(0) int state,
    DateTime? occurredUtc,
  }) = _ReturnTimelineEntryDto;

  const ReturnTimelineEntryDto._();

  factory ReturnTimelineEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ReturnTimelineEntryDtoFromJson(json);

  ReturnTimelineEntry toDomain() => ReturnTimelineEntry(
    status: ReturnRequestStatus.fromValue(state),
    occurredUtc: occurredUtc,
  );
}

/// `{ amount, currency }` inside [ReturnRefundBreakdownDto].
@freezed
abstract class ReturnMoneyDto with _$ReturnMoneyDto {
  const factory ReturnMoneyDto({
    @Default(0) num amount,
    @Default('NPR') String currency,
  }) = _ReturnMoneyDto;

  const ReturnMoneyDto._();

  factory ReturnMoneyDto.fromJson(Map<String, dynamic> json) =>
      _$ReturnMoneyDtoFromJson(json);

  Money toDomain() => Money(amount: amount.toDouble(), currency: currency);
}

/// `refundBreakdown` (return pickup contract §4). Null until the refund is
/// worked out.
@freezed
abstract class ReturnRefundBreakdownDto with _$ReturnRefundBreakdownDto {
  const factory ReturnRefundBreakdownDto({
    ReturnMoneyDto? itemTotal,
    ReturnMoneyDto? pickupFareDeducted,
    ReturnMoneyDto? refundAmount,
  }) = _ReturnRefundBreakdownDto;

  const ReturnRefundBreakdownDto._();

  factory ReturnRefundBreakdownDto.fromJson(Map<String, dynamic> json) =>
      _$ReturnRefundBreakdownDtoFromJson(json);

  /// Null when the two ends of the sum are missing — nothing is shown then.
  ReturnRefundBreakdown? toDomain() {
    final item = itemTotal;
    final refund = refundAmount;
    if (item == null || refund == null) return null;
    return ReturnRefundBreakdown(
      itemTotal: item.toDomain(),
      pickupFareDeducted:
          pickupFareDeducted?.toDomain() ??
          Money(amount: 0, currency: item.currency),
      refundAmount: refund.toDomain(),
    );
  }
}

/// `CustomerReturnRequestDto` — list items and detail share this shape.
@freezed
abstract class CustomerReturnDto with _$CustomerReturnDto {
  const factory CustomerReturnDto({
    required String id,
    required DateTime submittedUtc,
    @Default('') String orderId,
    @Default('') String orderNumber,
    @Default('') String subOrderId,
    @Default('') String subOrderLineId,
    @Default(ReturnProductSnapshotDto()) ReturnProductSnapshotDto product,
    @Default(0) int quantity,
    @Default('') String reason,
    @Default(<String>[]) List<String> photoUrls,
    @Default(0) int state,
    DateTime? resolvedUtc,
    String? rejectionNote,
    @Default(<ReturnTimelineEntryDto>[]) List<ReturnTimelineEntryDto> timeline,
    String? refundStatus,
    @Default(1) int resolution,
    String? replacementVariantId,
    double? replacementUnitPriceAmount,
    String? replacementUnitPriceCurrency,
    double? replacementPriceDifferenceAmount,
    @Default(0) int replacementState,
    String? replacementPaymentStatus,

    /// Evidence snapshot. Absent or null on every return opened before the
    /// snapshot existed — the ordinary case, never an error.
    ReturnEvidenceDto? evidence,

    /// Return pickup contract §4. All absent on older returns.
    String? reasonCategory,
    String? pickupFarePayer,
    String? pickupStage,
    ReturnRefundBreakdownDto? refundBreakdown,
  }) = _CustomerReturnDto;

  const CustomerReturnDto._();

  factory CustomerReturnDto.fromJson(Map<String, dynamic> json) =>
      _$CustomerReturnDtoFromJson(json);

  CustomerReturn toDomain() => CustomerReturn(
    id: id,
    orderId: orderId,
    orderNumber: orderNumber,
    subOrderId: subOrderId,
    subOrderLineId: subOrderLineId,
    product: product.toDomain(),
    quantity: quantity,
    reason: reason,
    photoUrls: photoUrls
        .map(_media)
        .whereType<String>()
        .toList(growable: false),
    status: ReturnRequestStatus.fromValue(state),
    submittedUtc: submittedUtc,
    resolvedUtc: resolvedUtc,
    rejectionNote: rejectionNote,
    timeline: timeline.map((e) => e.toDomain()).toList(growable: false),
    refundStatus: refundStatus,
    resolution: CustomerReturnResolution.fromCode(resolution),
    replacementVariantId: replacementVariantId,
    replacementUnitPrice: replacementUnitPriceAmount == null
        ? null
        : Money(
            amount: replacementUnitPriceAmount!,
            currency: replacementUnitPriceCurrency ?? 'NPR',
          ),
    replacementPriceDifferenceAmount: replacementPriceDifferenceAmount,
    replacementState: CustomerReplacementState.fromCode(replacementState),
    replacementPaymentStatus: replacementPaymentStatus,
    evidence: evidence?.toDomain(),
    reasonCategory: ReturnReasonCategory.fromWire(reasonCategory),
    pickupFarePayer: ReturnFarePayer.fromWire(pickupFarePayer),
    pickupStage: ReturnPickupStage.fromWire(pickupStage),
    refundBreakdown: refundBreakdown?.toDomain(),
  );
}

String? _media(String? url) {
  final absolute = absoluteMediaUrl(url);
  return absolute.isEmpty ? null : absolute;
}
