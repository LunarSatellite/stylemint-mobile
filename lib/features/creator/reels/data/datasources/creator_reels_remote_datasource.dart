import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/models/creator_reel_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/models/creator_reel_summary_dto.dart';

class CreatorReelsRemoteDataSource {
  CreatorReelsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorReelDetailDto> getReelDetail(String reelId) async {
    final response = await apiClient.get('/v1/public/reels/$reelId');
    return CreatorReelDetailDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<CreatorReelSummaryDto>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/reels',
      queryParameters: {
        'sortBy': sortBy,
        'order': order,
        'limit': limit,
      },
    );
    final items = (response['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CreatorReelSummaryDto.fromJson)
        .toList(growable: false);
    return items;
  }

  Future<void> publishReel(String reelId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/creator/reels/$reelId/publish',
      data: <String, dynamic>{},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<void> unpublishReel(String reelId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/creator/reels/$reelId/unpublish',
      data: <String, dynamic>{},
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<List<ReelTagManagementDto>> listTaggedProducts(String reelId) async {
    final response = await apiClient.get(
      '/v1/creator/reels/$reelId/tagged-products',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => ReelTagManagementDto.fromJson(e as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<ReelTagManagementDto> tagProduct(
    String reelId, {
    required String productId,
    required double overlayPositionX,
    required double overlayPositionY,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/reels/$reelId/tagged-products',
      data: {
        'productId': productId,
        'overlayPositionX': overlayPositionX,
        'overlayPositionY': overlayPositionY,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ReelTagManagementDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> untagProduct(
    String reelId,
    String taggedProductId,
    String idempotencyKey,
  ) async {
    await apiClient.authDelete(
      '/v1/creator/reels/$reelId/tagged-products/$taggedProductId',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }
}
