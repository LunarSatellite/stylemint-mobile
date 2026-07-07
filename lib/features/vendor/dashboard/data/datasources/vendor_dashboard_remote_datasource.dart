import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/data/models/vendor_dashboard_dto.dart';

class VendorDashboardRemoteDataSource {
  VendorDashboardRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `/v1/vendor/dashboard` is a different endpoint (Brand Studio snapshot).
  /// The vendor home dashboard is served by the analytics overview endpoint.
  Future<VendorAnalyticsOverviewDto> getDashboard() async {
    final response = await apiClient.get('/v1/vendor/analytics/overview');
    return VendorAnalyticsOverviewDto.fromJson(
      response as Map<String, dynamic>,
    );
  }
}
