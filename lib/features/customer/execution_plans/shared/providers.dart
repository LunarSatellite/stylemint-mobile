import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/datasources/execution_plans_datasource.dart';
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
