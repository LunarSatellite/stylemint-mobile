import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/data/models/vendor_dashboard_dto.dart';

class VendorDashboardRemoteDataSource {
  VendorDashboardRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<VendorDashboardDto> getDashboard() async {
    final response = await apiClient.get('/v1/vendor/dashboard');
    return VendorDashboardDto.fromJson(response as Map<String, dynamic>);
  }
}
