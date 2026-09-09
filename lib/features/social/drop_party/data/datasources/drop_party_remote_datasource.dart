import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/data/models/drop_party_dto.dart';

class DropPartyRemoteDataSource {
  DropPartyRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<DropPartyDto>> getActiveDropParties() async {
    final response = await apiClient.get('/v1/drop-parties');
    final items = (response as List<dynamic>?)
        ?.map((e) => DropPartyDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items ?? const [];
  }

  Future<DropPartyDto> getDropParty(String partyId) async {
    final response = await apiClient.get('/v1/drop-parties/$partyId');
    return DropPartyDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> rsvp(
    String partyId,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/drop-parties/$partyId/rsvp',
      options: _idempotent(idempotencyKey),
    );
  }

  Future<void> joinLive(String partyId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/drop-parties/$partyId/join-live',
      options: _idempotent(idempotencyKey),
    );
  }

  /// Invite is client-side only now (native share sheet of the invite
  /// code) — there's no per-recipient invite concept on the backend, same
  /// as CoWatch. "Scan" resolves the code and joins in one step.
  Future<DropPartyDto> scanInviteQr(
    String qrCode,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/drop-parties/join-by-code',
      data: {'joinCode': qrCode},
      options: _idempotent(idempotencyKey),
    );
    return DropPartyDto.fromJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
