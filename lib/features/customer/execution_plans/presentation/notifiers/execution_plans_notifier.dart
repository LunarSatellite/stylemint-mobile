import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/datasources/execution_plans_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_copy.dart';
import 'package:uuid/uuid.dart';

/// The currency a plan's spending limit is recorded in.
///
/// The backend requires one on every compile, whether or not a limit is set.
/// StyleMint trades in NPR — the same assumption `formatMoney` already makes
/// when it writes "Rs" — so the shopper is not asked to pick one. It is a
/// property of the platform, not a figure about their plan.
const String kExecutionPlanCurrency = 'NPR';

/// The backend accepts 1–20 items per plan.
const int kExecutionPlanMinItems = 1;
const int kExecutionPlanMaxItems = 20;

/// What the compiler is asked for when the shopper does not say.
const int kExecutionPlanDefaultItems = 5;

class ExecutionPlansState {
  const ExecutionPlansState({
    this.plans = const <CommerceExecutionPlan>[],
    this.loading = false,
    this.loaded = false,
    this.loadFailed = false,
    this.compiling = false,
    this.busyPlanId,
    this.failure,
    this.lastCompiledId,
  });

  /// Newest first, exactly as the backend returned them.
  final List<CommerceExecutionPlan> plans;

  final bool loading;

  /// A first read has completed. Distinguishes "nothing yet" from "nothing
  /// at all", so the screen does not flash an empty state.
  final bool loaded;

  final bool loadFailed;

  /// A compile is in flight.
  final bool compiling;

  /// The plan whose approve / cancel call is in flight, if any.
  final String? busyPlanId;

  /// Backend `errorCode` of the last refused action the shopper took, or
  /// [ExecutionPlanCopy.transportFailure]. Only ever set by something they
  /// did — a failed background read sets [loadFailed] instead.
  final String? failure;

  /// The plan the last successful compile produced, so the screen can open
  /// it without guessing which row is new.
  final String? lastCompiledId;

  bool get isBusy => compiling || busyPlanId != null;

  CommerceExecutionPlan? byId(String planId) {
    for (final plan in plans) {
      if (plan.id == planId) return plan;
    }
    return null;
  }

  List<CommerceExecutionPlan> get open =>
      plans.where((plan) => plan.isOpen).toList(growable: false);

  List<CommerceExecutionPlan> get closed =>
      plans.where((plan) => !plan.isOpen).toList(growable: false);

  ExecutionPlansState copyWith({
    List<CommerceExecutionPlan>? plans,
    bool? loading,
    bool? loaded,
    bool? loadFailed,
    bool? compiling,
    String? busyPlanId,
    String? failure,
    String? lastCompiledId,
    bool clearBusy = false,
    bool clearFailure = false,
    bool clearLastCompiled = false,
  }) => ExecutionPlansState(
    plans: plans ?? this.plans,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    loadFailed: loadFailed ?? this.loadFailed,
    compiling: compiling ?? this.compiling,
    busyPlanId: clearBusy ? null : (busyPlanId ?? this.busyPlanId),
    failure: clearFailure ? null : (failure ?? this.failure),
    lastCompiledId: clearLastCompiled
        ? null
        : (lastCompiledId ?? this.lastCompiledId),
  );
}

/// The shopper's compiled plans.
///
/// ## What this notifier cannot do
///
/// It has no method that carries a step out. Its data source deliberately
/// omits the evidence route, so the only writes reachable from here are
/// "compile a proposal", "record my go-ahead" and "cancel". That is the
/// §5.9 line expressed in code rather than in copy: there is no path from
/// this screen to a price, a stock hold or a payment.
class ExecutionPlansNotifier extends StateNotifier<ExecutionPlansState> {
  ExecutionPlansNotifier({
    required ExecutionPlansDataSource dataSource,
    Uuid uuid = const Uuid(),
    bool loadOnCreate = true,
  }) : _ds = dataSource,
       _uuid = uuid,
       super(const ExecutionPlansState()) {
    if (loadOnCreate) unawaited(refresh());
  }

  final ExecutionPlansDataSource _ds;
  final Uuid _uuid;

  /// Re-reads the list. Failures here are quiet: the shopper did not ask for
  /// this read.
  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(loading: true, loadFailed: false);
    try {
      final plans = await _ds.list();
      if (!mounted) return;
      state = state.copyWith(
        plans: plans,
        loading: false,
        loaded: true,
        loadFailed: false,
      );
    } on Object {
      if (!mounted) return;
      state = state.copyWith(loading: false, loaded: true, loadFailed: true);
    }
  }

  /// Compiles [intent] into steps. Creates a proposal and nothing else.
  ///
  /// Returns the new plan's id, or null when the call was refused.
  Future<String?> compile({
    required String intent,
    double? maximumSpend,
    int maximumItems = kExecutionPlanDefaultItems,
    DateTime? mustCompleteByUtc,
  }) async {
    if (!mounted || state.compiling) return null;
    state = state.copyWith(
      compiling: true,
      clearFailure: true,
      clearLastCompiled: true,
    );
    try {
      final plan = await _ds.compile(
        intent: intent,
        currency: kExecutionPlanCurrency,
        maximumItems: maximumItems,
        maximumSpend: maximumSpend,
        mustCompleteByUtc: mustCompleteByUtc,
        idempotencyKey: _uuid.v4(),
      );
      if (!mounted) return plan.id;
      state = state.copyWith(compiling: false, lastCompiledId: plan.id);
      await refresh();
      return plan.id;
    } on Object catch (error) {
      if (!mounted) return null;
      state = state.copyWith(
        compiling: false,
        failure: executionPlanErrorCodeOf(error),
      );
      return null;
    }
  }

  /// Records the shopper's go-ahead for the whole plan. Buys nothing.
  Future<bool> approvePlan(String planId) => _mutate(
    planId,
    (key) => _ds.approvePlan(planId: planId, idempotencyKey: key),
  );

  /// Records the shopper's go-ahead for one gated step. Buys nothing.
  Future<bool> approveStep(String planId, String taskKey) => _mutate(
    planId,
    (key) => _ds.approveStep(
      planId: planId,
      taskKey: taskKey,
      idempotencyKey: key,
    ),
  );

  Future<bool> cancel(String planId) =>
      _mutate(planId, (key) => _ds.cancel(planId: planId, idempotencyKey: key));

  Future<bool> _mutate(
    String planId,
    Future<CommerceExecutionPlan> Function(String idempotencyKey) call,
  ) async {
    if (!mounted || state.busyPlanId != null) return false;
    state = state.copyWith(busyPlanId: planId, clearFailure: true);
    try {
      await call(_uuid.v4());
      if (!mounted) return true;
      state = state.copyWith(clearBusy: true);
      await refresh();
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        clearBusy: true,
        failure: executionPlanErrorCodeOf(error),
      );
      return false;
    }
  }

  void dismissFailure() {
    if (!mounted) return;
    state = state.copyWith(clearFailure: true);
  }
}

/// Reads the backend `errorCode` out of a failed call, falling back to a
/// transport sentinel so the shopper is never shown a raw exception.
String executionPlanErrorCodeOf(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final code = data['errorCode'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
    }
  }
  return ExecutionPlanCopy.transportFailure;
}
