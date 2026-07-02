import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/data/models/vendor_activity_entry_dto.dart';

class VendorActivityRemoteDataSource {
  VendorActivityRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/vendor/activity` (Vendor §13). `kinds` isn't sent — there's no
  /// published label mapping for `VendorActivityKind` to build a filter UI
  /// against, so this always returns the unfiltered feed.
  Future<VendorActivityPageDto> getActivity({
    int pageSize = 25,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/activity',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return VendorActivityPageDto.fromJson(response as Map<String, dynamic>);
  }
}
