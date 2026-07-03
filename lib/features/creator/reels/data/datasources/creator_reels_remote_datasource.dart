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
}
