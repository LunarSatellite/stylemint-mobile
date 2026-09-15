import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/resolved_code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';

/// Codes module: public resolve and the caller's own Profile code.
class CodesRemoteDataSource {
  CodesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `POST /v1/public/codes/{code}/resolve` with `{ via }`. Anonymous is
  /// allowed; a signed-in caller's token still goes along so the scan knows
  /// who scanned. 404 when the code is unknown or revoked.
  Future<ResolvedCodeDto> resolve({
    required String code,
    required CodeScanVia via,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/public/codes/${Uri.encodeComponent(code)}/resolve',
      data: <String, dynamic>{'via': via.wireName},
      options: _mutationOptions(idempotencyKey),
    );
    return ResolvedCodeDto.fromJson(readJsonObject(response));
  }

  /// `POST /v1/me/profile-code` — get-or-create the active Profile code.
  Future<CodeDto> getMyProfileCode({required String idempotencyKey}) async {
    final response = await apiClient.post(
      '/v1/me/profile-code',
      options: _mutationOptions(idempotencyKey),
    );
    return CodeDto.fromJson(readJsonObject(response));
  }

  /// `POST /v1/me/profile-code/rotate` — revokes the old code, issues a new
  /// one.
  Future<CodeDto> rotateMyProfileCode({required String idempotencyKey}) async {
    final response = await apiClient.post(
      '/v1/me/profile-code/rotate',
      options: _mutationOptions(idempotencyKey),
    );
    return CodeDto.fromJson(readJsonObject(response));
  }

  static Options _mutationOptions(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
