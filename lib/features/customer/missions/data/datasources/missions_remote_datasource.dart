import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';

/// `/v1/customer/mission-shopping` — all `[Authorize]`, scoped server-side to
/// the JWT subject. Every mutation returns the whole mission.
class MissionsRemoteDataSource {
  MissionsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const String base = '/v1/customer/mission-shopping';

  Future<Map<String, dynamic>> start({
    required String missionText,
    required int maxItems,
    required String idempotencyKey,
    double? budgetAmount,
  }) async {
    final response = await apiClient.post(
      '$base/missions',
      data: {
        'missionText': missionText,
        'budgetAmount': budgetAmount,
        'maxItems': maxItems,
      },
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> list({
    MissionState? state,
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '$base/missions',
      queryParameters: {
        'pageSize': pageSize,
        if (state != null) 'state': state.wire,
        'cursor': ?cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String missionId) async {
    final response = await apiClient.get('$base/missions/${_seg(missionId)}');
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> replan(
    String missionId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '$base/missions/${_seg(missionId)}/replan',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> setItemState({
    required String missionId,
    required String itemId,
    required MissionItemState state,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.patch(
      '$base/missions/${_seg(missionId)}/items/${_seg(itemId)}',
      data: {'state': state.wire},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> complete(
    String missionId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '$base/missions/${_seg(missionId)}/complete',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> abandon(
    String missionId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '$base/missions/${_seg(missionId)}/abandon',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  static String _seg(String value) => Uri.encodeComponent(value);

  Options _idempotent(String idempotencyKey) => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
  );
}
