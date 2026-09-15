import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/data/models/catalog_dto.dart';

/// Catalog's public listing and collection endpoints. Throws on failure; the
/// repository maps errors.
class MallCatalogRemoteDataSource {
  MallCatalogRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `v1/public/products` — [query] holds the listing filters.
  Future<CatalogProductPageDto> getProducts(
    Map<String, String> query, {
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/products',
      queryParameters: {
        ...query,
        'cursor': ?cursor,
        'pageSize': pageSize,
      },
    );
    return CatalogProductPageDto.fromJson(readJsonObject(response));
  }

  /// GET `v1/public/collections/{slug}` — header plus one page of items.
  Future<CollectionDetailDto> getCollection(
    String slug, {
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/collections/${Uri.encodeComponent(slug)}',
      queryParameters: {'cursor': ?cursor, 'pageSize': pageSize},
    );
    return CollectionDetailDto.fromJson(readJsonObject(response));
  }
}
