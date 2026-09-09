import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/profile_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/models/user_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/creator_social_links.dart';
import 'package:uuid/uuid.dart';

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
      if (dateOfBirth != null)
        'dateOfBirth': dateOfBirth.toIso8601String().substring(0, 10),
    };
    final response = await apiClient.patch(
      '/v1/accounts/$accountId',
      data: data,
    );
    return UserProfileDto.fromJson(response as Map<String, dynamic>);
  }

  /// Stages an avatar image with Identity, then persists its URL through the
  /// existing row-versioned account profile patch.
  Future<UserProfileDto> uploadAvatar({
    required String filePath,
    required String rowVersion,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final upload = await apiClient.post(
      '/v1/customer/me/avatar',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      }),
      options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
    );
    final avatarUrl = (upload as Map<String, dynamic>)['url'] as String?;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.unexpectedError();
    }
    return updateProfile(avatarUrl: avatarUrl, rowVersion: rowVersion);
  }

  Future<CreatorSocialLinks> getCreatorSocialLinks() async {
    final accountId = await _accountId();
    final response = await apiClient.get(
      '/v1/accounts/$accountId/creator-profile',
    );
    final data = response as Map<String, dynamic>;
    return CreatorSocialLinks(
      instagramHandle: data['instagramHandle'] as String?,
      tiktokHandle: data['tiktokHandle'] as String?,
    );
  }

  Future<void> updateCreatorSocialLinks({
    required String instagramHandle,
    required String tiktokHandle,
  }) async {
    final accountId = await _accountId();
    await apiClient.patch(
      '/v1/accounts/$accountId/creator-profile',
      data: {
        'instagramHandle': instagramHandle,
        'tiktokHandle': tiktokHandle,
      },
      options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
    );
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

  /// Submits a GDPR Article 20 export request. The archive itself is produced
  /// asynchronously and delivered through the secure fulfilment flow.
  Future<void> requestDataExport() async {
    final accountId = await _accountId();
    await apiClient.post(
      '/v1/accounts/$accountId/data-rights-requests',
      data: const {
        // DataRightsRequestType.Portability (GDPR Article 20): the
        // machine-readable archive behind the "Download My Data" control.
        'requestType': 5,
        'description': 'Request a copy of my personal data.',
      },
      options: Options(headers: {'Idempotency-Key': const Uuid().v4()}),
    );
  }

  /// The account endpoint (`getProfileSummary`) doesn't carry the saved /
  /// following / orders counts — each is sourced from its own already-real
  /// endpoint instead of a dedicated (nonexistent) stats endpoint. Each
  /// sub-fetch fails independently to 0 rather than failing the whole
  /// profile load over one flaky count.
  Future<({int savedItemsCount, int followingCount, int ordersCount})>
  getStatsCounts() async {
    final results = await Future.wait([
      apiClient
          .get('/v1/cart/saved-for-later')
          .then((r) => (r as List<dynamic>).length)
          .catchError((_) => 0),
      // NOT /v1/connections — that's Networking's mutual friendships, a
      // different feature from one-way creator follows (see skill: "Following
      // is one-way (social-graph). Friendship is mutual (networking). Never
      // conflate."). The follow/unfollow actions post to /v1/follows, so the
      // count has to come from the same module's stats endpoint.
      _accountId().then(
        (accountId) => apiClient
            .get('/v1/follows/$accountId/stats')
            .then((r) => (r as Map<String, dynamic>)['following'] as int? ?? 0)
            .catchError((_) => 0),
      ),
      apiClient
          .get('/v1/orders', queryParameters: {'pageSize': 1})
          .then(
            (r) => ((r as Map<String, dynamic>)['totalCount'] as int? ?? 0)
                .clamp(0, 1 << 31),
          )
          .catchError((_) => 0),
    ]);
    return (
      savedItemsCount: results[0],
      followingCount: results[1],
      ordersCount: results[2],
    );
  }
}
