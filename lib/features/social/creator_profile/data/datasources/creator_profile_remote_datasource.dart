import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/badge_award_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/creator_profile_dto.dart';

class CreatorProfileRemoteDataSource {
  CreatorProfileRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorProfileDto> getCreatorProfile(String accountId) async {
    // Fetch account (displayName, avatarUrl) and creator-profile (bio) in
    // parallel. The creator-profile endpoint may 404 for brand-new accounts
    // so we swallow failures and fall back to an empty map.
    final results = await Future.wait([
      apiClient.get('/v1/accounts/$accountId'),
      apiClient
          .get('/v1/accounts/$accountId/creator-profile')
          .then<Map<String, dynamic>>((r) => r as Map<String, dynamic>)
          .catchError((_) => <String, dynamic>{}),
    ]);

    final accountJson = results[0] as Map<String, dynamic>;
    final cpJson = results[1] as Map<String, dynamic>;

    final bio = cpJson['bio'] as String? ?? '';
    // Tags may live on either the account or the creator-profile document;
    // prefer the account response when both are present.
    List<String>? tags;
    final acctTags = accountJson['tags'] as List<dynamic>?;
    if (acctTags != null) {
      tags = acctTags.map((t) => t.toString()).toList(growable: false);
    } else {
      final cpTags = cpJson['tags'] as List<dynamic>?;
      if (cpTags != null) {
        tags = cpTags.map((t) => t.toString()).toList(growable: false);
      }
    }
    return CreatorProfileDto.fromJson({
      ...accountJson,
      if (bio.isNotEmpty) 'bio': bio,
      if (tags != null) 'tags': tags,
    });
  }

  Future<CreatorProfileDto> updateCreatorProfile({
    required String accountId,
    required String rowVersion,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? tags,
    List<String>? niches,
  }) async {
    // Account-level fields.
    final accountData = <String, dynamic>{
      'rowVersion': rowVersion,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };

    // Creator-level fields (bio, tags) go to the creator-profile endpoint.
    final creatorProfileData = <String, dynamic>{};
    if (bio != null) creatorProfileData['bio'] = bio;
    if (tags != null) creatorProfileData['tags'] = tags;

    if (creatorProfileData.isNotEmpty) {
      // Both calls run in parallel.
      final results = await Future.wait([
        apiClient.patch('/v1/accounts/$accountId', data: accountData),
        apiClient.patch(
          '/v1/accounts/$accountId/creator-profile',
          data: creatorProfileData,
        ),
      ]);
      return CreatorProfileDto.fromJson({
        ...(results[0] as Map<String, dynamic>),
        ...(results[1] as Map<String, dynamic>),
      });
    }

    final response =
        await apiClient.patch('/v1/accounts/$accountId', data: accountData);
    return CreatorProfileDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET /v1/badges/me
  Future<List<BadgeAwardDto>> listMyBadges() async {
    final response = await apiClient.get('/v1/badges/me');
    final list = response as List<dynamic>? ?? const [];
    return list
        .map((e) => BadgeAwardDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// PUT /v1/badges/me/showcase
  Future<List<BadgeAwardDto>> updateBadgeShowcase(
      List<String> awardIdsInOrder) async {
    final response = await apiClient.put(
      '/v1/badges/me/showcase',
      data: {'awardIdsInOrder': awardIdsInOrder},
    );
    final list = response as List<dynamic>? ?? const [];
    return list
        .map((e) => BadgeAwardDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET /v1/accounts/{accountId}/creator-specializations
  /// Returns the category IDs (GUIDs) of all active specializations.
  Future<List<String>> listSpecializationCategoryIds(String accountId) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/creator-specializations',
    );
    final list = response as List<dynamic>? ?? const [];
    return list
        .map((e) => (e as Map<String, dynamic>)['categoryId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  /// POST /v1/accounts/{accountId}/creator-specializations
  Future<void> addSpecialization(String accountId, String categoryId) async {
    await apiClient.post(
      '/v1/accounts/$accountId/creator-specializations',
      data: {'categoryId': categoryId, 'isPrimary': false},
    );
  }

  /// DELETE /v1/accounts/{accountId}/creator-specializations/{categoryId}
  Future<void> removeSpecialization(
      String accountId, String categoryId) async {
    await apiClient.authDelete(
      '/v1/accounts/$accountId/creator-specializations/$categoryId',
    );
  }

  /// GET /v1/accounts/{accountId}/creator-specializations
  /// Returns {categoryId → isPrimary} for all active specializations.
  Future<Map<String, bool>> listSpecializationsWithPrimary(
      String accountId) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/creator-specializations',
    );
    final list = response as List<dynamic>? ?? const [];
    final result = <String, bool>{};
    for (final e in list) {
      final map = e as Map<String, dynamic>;
      final id = map['categoryId'] as String? ?? '';
      if (id.isNotEmpty) {
        result[id] = map['isPrimary'] as bool? ?? false;
      }
    }
    return result;
  }

  /// POST /v1/accounts/{accountId}/creator-specializations/{categoryId}/primary
  Future<void> setPrimarySpecialization(
      String accountId, String categoryId) async {
    await apiClient.post(
      '/v1/accounts/$accountId/creator-specializations/$categoryId/primary',
    );
  }
}
