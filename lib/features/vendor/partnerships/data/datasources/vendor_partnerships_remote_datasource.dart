import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/data/models/vendor_partnership_dto.dart';

class VendorPartnershipsRemoteDataSource {
  VendorPartnershipsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/vendor/briefs` (Vendor §3 — Brand Studio briefs list).
  Future<List<CampaignBriefDto>> getCampaigns() async {
    final response = await apiClient.get('/v1/vendor/briefs');
    final items =
        ((response as Map<String, dynamic>)['items'] as List<dynamic>? ??
                const <dynamic>[])
            .map((e) => CampaignBriefDto.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
    return items;
  }

  /// `POST /v1/vendor/briefs`.
  Future<CampaignBriefDto> createCampaign({
    required Map<String, dynamic> data,
  }) async {
    final response = await apiClient.post('/v1/vendor/briefs', data: data);
    return CampaignBriefDto.fromJson(response as Map<String, dynamic>);
  }

  /// `PATCH /v1/vendor/briefs/{id}`.
  Future<CampaignBriefDto> updateCampaign({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final response = await apiClient.patch(
      '/v1/vendor/briefs/$id',
      data: data,
    );
    return CampaignBriefDto.fromJson(response as Map<String, dynamic>);
  }

  /// `GET /v1/vendor/partnerships/creators` (Vendor §7J — invite picker).
  /// Real query params are `q` and `niche` (not `/search` + `category`).
  Future<List<CreatorInviteDto>> searchCreators({
    String? query,
    String? niche,
  }) async {
    final params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (niche != null && niche.isNotEmpty) params['niche'] = niche;
    final response = await apiClient.get(
      '/v1/vendor/partnerships/creators',
      queryParameters: params.isEmpty ? null : params,
    );
    final items =
        ((response as Map<String, dynamic>)['items'] as List<dynamic>? ??
                const <dynamic>[])
            .map((e) => CreatorInviteDto.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
    return items;
  }

  /// `POST /v1/vendor/partnerships/invite`. The backend requires a
  /// commission range per invite — there is no campaign-scoped invite
  /// endpoint.
  ///
  /// `message` is NOT part of the documented `InviteCreatorVm` contract
  /// (`additionalProperties: false`) — sent best-effort per product
  /// decision; the backend will most likely silently ignore it rather
  /// than reject the request, but this is unconfirmed.
  Future<void> inviteCreator({
    required String creatorProfileId,
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? brandBriefId,
    String? message,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/vendor/partnerships/invite',
      data: {
        'creatorProfileId': creatorProfileId,
        'commissionMinPercent': commissionMinPercent,
        'commissionMaxPercent': commissionMaxPercent,
        if (brandBriefId != null) 'brandBriefId': brandBriefId,
        // Undocumented — see method doc comment.
        if (message != null && message.isNotEmpty) 'requestMessage': message,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }

  /// `GET /v1/vendor/partnerships`. `states` is a comma-separated list of
  /// the numeric `PartnershipState` values (1-5), matching the query
  /// binding style used elsewhere (e.g. products' `state` filter).
  Future<Map<String, dynamic>> getPartnerships({
    List<int>? states,
    String? cursor,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/partnerships',
      queryParameters: {
        'pageSize': pageSize,
        if (states != null && states.isNotEmpty) 'states': states.join(','),
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<void> acceptRequest(String id, String idempotencyKey) =>
      _action(id, 'accept-request', idempotencyKey);

  Future<void> declineRequest(String id, String idempotencyKey) =>
      _action(id, 'decline-request', idempotencyKey);

  Future<void> resume(String id, String idempotencyKey) =>
      _action(id, 'resume', idempotencyKey);

  Future<void> pause(String id, String idempotencyKey, {String? reason}) =>
      _action(
        id,
        'pause',
        idempotencyKey,
        data: {if (reason != null) 'reason': reason},
      );

  Future<void> end(String id, String idempotencyKey, {String? reason}) =>
      _action(
        id,
        'end',
        idempotencyKey,
        data: {if (reason != null) 'reason': reason},
      );

  Future<void> adjustCommission(
    String id,
    String idempotencyKey, {
    required double commissionMinPercent,
    required double commissionMaxPercent,
    String? reason,
  }) => _action(
    id,
    'adjust-commission',
    idempotencyKey,
    data: {
      'commissionMinPercent': commissionMinPercent,
      'commissionMaxPercent': commissionMaxPercent,
      if (reason != null) 'reason': reason,
    },
  );

  Future<void> _action(
    String id,
    String action,
    String idempotencyKey, {
    Map<String, dynamic>? data,
  }) async {
    await apiClient.post(
      '/v1/vendor/partnerships/$id/$action',
      data: data,
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }
}
