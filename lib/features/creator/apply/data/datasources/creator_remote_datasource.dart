import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/data/models/creator_application_dto.dart';

class CreatorRemoteDataSource {
  CreatorRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorApplicationDto> getApplicationStatus() async {
    final response = await apiClient.get('/v1/creator/application');
    return CreatorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Instant creator onboarding — `POST /v1/creator/activate`. Both fields
  /// optional (`bio` ≤ 500, `expression` ≤ 140 free text). Idempotent: a repeat
  /// call for an existing creator returns the same result. Response:
  /// `{ creatorProfileId, profileApproved, creatorRoleActive }`.
  Future<void> activate({
    String? bio,
    String? expression,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/creator/activate',
      data: <String, dynamic>{
        if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
        if (expression != null && expression.trim().isNotEmpty)
          'expression': expression.trim(),
      },
      options: _idempotent(idempotencyKey),
    );
  }

  /// Public list of creator content categories (no auth required). Returns the
  /// raw decoded `CreatorContentCategoryDto` maps; the repository maps + orders.
  Future<List<Map<String, dynamic>>> getCreatorCategories() async {
    final response = await apiClient.authGet('/v1/public/creator-categories');
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Body matches `SubmitCreatorApplicationVm` exactly:
  /// `{ bio, audienceBand:int(1..5), contentCategoryIds:[uuid] (required,
  /// non-empty), otherCategoryDescription?, socials:[{ provider:int(1..4),
  /// handle?, followerCountSelfReported? }] }`. There is no fullName/handle/
  /// portfolio/identityDoc on this endpoint.
  Future<CreatorApplicationDto> submitApplication({
    required List<String> contentCategoryIds,
    required int audienceBand,
    required List<Map<String, dynamic>> socials,
    required String bio,
    String? otherCategoryDescription,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/apply',
      data: {
        'bio': bio,
        'audienceBand': audienceBand,
        'contentCategoryIds': contentCategoryIds,
        if (otherCategoryDescription != null &&
            otherCategoryDescription.trim().isNotEmpty)
          'otherCategoryDescription': otherCategoryDescription,
        if (socials.isNotEmpty) 'socials': socials,
      },
      options: _idempotent(idempotencyKey),
    );
    return CreatorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  /// Re-submit a rejected creator application with a fresh payload.
  /// `POST /v1/creator/reapply` → atomic Rejected → Submitted on the most-recent
  /// rejected application for the caller. Returns the updated application.
  /// 404 if no rejected application exists.
  Future<CreatorApplicationDto> reapplyApplication({
    required List<String> contentCategoryIds,
    required int audienceBand,
    required List<Map<String, dynamic>> socials,
    required String bio,
    String? otherCategoryDescription,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/reapply',
      data: {
        'bio': bio,
        'audienceBand': audienceBand,
        'contentCategoryIds': contentCategoryIds,
        if (otherCategoryDescription != null &&
            otherCategoryDescription.trim().isNotEmpty)
          'otherCategoryDescription': otherCategoryDescription,
        if (socials.isNotEmpty) 'socials': socials,
      },
      options: _idempotent(idempotencyKey),
    );
    return CreatorApplicationDto.fromJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
