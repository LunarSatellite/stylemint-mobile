import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_dto.dart';

class ReelStudioRemoteDataSource {
  ReelStudioRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ReelRecipeDto>> getRecipes({
    String? platform,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/studio/recipes',
      queryParameters: {
        if (platform != null) 'platform': platform,
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => ReelRecipeDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<CoachingFeedbackDto> getCoachingFeedback(String draftId) async {
    final response = await apiClient.get(
      '/v1/creator/studio/coaching/insight',
    );
    return CoachingFeedbackDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ReelDraftDto> createDraft({
    required String caption,
    required List<String> hashtags,
    required List<String> taggedProductIds,
    required String platform,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/recipes/draft',
      data: {
        'caption': caption,
        'hashtags': hashtags,
        'taggedProductIds': taggedProductIds,
        'platform': platform,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ReelDraftDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ReelDraftDto> updateDraft({
    required String draftId,
    String? caption,
    List<String>? hashtags,
    List<String>? taggedProductIds,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.put(
      '/v1/creator/recipes/$draftId',
      data: {
        if (caption != null) 'caption': caption,
        if (hashtags != null) 'hashtags': hashtags,
        if (taggedProductIds != null) 'taggedProductIds': taggedProductIds,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ReelDraftDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ReelDraftDto>> getDrafts() async {
    final response = await apiClient.get('/v1/creator/recipes/draft');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => ReelDraftDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  // TODO(swagger): DELETE /v1/creator/recipes/draft/{id} not found; re-evaluate draft deletion path
  Future<void> deleteDraft(String draftId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/creator/reel-studio/drafts/$draftId',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<ReelDraftDto> requestCoaching(
    String draftId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/creator/studio/analyze',
      data: {},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ReelDraftDto.fromJson(response as Map<String, dynamic>);
  }
}
