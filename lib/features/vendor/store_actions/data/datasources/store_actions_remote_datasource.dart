import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/store_actions/data/models/store_action_queue_dto.dart';

class StoreActionsRemoteDataSource {
  StoreActionsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/vendor/store/actions` (Catalog module `VendorStoreController`,
  /// route `v1/vendor/store`). Catalog vendor routes carry no `api/` prefix,
  /// same as `/v1/vendor/products`.
  Future<StoreActionQueueDto> getStoreActions() async {
    final response = await apiClient.get('/v1/vendor/store/actions');
    return StoreActionQueueDto.fromJson(response as Map<String, dynamic>);
  }
}
