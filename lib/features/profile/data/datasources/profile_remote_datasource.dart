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

  /// The profile feature always operates on the signed-in account. The id is
  /// the source of truth in [TokenStorage] (persisted at login); a null/empty
  /// value means there is no valid session, so we surface it as an auth error
  /// rather than calling the API with the unsubstituted `{accountId}` literal.
  Future<String> _accountId() async {
    final id = await tokenStorage.accountId;
    if (id == null || id.isEmpty) {
      // NetworkExceptions is the app's domain failure type; the repository
      // catches it and folds it into Either.
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
    String? website,
    String? avatarPath,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    final accountId = await _accountId();
    final data = <String, dynamic>{
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (website != null) 'website': website,
      if (avatarPath != null) 'avatarPath': avatarPath,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth.toIso8601String(),
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
