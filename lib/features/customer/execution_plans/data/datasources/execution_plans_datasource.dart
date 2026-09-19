import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/models/commerce_execution_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';

/// `v1/commerce-execution-plans` — the request-to-plan compiler.
///
/// ## The one route this app will not call
///
/// `POST {planId}/tasks/{taskKey}/evidence` is the only route in this family
/// that turns a proposed step into a recorded one. It is deliberately absent
/// from this interface. Section 5.9 of the client proposal says StyleMint's
/// AI "will not set prices, reserve stock or move money"; three of the four
/// compiled steps name exactly those things, so the app that shows the plan
/// must have no way of marking them done. Adding it here would give one.
///
/// What is left — compile, read, give a go-ahead, cancel — creates a
/// proposal and records a human decision about it. None of it moves
/// anything.
abstract class ExecutionPlansDataSource {
  /// Compiles the shopper's stated [intent] into steps. Creates a plan row
  /// and nothing else: no basket, no hold, no payment.
  Future<CommerceExecutionPlan> compile({
    required String intent,
    required String currency,
    required int maximumItems,
    required String idempotencyKey,
    double? maximumSpend,
    DateTime? mustCompleteByUtc,
  });

  /// The shopper's own plans, newest first.
  Future<List<CommerceExecutionPlan>> list();

  Future<CommerceExecutionPlan> get(String planId);

  /// Records the shopper's go-ahead for the whole plan. A go-ahead is not an
  /// execution: every step still has to be carried out by a human in
  /// checkout.
  Future<CommerceExecutionPlan> approvePlan({
    required String planId,
    required String idempotencyKey,
  });

  /// Records the shopper's go-ahead for one step that carries its own gate.
  Future<CommerceExecutionPlan> approveStep({
    required String planId,
    required String taskKey,
    required String idempotencyKey,
  });

  Future<CommerceExecutionPlan> cancel({
    required String planId,
    required String idempotencyKey,
  });
}

class ExecutionPlansRemoteDataSource implements ExecutionPlansDataSource {
  const ExecutionPlansRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  static const String _plans = '/v1/commerce-execution-plans';

  static Options _auth(String idempotencyKey) => Options(
    headers: <String, dynamic>{
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  @override
  Future<CommerceExecutionPlan> compile({
    required String intent,
    required String currency,
    required int maximumItems,
    required String idempotencyKey,
    double? maximumSpend,
    DateTime? mustCompleteByUtc,
  }) async {
    final response = await _api.post(
      _plans,
      data: <String, dynamic>{
        'intent': intent.trim(),
        // Omitted rather than zeroed: the backend treats a null limit as "no
        // ceiling recorded", and rejects a zero one outright.
        'maximumSpend': ?maximumSpend,
        'currency': currency.trim().toUpperCase(),
        'maximumItems': maximumItems,
        'mustCompleteByUtc': ?mustCompleteByUtc?.toUtc().toIso8601String(),
      },
      options: _auth(idempotencyKey),
    );
    return parseCommerceExecutionPlan(_asMap(response));
  }

  @override
  Future<List<CommerceExecutionPlan>> list() async {
    final response = await _api.get(_plans);
    return _asList(
      response,
    ).map(parseCommerceExecutionPlan).toList(growable: false);
  }

  @override
  Future<CommerceExecutionPlan> get(String planId) async {
    final response = await _api.get('$_plans/${Uri.encodeComponent(planId)}');
    return parseCommerceExecutionPlan(_asMap(response));
  }

  @override
  Future<CommerceExecutionPlan> approvePlan({
    required String planId,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '$_plans/${Uri.encodeComponent(planId)}/approve',
      options: _auth(idempotencyKey),
    );
    return parseCommerceExecutionPlan(_asMap(response));
  }

  @override
  Future<CommerceExecutionPlan> approveStep({
    required String planId,
    required String taskKey,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '$_plans/${Uri.encodeComponent(planId)}'
      '/tasks/${Uri.encodeComponent(taskKey)}/approve',
      options: _auth(idempotencyKey),
    );
    return parseCommerceExecutionPlan(_asMap(response));
  }

  @override
  Future<CommerceExecutionPlan> cancel({
    required String planId,
    required String idempotencyKey,
  }) async {
    final response = await _api.authDelete(
      '$_plans/${Uri.encodeComponent(planId)}',
      options: _auth(idempotencyKey),
    );
    return parseCommerceExecutionPlan(_asMap(response));
  }
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<Map<String, dynamic>> _asList(dynamic value) =>
    (value is List ? value : const <dynamic>[])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
