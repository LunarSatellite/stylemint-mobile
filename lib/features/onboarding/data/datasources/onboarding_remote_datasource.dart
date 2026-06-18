import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/onboarding/data/models/creator_dto.dart';

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

  /// GET /v1/onboarding/creators
  Future<List<CreatorDto>> fetchCreators() async {
    final data = await apiClient.get('/v1/onboarding/creators');
    final list = data as List<dynamic>;
    return list
        .map((e) => CreatorDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /v1/onboarding/follow-creators
  Future<void> followCreators(List<String> creatorIds) async {
    await apiClient.post(
      '/v1/onboarding/follow-creators',
      data: {'creatorIds': creatorIds},
    );
  }
}
