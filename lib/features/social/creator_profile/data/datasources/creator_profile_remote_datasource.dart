import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/creator_profile_dto.dart';

class CreatorProfileRemoteDataSource {
  CreatorProfileRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorProfileDto> getCreatorProfile(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId');
    return CreatorProfileDto.fromJson(response as Map<String, dynamic>);
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
    final data = <String, dynamic>{
      'rowVersion': rowVersion,
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (tags != null) 'tags': tags,
      if (niches != null) 'niches': niches,
    };
    final response = await apiClient.patch(
      '/v1/accounts/$accountId',
      data: data,
    );
    return CreatorProfileDto.fromJson(response as Map<String, dynamic>);
  }
}
