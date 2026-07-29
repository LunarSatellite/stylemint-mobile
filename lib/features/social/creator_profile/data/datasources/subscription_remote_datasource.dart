import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/account_subscription_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/subscription_plan_dto.dart';

/// Remote data source for the Identity module subscription endpoints:
///   - GET    /v1/subscriptions/plans
///   - GET    /v1/subscriptions/me
///   - POST   /v1/subscriptions/me/upgrade
///   - POST   /v1/subscriptions/me/cancel
class SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/subscriptions/plans — returns the active plans across all
  /// tier × cadence combinations. Public endpoint (no token required).
  Future<List<SubscriptionPlanDto>> listPlans() async {
    final response = await apiClient.authGet('/v1/subscriptions/plans');
    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map(SubscriptionPlanDto.fromJson).toList(growable: false);
  }

  /// GET /v1/subscriptions/me — current subscription or null.
  Future<AccountSubscriptionDto?> getMine() async {
    final response = await apiClient.get('/v1/subscriptions/me');
    if (response == null) return null;
    return AccountSubscriptionDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/subscriptions/me/upgrade — switches to [planId]. The previous
  /// active subscription (if any) is cancelled server-side.
  Future<AccountSubscriptionDto> upgrade({required String planId}) async {
    final response = await apiClient.post(
      '/v1/subscriptions/me/upgrade',
      data: {'planId': planId},
    );
    return AccountSubscriptionDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/subscriptions/me/cancel — cancels the active subscription.
  Future<AccountSubscriptionDto> cancel() async {
    final response = await apiClient.post('/v1/subscriptions/me/cancel');
    return AccountSubscriptionDto.fromJson(response as Map<String, dynamic>);
  }
}
