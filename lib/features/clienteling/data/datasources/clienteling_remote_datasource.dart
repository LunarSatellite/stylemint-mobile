import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/models/clienteling_dtos.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';

/// Raw calls against `v1/clienteling/*`.
///
/// Mutations take an explicit `idempotencyKey` so one key belongs to one user
/// tap and survives retries — the Dio interceptor's per-request fallback would
/// mint a fresh key on every retry.
class ClientelingRemoteDataSource {
  ClientelingRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _associate = '/v1/clienteling/associate';
  static const _me = '/v1/clienteling/me';

  Options _idempotent(String key) =>
      Options(headers: {'requiresToken': true, 'Idempotency-Key': key});

  // ─── Associate ────────────────────────────────────────────────────────────

  Future<ClientAssignmentPageDto> listMyClients({
    String? cursor,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '$_associate/clients',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return ClientAssignmentPageDto.fromJson(readJsonObject(response));
  }

  Future<ClientBrief> getBrief(String customerAccountId) async {
    final response = await apiClient.get(
      '$_associate/clients/$customerAccountId/brief',
    );
    return clientBriefFromJson(readJsonObject(response));
  }

  Future<AssistSession> openSession({
    required String customerAccountId,
    required String purpose,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$_associate/sessions',
      data: {'customerAccountId': customerAccountId, 'purpose': purpose},
      options: _idempotent(idempotencyKey),
    );
    return assistSessionFromJson(readJsonObject(response));
  }

  Future<AssistSession> closeSession({
    required String sessionId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$_associate/sessions/$sessionId/close',
      options: _idempotent(idempotencyKey),
    );
    return assistSessionFromJson(readJsonObject(response));
  }

  Future<OutreachAttempt> sendOutreach({
    required String customerAccountId,
    required ClientelingOutreachChannel channel,
    required String subject,
    required String body,
    required String idempotencyKey,
    String? sessionId,
  }) async {
    final response = await apiClient.post(
      '$_associate/outreach',
      data: {
        'customerAccountId': customerAccountId,
        'sessionId': ?sessionId,
        'channel': outreachChannelToJson(channel),
        'subject': subject,
        'body': body,
      },
      options: _idempotent(idempotencyKey),
    );
    return outreachAttemptFromJson(readJsonObject(response));
  }

  Future<AssistedOutcome> claimOutcome({
    required String sessionId,
    required String orderId,
    required String idempotencyKey,
    String? note,
  }) async {
    final response = await apiClient.post(
      '$_associate/outcomes',
      data: {
        'sessionId': sessionId,
        'orderId': orderId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      options: _idempotent(idempotencyKey),
    );
    return assistedOutcomeFromJson(readJsonObject(response));
  }

  Future<List<ClientelingActivity>> listMyActivity({
    String? customerAccountId,
    int limit = 50,
  }) async {
    final response = await apiClient.get(
      '$_associate/activity',
      queryParameters: {
        'limit': limit,
        if (customerAccountId != null && customerAccountId.isNotEmpty)
          'customerAccountId': customerAccountId,
      },
    );
    return clientelingActivityListFromJson(response);
  }

  // ─── Customer ─────────────────────────────────────────────────────────────

  Future<List<ClientelingActivity>> listMyHistory({int limit = 50}) async {
    final response = await apiClient.get(
      '$_me/history',
      queryParameters: {'limit': limit},
    );
    return clientelingActivityListFromJson(response);
  }

  Future<List<AssistedOutcome>> listMyClaims({int limit = 50}) async {
    final response = await apiClient.get(
      '$_me/assisted-outcomes',
      queryParameters: {'limit': limit},
    );
    return assistedOutcomeListFromJson(response);
  }

  Future<AssistedOutcome> confirmOutcome({
    required String outcomeId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$_me/assisted-outcomes/$outcomeId/confirm',
      options: _idempotent(idempotencyKey),
    );
    return assistedOutcomeFromJson(readJsonObject(response));
  }

  Future<AssistedOutcome> rejectOutcome({
    required String outcomeId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$_me/assisted-outcomes/$outcomeId/reject',
      options: _idempotent(idempotencyKey),
    );
    return assistedOutcomeFromJson(readJsonObject(response));
  }
}
