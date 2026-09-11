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
    required double confidence,
  }) = _ReorderSuggestionDto;

  factory ReorderSuggestionDto.fromJson(Map<String, dynamic> json) =>
      _$ReorderSuggestionDtoFromJson(json);
}
