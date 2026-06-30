import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/data/models/creator_performance_dto.dart';

class CreatorPerformanceRemoteDataSource {
  CreatorPerformanceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<CreatorPerformanceDto>> getCreatorPerformance({
    String? sortBy,
    String? window,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/creator-performance',
      queryParameters: <String, dynamic>{
        'sortBy': ?sortBy,
        'window': ?window,
      },
    );
    return (response as List)
        .map((e) => CreatorPerformanceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
