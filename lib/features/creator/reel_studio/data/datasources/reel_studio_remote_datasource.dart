import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_briefing_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_extras_dto.dart';

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

  Future<List<CoachingTipDto>> getCoachingTips(String draftId) async {
    final response = await apiClient.get(
      '/v1/creator/studio/coaching/tips',
      queryParameters: {'draftId': draftId},
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => CoachingTipDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<CollabSuggestionDto>> getCollabSuggestions() async {
    final response = await apiClient.get(
      '/v1/creator/studio/collab-suggestions',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => CollabSuggestionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<DropPartyPromptDto> getDropPartyPrompt() async {
    final response = await apiClient.get(
      '/v1/creator/studio/drop-party-prompt',
    );
    return DropPartyPromptDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TagNudgeDto>> getTagNudges() async {
    final response = await apiClient.get(
      '/v1/creator/studio/tag-nudges',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => TagNudgeDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<LaunchpadDto> getLaunchpad() async {
    final response = await apiClient.get('/v1/creator/studio/launchpad');
    return LaunchpadDto.fromJson(response as Map<String, dynamic>);
  }

  Future<ReelDraftDto> createDraft({
    required String caption,
    required List<String> hashtags,
    required List<String> taggedProductIds,
    required String platform,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/studio/drafts',
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
    String? platform,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.put(
      '/v1/creator/studio/drafts/$draftId',
      data: {
        if (caption != null) 'caption': caption,
        if (hashtags != null) 'hashtags': hashtags,
        if (taggedProductIds != null) 'taggedProductIds': taggedProductIds,
        if (platform != null) 'platform': platform,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ReelDraftDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ReelDraftDto>> getDrafts() async {
    final response = await apiClient.get('/v1/creator/studio/drafts');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => ReelDraftDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<void> deleteDraft(String draftId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/creator/studio/drafts/$draftId',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<ReelStudioBriefingDto> requestCoaching(
    String draftId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/creator/studio/analyze',
      data: {'reelDraftId': draftId},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ReelStudioBriefingDto.fromJson(response as Map<String, dynamic>);
  }
}
