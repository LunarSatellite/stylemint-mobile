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

  /// `GET /v1/vendor/briefs/{id}`.
  Future<CampaignBriefDto> getCampaign(String id) async {
    final response = await apiClient.get('/v1/vendor/briefs/$id');
    return CampaignBriefDto.fromJson(response as Map<String, dynamic>);
  }

  /// `POST /v1/vendor/briefs/{id}/lock` — makes the brief immutable so it
  /// can be attached to partnership invites. Edit via [forkCampaign] instead.
  Future<CampaignBriefDto> lockCampaign(String id, String idempotencyKey) =>
      _briefAction(id, 'lock', idempotencyKey);

  /// `POST /v1/vendor/briefs/{id}/fork` — clones the brief (locked included)
  /// into a new Draft with `version + 1`.
  Future<CampaignBriefDto> forkCampaign(String id, String idempotencyKey) =>
      _briefAction(id, 'fork', idempotencyKey);

  /// `POST /v1/vendor/briefs/{id}/retire` — soft-archive; idempotent.
  Future<CampaignBriefDto> retireCampaign(String id, String idempotencyKey) =>
      _briefAction(id, 'retire', idempotencyKey);

  Future<CampaignBriefDto> _briefAction(
    String id,
    String action,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/briefs/$id/$action',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return CampaignBriefDto.fromJson(response as Map<String, dynamic>);
  }

  /// `POST /v1/vendor/briefs/{id}/recompute-roi` — returns just the
  /// refreshed projection, not the full brief.
  Future<RoiProjectionSummaryDto> recomputeRoi(
    String id,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/briefs/$id/recompute-roi',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return RoiProjectionSummaryDto.fromJson(response as Map<String, dynamic>);
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

  /// Resolves a creator `Account.Id` (returned by the picker) to the
  /// corresponding `CreatorProfile.Id` (expected by
  /// `POST /v1/vendor/partnerships/invite`).
  ///
  /// Background: `CreatorPickerDto.CreatorAccountId` is the account id,
  /// but `InviteCreatorVm.CreatorProfileId` is the creator-profile id
  /// stored on the partnership aggregate. Sending the account id there
  /// stores it in `Partnership.CreatorProfileId`, which then breaks the
  /// chat-by-profile lookup (see `accountByProfileProvider`). This is
  /// the bridge call that keeps the two surfaces in sync.
  ///
  /// `GET /v1/accounts/{accountId}/creator-profile` returns 404 if the
  /// account has no creator profile; callers should treat that as a
  /// hard failure for the invite flow (a creator must have a profile to
  /// be invited).
  Future<String> getCreatorProfileIdByAccountId(String accountId) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/creator-profile',
    );
    final map = response as Map<String, dynamic>;
    final id = (map['id'] as String?) ?? '';
    if (id.isEmpty) {
      throw StateError(
        'Account $accountId has no creator profile (empty id in response).',
      );
    }
    return id;
  }

  /// `POST /v1/vendor/partnerships/invite`. The backend requires a
  /// commission range per invite — there is no campaign-scoped invite
  /// endpoint.
  ///
  /// [creatorProfileId] MUST be the creator's profile id (not the
  /// account id returned by the picker). Use
  /// [getCreatorProfileIdByAccountId] to convert Account.Id to
  /// CreatorProfile.Id before calling this method.
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

  /// `GET /v1/vendor/partnerships` scoped to pending creator-initiated
  /// requests (`states=1` i.e. Invited, `initiatedByCreator=true`,
  /// `pageSize=1`) — used for the dashboard tile count.
  Future<int> getPendingCreatorRequestCount() async {
    final response = await apiClient.get(
      '/v1/vendor/partnerships',
      queryParameters: {
        'states': '1',
        'initiatedByCreator': true,
        'pageSize': 1,
      },
    );
    return (response as Map<String, dynamic>)['totalCount'] as int? ?? 0;
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
