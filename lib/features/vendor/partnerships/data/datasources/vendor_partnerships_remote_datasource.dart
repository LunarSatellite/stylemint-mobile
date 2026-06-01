import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/models/vendor_partnership_dto.dart';

class VendorPartnershipsRemoteDataSource {
  VendorPartnershipsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // TODO(swagger): GET /v1/vendor/partnerships/campaigns not found. Use GET /v1/vendor/partnerships for list or GET /v1/vendor/briefs for briefs
  Future<List<CampaignBriefDto>> getCampaigns() async {
    final response = await apiClient.get('/v1/vendor/partnerships/campaigns');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => CampaignBriefDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  // TODO(swagger): POST /v1/vendor/partnerships/campaigns not found. Use POST /v1/vendor/briefs to create a brief or POST /v1/vendor/partnerships/invite to invite
  Future<CampaignBriefDto> createCampaign({
    required Map<String, dynamic> data,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/partnerships/campaigns',
      data: data,
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return CampaignBriefDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): PUT /v1/vendor/partnerships/campaigns/{id} not found. Use PATCH /v1/vendor/briefs/{id}
  Future<CampaignBriefDto> updateCampaign({
    required String id,
    required Map<String, dynamic> data,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.put(
      '/v1/vendor/partnerships/campaigns/$id',
      data: data,
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return CampaignBriefDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): GET /v1/vendor/partnerships/creators/search not found. Use GET /v1/vendor/partnerships/creators
  Future<List<CreatorInviteDto>> searchCreators({
    String? query,
    List<String>? categories,
  }) async {
    final params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (categories != null && categories.isNotEmpty) {
      params['category'] = categories.join(',');
    }
    final response = await apiClient.get(
      '/v1/vendor/partnerships/creators/search',
      queryParameters: params.isEmpty ? null : params,
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => CreatorInviteDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  // TODO(swagger): POST /v1/vendor/partnerships/campaigns/{campaignId}/invite not found. Use POST /v1/vendor/partnerships/invite
  Future<CreatorInviteDto> inviteCreator({
    required String campaignId,
    required String creatorId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/partnerships/campaigns/$campaignId/invite',
      data: {'creatorId': creatorId},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return CreatorInviteDto.fromJson(response as Map<String, dynamic>);
  }

  // TODO(swagger): GET /v1/vendor/partnerships/campaigns/{campaignId}/invites not found in Swagger
  Future<List<CreatorInviteDto>> getInvites(String campaignId) async {
    final response = await apiClient.get(
      '/v1/vendor/partnerships/campaigns/$campaignId/invites',
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => CreatorInviteDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }
}
