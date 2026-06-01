import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/data/models/imported_reel_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class ReelImportRemoteDataSource {
  ReelImportRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ImportableReelDto>> getImportableReels(String platform) async {
    final response = await apiClient.get(
      '/v1/creator/reels',
      queryParameters: {'platform': platform},
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => ImportableReelDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<ImportedReelDto> importReel({
    required String platformPostId,
    required String caption,
    required List<String> taggedProductIds,
    required String platform,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/reels/import',
      data: {
        'platformPostId': platformPostId,
        'caption': caption,
        'taggedProductIds': taggedProductIds,
        'platform': platform,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ImportedReelDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<TaggedProductForImportDto>> searchProducts(String query) async {
    // TODO(swagger): /v1/creator/reels/search-products not found; re-evaluate product search path
    final response = await apiClient.get(
      '/v1/creator/reels/search-products',
      queryParameters: {'q': query},
    );
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) =>
              TaggedProductForImportDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
    return items;
  }

  Future<Map<String, dynamic>> getImportHistory({
    int limit = 20,
    String? cursor,
  }) async {
    // TODO(swagger): /v1/creator/reels/import-history not found; re-evaluate import history path
    final response = await apiClient.get(
      '/v1/creator/reels/import-history',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }
}
