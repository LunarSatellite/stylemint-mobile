import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_tag_suggestion.dart';

/// ML product-tag suggestions for a creator's own reel.
class ReelTagSuggestionsRemoteDataSource {
  ReelTagSuggestionsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  String _base(String reelId) => '/v1/creator/reels/$reelId/tag-suggestions';

  /// `GET /v1/creator/reels/{reelId}/tag-suggestions` — a bare JSON array of
  /// detections, each with its candidate products.
  Future<List<ReelTagSuggestionDetection>> listSuggestions(
    String reelId,
  ) async {
    final response = await apiClient.get(_base(reelId));
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(ReelTagSuggestionDetection.fromJson)
        .toList(growable: false);
  }

  /// `POST .../tag-suggestions/{suggestionId}/accept` — tags the product.
  Future<void> acceptSuggestion(
    String reelId,
    String suggestionId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '${_base(reelId)}/$suggestionId/accept',
      data: <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
  }

  /// `POST .../tag-suggestions/{suggestionId}/dismiss`.
  Future<void> dismissSuggestion(
    String reelId,
    String suggestionId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '${_base(reelId)}/$suggestionId/dismiss',
      data: <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
  );
}
