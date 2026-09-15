import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/data/models/code_dto.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/data/models/code_stats_dto.dart';

/// One page of `GET /v1/vendor/codes`.
typedef VendorCodesPage = ({List<CodeDto> codes, String? nextCursor});

/// Codes module `v1/vendor/codes`: the vendor's product and store codes.
class VendorCodesRemoteDataSource {
  VendorCodesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/vendor/codes';

  /// `POST /v1/vendor/codes` with `CreateVendorCodeVm { kind, productId?,
  /// storeId, label? }`. Get-or-create: an existing active code comes back.
  Future<CodeDto> createCode({
    required CodeKind kind,
    required String storeId,
    required String idempotencyKey,
    String? productId,
    String? label,
  }) async {
    final response = await apiClient.post(
      _base,
      data: <String, dynamic>{
        'kind': kind.wireName,
        'productId': ?productId,
        'storeId': storeId,
        'label': ?label,
      },
      options: _mutationOptions(idempotencyKey),
    );
    return CodeDto.fromJson(readJsonObject(response));
  }

  /// `GET /v1/vendor/codes?storeId=&productId=&kind=&cursor=&pageSize=`.
  Future<VendorCodesPage> listCodes({
    String? storeId,
    String? productId,
    CodeKind? kind,
    String? cursor,
    int pageSize = 50,
  }) async {
    final response = await apiClient.get(
      _base,
      queryParameters: <String, dynamic>{
        'storeId': ?storeId,
        'productId': ?productId,
        'kind': ?kind?.wireName,
        'cursor': ?cursor,
        'pageSize': pageSize,
      },
    );
    return (
      codes: CodeDto.listFromPage(response),
      nextCursor: readNextCursor(response),
    );
  }

  /// `POST /v1/vendor/codes/{code}/revoke`.
  Future<CodeDto> revoke({
    required String code,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '$_base/${Uri.encodeComponent(code)}/revoke',
      options: _mutationOptions(idempotencyKey),
    );
    return CodeDto.fromJson(readJsonObject(response));
  }

  /// `GET /v1/vendor/codes/{code}/stats`.
  Future<CodeStatsDto> getStats(String code) async {
    final response = await apiClient.get(
      '$_base/${Uri.encodeComponent(code)}/stats',
    );
    return CodeStatsDto.fromJson(readJsonObject(response));
  }

  static Options _mutationOptions(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
