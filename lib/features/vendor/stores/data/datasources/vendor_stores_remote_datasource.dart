import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/data/models/vendor_store_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store_draft.dart';

/// One page of `GET /v1/vendor/stores`.
typedef VendorStoresPage = ({List<VendorStoreDto> stores, String? nextCursor});

/// Codes module `v1/vendor/stores`: the vendor's physical stores.
class VendorStoresRemoteDataSource {
  VendorStoresRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/vendor/stores';

  /// `GET /v1/vendor/stores?cursor=&pageSize=`.
  Future<VendorStoresPage> getStores({
    String? cursor,
    int pageSize = 50,
  }) async {
    final response = await apiClient.get(
      _base,
      queryParameters: <String, dynamic>{
        'pageSize': pageSize,
        'cursor': ?cursor,
      },
    );
    return (
      stores: VendorStoreDto.listFromPage(response),
      nextCursor: readNextCursor(response),
    );
  }

  /// `POST /v1/vendor/stores`.
  Future<VendorStoreDto> createStore({
    required VendorStoreDraft draft,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      _base,
      data: VendorStoreDto.draftToJson(draft),
      options: _mutationOptions(idempotencyKey),
    );
    return VendorStoreDto.fromJson(readJsonObject(response));
  }

  /// `PUT /v1/vendor/stores/{storeId}`.
  Future<VendorStoreDto> updateStore({
    required String storeId,
    required VendorStoreDraft draft,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.put(
      '$_base/${Uri.encodeComponent(storeId)}',
      data: VendorStoreDto.draftToJson(draft),
      options: _mutationOptions(idempotencyKey),
    );
    return VendorStoreDto.fromJson(readJsonObject(response));
  }

  /// `POST /v1/vendor/stores/{storeId}/archive` — 204 No Content.
  Future<void> archiveStore({
    required String storeId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '$_base/${Uri.encodeComponent(storeId)}/archive',
      options: _mutationOptions(idempotencyKey),
    );
  }

  static Options _mutationOptions(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
