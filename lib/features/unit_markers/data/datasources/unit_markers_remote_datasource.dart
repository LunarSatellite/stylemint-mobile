import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/data/models/unit_marker_dtos.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';

/// The nine per-unit routes.
///
/// **Where the marker secret goes.** On `scan`, `bind` and `correct` the
/// cleartext marker is a request **body** field. It is never a path segment
/// and never a query parameter — a credential in a URL is written to the
/// client's own request log, the gateway's access log and the server's, and
/// none of those are places a 130-bit tag secret may live. The routes that
/// name a specific tag in their path use the non-secret `UMxxxxxxxxxx`
/// reference instead.
class UnitMarkersRemoteDataSource {
  UnitMarkersRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // ── Seller: provisioning ───────────────────────────────────────────────

  /// `POST /v1/vendor/unit-markers` — mints a print run and returns the
  /// cleartext secrets **once**.
  ///
  /// The response is not logged and not cached anywhere; it is mapped and
  /// handed to the caller.
  Future<List<ProvisionedUnitMarkerDto>> provision({
    required String productVariantId,
    required int quantity,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/unit-markers',
      data: <String, dynamic>{
        'productVariantId': productVariantId,
        'quantity': quantity,
      },
      options: _mutationOptions(idempotencyKey),
    );
    return _objects(
      response,
    ).map(ProvisionedUnitMarkerDto.fromJson).toList(growable: false);
  }

  /// `GET /v1/vendor/unit-markers` — cursor-paged, never carries a secret.
  Future<({List<UnitMarkerDto> items, String? nextCursor, int totalCount})>
  listMarkers({
    String? productId,
    String? productVariantId,
    String? cursor,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/unit-markers',
      queryParameters: <String, dynamic>{
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        if (productVariantId != null && productVariantId.isNotEmpty)
          'productVariantId': productVariantId,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'pageSize': pageSize,
      },
      options: Options(headers: <String, dynamic>{'requiresToken': true}),
    );
    final body = readJsonObject(response);
    return (
      items: readPagedItems(
        body,
      ).map(UnitMarkerDto.fromJson).toList(growable: false),
      nextCursor: readNextCursor(body),
      totalCount: readInt(body['totalCount']),
    );
  }

  /// `POST /v1/vendor/unit-markers/{reference}/revoke` — by the **reference**,
  /// because the case that matters is a tag whose secret nobody holds any
  /// more.
  Future<UnitMarkerDto> revoke({
    required String reference,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/unit-markers/${Uri.encodeComponent(reference)}/revoke',
      options: _mutationOptions(idempotencyKey),
    );
    return UnitMarkerDto.fromJson(readJsonObject(response));
  }

  // ── Packer: binding ───────────────────────────────────────────────────

  /// `POST /v1/vendor/unit-markers/bind` — marker in the body.
  Future<UnitMarkerBindingDto> bind({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/unit-markers/bind',
      data: <String, dynamic>{
        'marker': marker,
        'subOrderLineId': subOrderLineId,
        'stage': stage.wire,
      },
      options: _mutationOptions(idempotencyKey),
    );
    return UnitMarkerBindingDto.fromJson(readJsonObject(response));
  }

  /// `POST /v1/vendor/unit-markers/bindings/correct` — marker in the body,
  /// and `reason` is the seller's own words, required by the backend.
  Future<UnitMarkerBindingDto> correct({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
    required String reason,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/unit-markers/bindings/correct',
      data: <String, dynamic>{
        'marker': marker,
        'subOrderLineId': subOrderLineId,
        'stage': stage.wire,
        'reason': reason,
      },
      options: _mutationOptions(idempotencyKey),
    );
    return UnitMarkerBindingDto.fromJson(readJsonObject(response));
  }

  /// `GET /v1/vendor/unit-markers/{reference}/bindings` — by reference, never
  /// by secret.
  Future<List<UnitMarkerBindingDto>> bindingHistory(String reference) async {
    final response = await apiClient.get(
      '/v1/vendor/unit-markers/${Uri.encodeComponent(reference)}/bindings',
      options: Options(headers: <String, dynamic>{'requiresToken': true}),
    );
    return _objects(
      response,
    ).map(UnitMarkerBindingDto.fromJson).toList(growable: false);
  }

  /// `GET /v1/vendor/unit-markers/{reference}/scans` — by reference.
  Future<List<UnitMarkerScanDto>> scanHistory(
    String reference, {
    int limit = 50,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/unit-markers/${Uri.encodeComponent(reference)}/scans',
      queryParameters: <String, dynamic>{'limit': limit},
      options: Options(headers: <String, dynamic>{'requiresToken': true}),
    );
    return _objects(
      response,
    ).map(UnitMarkerScanDto.fromJson).toList(growable: false);
  }

  // ── Public ────────────────────────────────────────────────────────────

  /// `POST /v1/public/unit-markers/scan` — **marker in the body**.
  ///
  /// Anonymous is the normal case; a signed-in caller's token still goes
  /// along so the scan can be attributed. 404 when the platform never issued
  /// this marker.
  Future<UnitMarkerScanResultDto> scan({
    required String marker,
    required CodeScanVia via,
    required String idempotencyKey,
    String? atStoreCode,
  }) async {
    final response = await apiClient.post(
      '/v1/public/unit-markers/scan',
      data: <String, dynamic>{
        'marker': marker,
        'via': via.wireName,
        if (atStoreCode != null && atStoreCode.isNotEmpty)
          'atStoreCode': atStoreCode,
      },
      options: _mutationOptions(idempotencyKey),
    );
    return UnitMarkerScanResultDto.fromJson(readJsonObject(response));
  }

  /// `GET /v1/public/unit-passports/{unitMarkerId}` — the **opaque id** in
  /// the path, which is safe there: it is not a credential, and the endpoint
  /// re-checks the binding, so a guessed id is simply unbound (404).
  Future<Map<String, dynamic>> unitPassport(String unitMarkerId) async {
    final response = await apiClient.get(
      '/v1/public/unit-passports/${Uri.encodeComponent(unitMarkerId)}',
    );
    return readJsonObject(response);
  }

  static List<Map<String, dynamic>> _objects(Object? raw) => raw is List
      ? raw.whereType<Map<String, dynamic>>().toList(growable: false)
      : const [];

  static Options _mutationOptions(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
