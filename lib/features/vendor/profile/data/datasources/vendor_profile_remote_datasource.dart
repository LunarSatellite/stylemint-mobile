import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/profile/data/models/vendor_profile_dto.dart';

class VendorProfileRemoteDataSource {
  VendorProfileRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// The backend enforces that [accountId] matches the authenticated caller.
  Future<VendorProfileDto> getMyProfile(String accountId) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/vendor-profile',
    );
    return VendorProfileDto.fromJson(response as Map<String, dynamic>);
  }
}
