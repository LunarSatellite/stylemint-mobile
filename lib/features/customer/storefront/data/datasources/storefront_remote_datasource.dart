import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_collection_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_reel_dto.dart';

/// Anonymous storefront reads. A signed-in caller's token is still sent so
/// viewer fields (`isSavedByMe`) are filled. Throws on failure; the
/// repository maps errors.
class StorefrontRemoteDataSource {
  StorefrontRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `v1/public/creators/{accountId}/reels`.
  Future<StorefrontPageDto<StorefrontReelDto>> getCreatorReels(
    String creatorAccountId, {
    required String sort,
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/creators/${Uri.encodeComponent(creatorAccountId)}/reels',
      queryParameters: {'sort': sort, 'cursor': ?cursor, 'pageSize': pageSize},
    );
    return StorefrontPageDto.fromJson(
      readJsonObject(response),
      StorefrontReelDto.fromJson,
    );
  }

  /// GET `v1/public/vendors/{vendorAccountId}/reels`.
  Future<StorefrontPageDto<StorefrontReelDto>> getVendorReels(
    String vendorAccountId, {
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/vendors/${Uri.encodeComponent(vendorAccountId)}/reels',
      queryParameters: {'cursor': ?cursor, 'pageSize': pageSize},
    );
    return StorefrontPageDto.fromJson(
      readJsonObject(response),
      StorefrontReelDto.fromJson,
    );
  }

  /// GET `v1/public/collections` for one owner and kind.
  Future<StorefrontPageDto<StorefrontCollectionDto>> getCollections({
    required int ownerKind,
    required String ownerAccountId,
    required int kind,
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/collections',
      queryParameters: {
        'kind': kind,
        'ownerKind': ownerKind,
        'ownerAccountId': ownerAccountId,
        'cursor': ?cursor,
        'pageSize': pageSize,
      },
    );
    return StorefrontPageDto.fromJson(
      readJsonObject(response),
      StorefrontCollectionDto.fromJson,
    );
  }
}
