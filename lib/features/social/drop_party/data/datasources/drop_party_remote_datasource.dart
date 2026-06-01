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

  Future<DropPartyDto> createDropParty({
    required String title,
    required String description,
    required String productId,
    required double dropAmount,
    required int maxParticipants,
    required DateTime startsAt,
    required DateTime endsAt,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/drop-parties',
      data: {
        'title': title,
        'description': description,
        'productId': productId,
        'dropAmount': dropAmount,
        'maxParticipants': maxParticipants,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
      },
      options: _idempotent(idempotencyKey),
    );
    return DropPartyDto.fromJson(response as Map<String, dynamic>);
  }

  Future<DropPartyDto> joinDropParty(
    String partyId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/drop-parties/$partyId/join-live',
      options: _idempotent(idempotencyKey),
    );
    return DropPartyDto.fromJson(response as Map<String, dynamic>);
  }

  /// TODO(swagger): No invite endpoint found for drop-parties.
  Future<void> inviteToParty(
    String partyId,
    List<String> userIds,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/drop-parties/$partyId/invite',
      data: {'userIds': userIds},
      options: _idempotent(idempotencyKey),
    );
  }

  /// TODO(swagger): No scan/QR endpoint found for drop-parties.
  Future<DropPartyDto> scanInviteQr(
    String qrCode,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/drop-parties/scan',
      data: {'qrCode': qrCode},
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
