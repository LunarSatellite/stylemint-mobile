import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/refill_plan_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/refill_plan_dto.dart';
import 'package:uuid/uuid.dart';

/// What the refill-basket screen knows.
///
/// [RefillPlanNone] is the 204 answer and is deliberately **not** a failure:
/// the customer's own rules said no basket should exist. It renders as a calm
/// empty state, never as an error.
sealed class RefillPlanState {
  const RefillPlanState();
}

final class RefillPlanLoading extends RefillPlanState {
  const RefillPlanLoading();
}

/// The rules said no basket. Nothing is wrong.
final class RefillPlanNone extends RefillPlanState {
  const RefillPlanNone();
}

final class RefillPlanReady extends RefillPlanState {
  const RefillPlanReady(this.plan, {this.busy = false});

  final RefillPlanDto plan;

  /// A confirm or dismiss is in flight. Controls disable; nothing else moves.
  final bool busy;
}

/// The plan was approved. The server's lines came back for the customer's own
/// cart — **no order exists**, and nothing here creates one.
final class RefillPlanConfirmed extends RefillPlanState {
  const RefillPlanConfirmed(this.handoff, {this.addingToCart = false});

  final RefillPlanHandoffDto handoff;
  final bool addingToCart;
}

/// The read itself failed. Distinct from [RefillPlanNone] on purpose: a
/// failed read is not the fact that there is no basket.
final class RefillPlanFailed extends RefillPlanState {
  const RefillPlanFailed();
}

/// Reads, prepares, confirms and dismisses the customer's refill basket.
///
/// Two things this notifier never does, and a reviewer should check it still
/// never does:
///
/// 1. **It does not order.** `confirm` records approval and returns lines.
///    Putting those lines in the customer's own cart is a separate, explicitly
///    tapped action — see `RefillPlanScreen`.
/// 2. **It does not prepare on its own.** Opening the screen reads the open
///    plan (`GET current`). Building a new one is a tap, because preparing is
///    the thing the customer's automation level and frequency limit govern.
class RefillPlanNotifier extends StateNotifier<RefillPlanState> {
  RefillPlanNotifier(this._dataSource) : super(const RefillPlanLoading()) {
    unawaited(load());
  }

  static const _uuid = Uuid();

  final RefillPlanDataSource _dataSource;

  /// The open plan. A 204 is [RefillPlanNone]; only a thrown failure is
  /// [RefillPlanFailed].
  Future<void> load() async {
    state = const RefillPlanLoading();
    try {
      final plan = await _dataSource.current();
      state = plan == null ? const RefillPlanNone() : RefillPlanReady(plan);
    } on Object catch (_) {
      state = const RefillPlanFailed();
    }
  }

  /// Asks for a basket to be assembled. A 204 here means the customer's own
  /// rules declined — reminders only, too soon since the last basket, or
  /// nothing due — and is shown as the calm empty state.
  Future<void> prepare() async {
    state = const RefillPlanLoading();
    try {
      final plan = await _dataSource.prepare(idempotencyKey: _uuid.v4());
      state = plan == null ? const RefillPlanNone() : RefillPlanReady(plan);
    } on Object catch (_) {
      state = const RefillPlanFailed();
    }
  }

  /// Records the customer's yes. Returns false when the call failed, so the
  /// screen can say so without the state pretending an approval happened.
  ///
  /// Nothing is ordered, reserved or charged by this call, and the confirmed
  /// state holds only the lines the server handed back.
  Future<bool> confirm() async {
    final current = state;
    if (current is! RefillPlanReady || current.busy) return false;
    state = RefillPlanReady(current.plan, busy: true);
    try {
      final handoff = await _dataSource.confirm(
        planId: current.plan.planId,
        idempotencyKey: _uuid.v4(),
      );
      state = RefillPlanConfirmed(handoff);
      return true;
    } on Object catch (_) {
      state = RefillPlanReady(current.plan);
      return false;
    }
  }

  Future<bool> dismiss() async {
    final current = state;
    if (current is! RefillPlanReady || current.busy) return false;
    state = RefillPlanReady(current.plan, busy: true);
    try {
      await _dataSource.dismiss(
        planId: current.plan.planId,
        idempotencyKey: _uuid.v4(),
      );
      state = const RefillPlanNone();
      return true;
    } on Object catch (_) {
      state = RefillPlanReady(current.plan);
      return false;
    }
  }

  /// Marks the hand-off as being moved into the cart, so the button can
  /// disable itself. The cart call itself belongs to the cart notifier — this
  /// one only tracks that a tap is in flight.
  void setAddingToCart({required bool adding}) {
    final current = state;
    if (current is! RefillPlanConfirmed) return;
    state = RefillPlanConfirmed(current.handoff, addingToCart: adding);
  }
}
