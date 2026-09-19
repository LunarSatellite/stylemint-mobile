import 'package:freezed_annotation/freezed_annotation.dart';

part 'reorder_suggestion_dto.freezed.dart';
part 'reorder_suggestion_dto.g.dart';

/// Mirrors the backend's `ReorderSuggestionDto` (Orders module,
/// `GET /v1/customer/reorder-suggestions`) — predictions computed from the
/// customer's purchase cadence by the nightly `orders.reorder-predictions-
/// recalculate` job, surfaced here as the "Buy It Again" list.
@freezed
abstract class ReorderSuggestionDto with _$ReorderSuggestionDto {
  const factory ReorderSuggestionDto({
    required String productId,
    required String productName,
    String? thumbnailUrl,
    required int suggestedQuantity,
    required String reason,
    required double price,
    required String currency,
    required int daysUntilExpected,
    /// The model's internal confidence, when the backend still sends one.
    ///
    /// **Optional on purpose, and never drawn.** This is a score on a
    /// customer-facing payload, and it is being retired: the backend applies
    /// its own confidence floor before a row is ever returned, so the number
    /// decides nothing on this side. Nothing in the app reads it, and nothing
    /// may start — the customer-legible form of this threshold is
    /// `steadiness` on the replenishment rules, three named choices with no
    /// number behind them.
    ///
    /// It parses as nullable so that a payload omitting it entirely still
    /// loads on clients already in the field. There is deliberately **no
    /// default**: an absent score stays absent rather than becoming a
    /// fabricated zero. Once shipped, the backend is free to drop the field.
    double? confidence,
  }) = _ReorderSuggestionDto;

  factory ReorderSuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$ReorderSuggestionDtoFromJson(json);
}
