import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/discover_feed_dtos.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/data/models/search_suggestions_dto.dart';

/// Suggestions, collections and feed feedback for the Discover tab. Throws on
/// failure; the repository maps errors.
class DiscoverFeedRemoteDataSource {
  DiscoverFeedRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const String notInterestedPath =
      '/api/v1/customer/feed/not-interested';

  /// GET `api/v1/public/search/suggest`.
  Future<SearchSuggestionsDto> suggest(
    String query, {
    required int limit,
  }) async {
    final response = await apiClient.get(
      '/api/v1/public/search/suggest',
      queryParameters: {'q': query, 'limit': limit},
    );
    return SearchSuggestionsDto.fromJson(readJsonObject(response));
  }

  /// GET `v1/public/collections`.
  Future<DiscoverCollectionPageDto> getCollections({
    required int pageSize,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/collections',
      queryParameters: {'cursor': ?cursor, 'pageSize': pageSize},
    );
    return DiscoverCollectionPageDto.fromJson(readJsonObject(response));
  }

  /// POST `api/v1/customer/feed/not-interested` — 204.
  Future<void> markNotInterested({
    required String targetKind,
    required String targetId,
    String? reason,
  }) async {
    await apiClient.post(
      notInterestedPath,
      data: {
        'targetKind': targetKind,
        'targetId': targetId,
        'reason': ?reason,
      },
    );
  }

  /// DELETE `api/v1/customer/feed/not-interested/{targetKind}/{targetId}`.
  Future<void> undoNotInterested({
    required String targetKind,
    required String targetId,
  }) async {
    await apiClient.authDelete(
      '$notInterestedPath/${Uri.encodeComponent(targetKind)}'
      '/${Uri.encodeComponent(targetId)}',
    );
  }

  /// GET `api/v1/customer/feed/not-interested`.
  Future<NotInterestedListDto> getNotInterested() async {
    final response = await apiClient.get(notInterestedPath);
    return NotInterestedListDto.fromJson(readJsonObject(response));
  }

  /// POST `v1/customer/reels/{reelId}/report` — 204. The Dio client adds the
  /// Idempotency-Key.
  Future<void> reportReel(String reelId, String reasonCode) async {
    await apiClient.post(
      '/v1/customer/reels/${Uri.encodeComponent(reelId)}/report',
      data: {'reasonCode': reasonCode},
    );
  }
}
