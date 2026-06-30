import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/profile_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/user_profile_dto.dart';

class ProfileRemoteDataSource {
  ProfileRemoteDataSource({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<String> _accountId() async {
    final id = await tokenStorage.accountId;
    if (id == null || id.isEmpty) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.auth();
    }
    return id;
  }

  Future<ProfileSummaryDto> getProfileSummary() async {
    final accountId = await _accountId();
    final response = await apiClient.get('/v1/accounts/$accountId');
    return ProfileSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfileDto> getFullProfile() async {
    final accountId = await _accountId();
    final response = await apiClient.get('/v1/accounts/$accountId');
    return UserProfileDto.fromJson(response as Map<String, dynamic>);
  }

  Future<UserProfileDto> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    required String rowVersion,
  }) async {
    final accountId = await _accountId();
    final data = <String, dynamic>{
      'rowVersion': rowVersion,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String().substring(0, 10),
    };
    final response = await apiClient.patch('/v1/accounts/$accountId', data: data);
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
