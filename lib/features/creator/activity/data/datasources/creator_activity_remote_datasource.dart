import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/activity/data/models/creator_activity_entry_dto.dart';

class CreatorActivityRemoteDataSource {
  CreatorActivityRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorActivityPageDto> getActivity({
    int pageSize = 25,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/activity',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return CreatorActivityPageDto.fromJson(response as Map<String, dynamic>);
  }
}
