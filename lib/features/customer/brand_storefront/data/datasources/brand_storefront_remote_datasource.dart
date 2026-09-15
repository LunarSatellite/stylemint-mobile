import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/data/models/public_brand_profile_dto.dart';

/// Anonymous brand storefront reads. Throws on failure; the repository maps
/// errors.
class BrandStorefrontRemoteDataSource {
  BrandStorefrontRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `v1/public/brands/{vendorAccountId}`.
  Future<PublicBrandProfileDto> getBrand(String vendorAccountId) async {
    final response = await apiClient.get(
      '/v1/public/brands/${Uri.encodeComponent(vendorAccountId)}',
    );
    return PublicBrandProfileDto.fromJson(readJsonObject(response));
  }
}
