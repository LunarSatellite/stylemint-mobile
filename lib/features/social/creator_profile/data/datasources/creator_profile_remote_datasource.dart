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
    return CreatorProfileDto.fromJson({
      ...accountJson,
      if (bio.isNotEmpty) 'bio': bio,
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
    // Account-level fields (bio is NOT accepted here — send it to creator-profile).
    final accountData = <String, dynamic>{
      'rowVersion': rowVersion,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (tags != null) 'tags': tags,
    };

    if (bio != null) {
      // Both calls run in parallel; bio goes to the creator-profile endpoint.
      final results = await Future.wait([
        apiClient.patch('/v1/accounts/$accountId', data: accountData),
        apiClient.patch(
          '/v1/accounts/$accountId/creator-profile',
          data: {'bio': bio},
        ),
      ]);
      return CreatorProfileDto.fromJson({
        ...(results[0] as Map<String, dynamic>),
        'bio': bio,
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
}
