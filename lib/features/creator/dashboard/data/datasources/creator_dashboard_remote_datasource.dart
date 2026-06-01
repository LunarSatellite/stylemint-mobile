import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/data/models/creator_dashboard_dto.dart';

class CreatorDashboardRemoteDataSource {
  CreatorDashboardRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<CreatorDashboardDto> getDashboard() async {
    final response = await apiClient.get('/v1/creator/analytics/dashboard');
    return CreatorDashboardDto.fromJson(response as Map<String, dynamic>);
  }
}
