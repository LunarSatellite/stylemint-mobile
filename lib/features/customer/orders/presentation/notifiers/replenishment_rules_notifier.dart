import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/refill_plan_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/replenishment_rules_dto.dart';
import 'package:uuid/uuid.dart';

sealed class ReplenishmentRulesState {
  const ReplenishmentRulesState();
}

final class ReplenishmentRulesLoading extends ReplenishmentRulesState {
  const ReplenishmentRulesLoading();
}

/// A rule set that could not be read is not a rule set to override. The
/// screen says so and offers no controls, because a control drawn over an
/// unknown value would save a guess.
final class ReplenishmentRulesFailed extends ReplenishmentRulesState {
  const ReplenishmentRulesFailed();
}

final class ReplenishmentRulesLoaded extends ReplenishmentRulesState {
  const ReplenishmentRulesLoaded(
    this.preference, {
    this.saving = false,
    this.error,
  });

  final ReplenishmentPreferenceDto preference;
  final bool saving;

  /// The last refusal, in the customer's words. Cleared on the next save.
  final String? error;

  ReplenishmentRulesLoaded copyWith({
    ReplenishmentPreferenceDto? preference,
    bool? saving,
    Object? error = _unset,
  }) => ReplenishmentRulesLoaded(
    preference ?? this.preference,
    saving: saving ?? this.saving,
    error: error == _unset ? this.error : error as String?,
  );

  static const Object _unset = Object();
}

/// The rules the customer sets for replenishment, and the pause that lifts
/// itself.
///
/// Every rule the backend accepts is settable here and round-trips: the
/// backend replies with the stored rule set and that reply becomes the state,
/// so what the screen shows afterwards is what was saved, never what was
/// typed.
///
/// Out-of-range values are refused **before** the call. The backend refuses
/// them too (it throws rather than clamping, deliberately), but a client that
/// let a 40-day lead time leave the device would be asking the customer to
/// discover a rule the screen already knows.
class ReplenishmentRulesNotifier
    extends StateNotifier<ReplenishmentRulesState> {
  ReplenishmentRulesNotifier(this._dataSource)
    : super(const ReplenishmentRulesLoading()) {
    unawaited(load());
  }

  static const _uuid = Uuid();

  final RefillPlanDataSource _dataSource;

  Future<void> load() async {
    try {
      state = ReplenishmentRulesLoaded(await _dataSource.preference());
    } on Object catch (_) {
      state = const ReplenishmentRulesFailed();
    }
  }

  /// Saves the whole rule set. Returns false when it was refused — locally or
  /// by the server — and leaves the previously saved rules in place.
  Future<bool> save(ReplenishmentRulesRequest rules) async {
    final current = state;
    if (current is! ReplenishmentRulesLoaded || current.saving) return false;

    final refusal = rules.validationError;
    if (refusal != null) {
      state = current.copyWith(error: refusal);
      return false;
    }

    state = current.copyWith(saving: true, error: null);
    try {
      final saved = await _dataSource.setRules(
        rules,
        idempotencyKey: _uuid.v4(),
      );
      state = ReplenishmentRulesLoaded(saved);
      return true;
    } on Object catch (_) {
      state = current.copyWith(
        saving: false,
        error: "We couldn't save those rules. Please try again.",
      );
      return false;
    }
  }

  /// A quiet period. [until] must be in the future; null resumes immediately.
  Future<bool> setPause(DateTime? until) async {
    final current = state;
    if (current is! ReplenishmentRulesLoaded || current.saving) return false;

    if (until != null && !until.toUtc().isAfter(DateTime.now().toUtc())) {
      state = current.copyWith(error: 'A pause has to end in the future.');
      return false;
    }

    state = current.copyWith(saving: true, error: null);
    try {
      final saved = await _dataSource.setPause(
        until,
        idempotencyKey: _uuid.v4(),
      );
      state = ReplenishmentRulesLoaded(saved);
      return true;
    } on Object catch (_) {
      state = current.copyWith(
        saving: false,
        error: "We couldn't change your pause. Please try again.",
      );
      return false;
    }
  }
}
