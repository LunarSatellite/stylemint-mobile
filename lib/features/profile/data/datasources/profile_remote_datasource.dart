import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/profile_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/user_profile_dto.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // TODO: accountId must come from auth state — use `/v1/accounts/{accountId}`
  Future<ProfileSummaryDto> getProfileSummary() async {
    final response = await apiClient.get('/v1/accounts/{accountId}');
    return ProfileSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO: accountId must come from auth state — use `/v1/accounts/{accountId}`
  Future<UserProfileDto> getFullProfile() async {
    final response = await apiClient.get('/v1/accounts/{accountId}');
    return UserProfileDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO: accountId must come from auth state — use `PATCH /v1/accounts/{accountId}`
  Future<UserProfileDto> updateProfile({
    String? displayName,
    String? bio,
    String? website,
    String? avatarPath,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    final data = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
      if (avatarPath != null) 'avatarPath': avatarPath,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
    };
    final response = await apiClient.patch('/v1/accounts/{accountId}', data: data);
    return UserProfileDto.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getFollowing({
    String? search,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/connections',
      queryParameters: {
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<void> unfollowUser(String userId) async {
    await apiClient.authDelete('/v1/connections/$userId');
  }
}
