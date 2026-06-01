import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';

/// CRUD for saved payout destinations — `/v1/payout-destinations`.
class PayoutDestinationsRemoteDataSource {
  PayoutDestinationsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PayoutDestinationDto>> list(int role) async {
    final response = await apiClient.get(
      '/v1/payout-destinations',
      queryParameters: {'role': role},
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(PayoutDestinationDto.fromJson)
        .toList(growable: false);
  }

  Future<PayoutDestinationDto> create({
    required int role,
    required int kind,
    required String label,
    required String accountIdentifier,
    String? branchOrIfsc,
    bool makeDefault = false,
  }) async {
    final response = await apiClient.post(
      '/v1/payout-destinations',
      data: {
        'role': role,
        'kind': kind,
        'label': label,
        'accountIdentifier': accountIdentifier,
        if (branchOrIfsc != null && branchOrIfsc.isNotEmpty)
          'branchOrIfsc': branchOrIfsc,
        'makeDefault': makeDefault,
      },
    );
    return PayoutDestinationDto.fromJson(response as Map<String, dynamic>);
  }

  Future<PayoutDestinationDto> setDefault(String id) async {
    final response = await apiClient.post('/v1/payout-destinations/$id/default');
    return PayoutDestinationDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> remove(String id) async {
    await apiClient.authDelete('/v1/payout-destinations/$id');
  }
}
