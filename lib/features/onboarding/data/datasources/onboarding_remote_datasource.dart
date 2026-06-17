import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

class OnboardingRemoteDatasource {
  const OnboardingRemoteDatasource({required this.apiClient});
  final ApiClient apiClient;

  /// POST /v1/onboarding/customer-interests
  Future<void> saveInterests(List<String> categoryIds) async {
    await apiClient.post(
      '/v1/onboarding/customer-interests',
      data: {'categoryIds': categoryIds},
    );
  }
}
