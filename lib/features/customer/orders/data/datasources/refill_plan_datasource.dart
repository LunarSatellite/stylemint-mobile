import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/refill_plan_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/replenishment_rules_dto.dart';

/// The prepared refill basket and the rules that govern it —
/// `/v1/customer/refill-plans` and `/v1/customer/reorder-suggestions/{rules,
/// pause}`.
///
/// **Nothing on this data source places an order.** `confirm` is the approval
/// boundary: it records the customer's yes and hands back the lines for their
/// own cart. No route here creates an order, a hold or a payment, and none may
/// be added.
///
/// `current` and `prepare` return **null for 204**, which the backend sends
/// whenever the customer's own rules say no basket should exist — not opted
/// in, paused, reminders only, inside their frequency limit, or nothing due.
/// A 204 is an answer, never an error.
abstract class RefillPlanDataSource {
  /// The open plan, or null when the rules say there is none.
  Future<RefillPlanDto?> current();

  /// Verifies what is due and assembles a basket within the customer's rules.
  /// Null when their rules say no basket should be built.
  Future<RefillPlanDto?> prepare({required String idempotencyKey});

  /// Records the customer's approval and returns the lines. Nothing is
  /// ordered, reserved or charged.
  Future<RefillPlanHandoffDto> confirm({
    required String planId,
    required String idempotencyKey,
  });

  Future<void> dismiss({
    required String planId,
    required String idempotencyKey,
  });

  /// The whole rule set, including the on/off switch and any pause.
  Future<ReplenishmentPreferenceDto> preference();

  /// Replaces the rule set as one whole.
  Future<ReplenishmentPreferenceDto> setRules(
    ReplenishmentRulesRequest rules, {
    required String idempotencyKey,
  });

  /// A quiet period that lifts itself. A null instant resumes immediately.
  Future<ReplenishmentPreferenceDto> setPause(
    DateTime? pausedUntilUtc, {
    required String idempotencyKey,
  });
}

class RefillPlanRemoteDataSource implements RefillPlanDataSource {
  const RefillPlanRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  static const String _plans = '/v1/customer/refill-plans';
  static const String _suggestions = '/v1/customer/reorder-suggestions';

  final ApiClient _api;

  @override
  Future<RefillPlanDto?> current() async =>
      _planOrNone(await _api.get('$_plans/current'));

  @override
  Future<RefillPlanDto?> prepare({required String idempotencyKey}) async =>
      _planOrNone(
        await _api.post(
          _plans,
          data: const <String, dynamic>{},
          options: _idempotent(idempotencyKey),
        ),
      );

  @override
  Future<RefillPlanHandoffDto> confirm({
    required String planId,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '$_plans/$planId/confirm',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );
    return RefillPlanHandoffDto.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> dismiss({
    required String planId,
    required String idempotencyKey,
  }) async {
    await _api.authDelete(
      '$_plans/$planId',
      options: _idempotent(idempotencyKey),
    );
  }

  @override
  Future<ReplenishmentPreferenceDto> preference() async =>
      ReplenishmentPreferenceDto.fromJson(
        await _api.get('$_suggestions/preference') as Map<String, dynamic>,
      );

  @override
  Future<ReplenishmentPreferenceDto> setRules(
    ReplenishmentRulesRequest rules, {
    required String idempotencyKey,
  }) async {
    final response = await _api.put(
      '$_suggestions/rules',
      data: rules.toJson(),
      options: _idempotent(idempotencyKey),
    );
    return ReplenishmentPreferenceDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  @override
  Future<ReplenishmentPreferenceDto> setPause(
    DateTime? pausedUntilUtc, {
    required String idempotencyKey,
  }) async {
    final response = await _api.put(
      '$_suggestions/pause',
      data: <String, dynamic>{
        'pausedUntilUtc': pausedUntilUtc?.toUtc().toIso8601String(),
      },
      options: _idempotent(idempotencyKey),
    );
    return ReplenishmentPreferenceDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  /// 204 arrives here as a null (or empty) body. That is the rules saying no
  /// basket — a calm, expected answer, so it is mapped to null rather than
  /// thrown.
  RefillPlanDto? _planOrNone(dynamic response) {
    if (response is! Map<String, dynamic> || response.isEmpty) return null;
    return RefillPlanDto.fromJson(response);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
  );
}
