import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/datasources/execution_plans_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/notifiers/execution_plans_notifier.dart';

export 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/notifiers/execution_plans_notifier.dart';

/// `v1/commerce-execution-plans`, minus the evidence route — see
/// [ExecutionPlansDataSource].
final executionPlansDataSourceProvider = Provider<ExecutionPlansDataSource>(
  (ref) =>
      ExecutionPlansRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// The shopper's compiled plans.
///
/// Not `autoDispose`: the list screen and a plan's own screen are two views
/// of the same list, and bouncing between them should not re-read the
/// endpoint each time.
final executionPlansNotifierProvider =
    StateNotifierProvider<ExecutionPlansNotifier, ExecutionPlansState>(
      (ref) => ExecutionPlansNotifier(
        dataSource: ref.watch(executionPlansDataSourceProvider),
      ),
    );

/// One plan read on its own, from `GET /v1/commerce-execution-plans/{id}`.
///
/// The plan screen normally reads from the cached list above. This is its
/// fallback for when the list does not hold the plan — the list read failed,
/// or the plan was opened before the list loaded — so a flaky list read is
/// not reported to the shopper as "this plan is not on your account".
///
/// Resolves to null only when the backend itself says there is no such plan
/// for this account. Any other failure stays an error, so the screen offers a
/// retry rather than claiming the plan is gone.
// ignore: specify_nonobvious_property_types — Riverpod's own inferred type.
final executionPlanByIdProvider = FutureProvider.autoDispose
    .family<CommerceExecutionPlan?, String>((ref, planId) async {
      try {
        return await ref.watch(executionPlansDataSourceProvider).get(planId);
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 404 || status == 403) return null;
        rethrow;
      }
    });
