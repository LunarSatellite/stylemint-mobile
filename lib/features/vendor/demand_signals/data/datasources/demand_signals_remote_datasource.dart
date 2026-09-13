import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/data/models/demand_signals_dto.dart';

class DemandSignalsRemoteDataSource {
  DemandSignalsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /api/v1/vendor/demand-signals?days=&limit=` (Discovery module
  /// `DemandSignalsController`). Discovery routes carry the `api/` prefix,
  /// unlike the Orders/Vendor `/v1/...` routes.
  Future<DemandSignalsDto> getDemandSignals({
    required int days,
    required int limit,
  }) async {
    final response = await apiClient.get(
      '/api/v1/vendor/demand-signals',
      queryParameters: {'days': days, 'limit': limit},
    );
    return DemandSignalsDto.fromJson(response as Map<String, dynamic>);
  }
}
