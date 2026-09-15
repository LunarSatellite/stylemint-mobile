import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/data/models/storefront_json.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/models/creator_reel_stats_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/models/creator_shop_product_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/data/models/public_creator_profile_dto.dart';

/// Anonymous creator storefront reads. Throws on failure; the repository
/// maps errors.
class CreatorStorefrontRemoteDataSource {
  CreatorStorefrontRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  String _base(String accountId) =>
      '/v1/public/creators/${Uri.encodeComponent(accountId)}';

  /// GET `v1/public/creators/{accountId}`.
  Future<PublicCreatorProfileDto> getProfile(String accountId) async {
    final response = await apiClient.get(_base(accountId));
    return PublicCreatorProfileDto.fromJson(readJsonObject(response));
  }

  /// GET `v1/public/creators/{accountId}/reel-stats`.
  Future<CreatorReelStatsDto> getReelStats(String accountId) async {
    final response = await apiClient.get('${_base(accountId)}/reel-stats');
    return CreatorReelStatsDto.fromJson(readJsonObject(response));
  }

  /// GET `v1/public/creators/{accountId}/shop`.
  Future<StorefrontPageDto<CreatorShopProductDto>> getShop(
    String accountId, {
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '${_base(accountId)}/shop',
      queryParameters: {'cursor': ?cursor, 'pageSize': pageSize},
    );
    return StorefrontPageDto.fromJson(
      readJsonObject(response),
      CreatorShopProductDto.fromJson,
    );
  }
}
