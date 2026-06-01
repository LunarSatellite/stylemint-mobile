import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/models/partnership_dto.dart';

class PartnershipsRemoteDataSource {
  PartnershipsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PartnershipInviteDto>> getInvites() async {
    final response = await apiClient.get('/v1/partnerships');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) =>
              PartnershipInviteDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
    return items;
  }

  Future<PartnershipInviteDto> acceptInvite(
    String inviteId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/partnerships/$inviteId/accept',
      data: {},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return PartnershipInviteDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> declineInvite(String inviteId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/partnerships/$inviteId/decline',
      data: {},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<List<ActivePartnershipDto>> getActivePartnerships() async {
    // TODO(swagger): /v1/creator/partnerships/active not found; use /v1/partnerships with status filter
    final response = await apiClient.get('/v1/partnerships');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) =>
              ActivePartnershipDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
    return items;
  }
}
