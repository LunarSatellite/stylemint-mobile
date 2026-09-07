import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/datasources/subscription_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/account_subscription_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/models/subscription_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/data/repositories/subscription_repository.dart';

final _subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
  return SubscriptionRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  );
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
    remote: ref.watch(_subscriptionRemoteDataSourceProvider),
  );
});

/// Active subscription plans (Basic / Pro / Enterprise x monthly/yearly).
/// Refresh on demand via `ref.invalidate(subscriptionPlansProvider)`.
final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlanDto>>((ref) async {
  final result = await ref.watch(subscriptionRepositoryProvider).listPlans();
  return result.fold(
    (err) => throw err,
    (plans) => plans,
  );
});

/// The signed-in user's current subscription, or `null` if none. The upgrade
/// screen uses this to preselect the tier the user is already on, instead of
/// defaulting to Pro every time. Returns `null` for both "no subscription"
/// and "request failed" so the screen can fall back to a sensible default
/// rather than blocking on a transient 401/5xx.
final currentSubscriptionProvider =
    FutureProvider<AccountSubscriptionDto?>((ref) async {
  final result = await ref.watch(subscriptionRepositoryProvider).getMine();
  return result.fold(
    (_) => null,
    (sub) => sub,
  );
});