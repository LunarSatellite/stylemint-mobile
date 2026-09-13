import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';

part 'basket_scenarios_notifier.freezed.dart';

@freezed
abstract class BasketScenariosState with _$BasketScenariosState {
  const factory BasketScenariosState.initial() = _Initial;
  const factory BasketScenariosState.loadInProgress() = _LoadInProgress;
  const factory BasketScenariosState.loadSuccess(BasketScenarios result) =
      _LoadSuccess;
  const factory BasketScenariosState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

/// "Try other baskets": read-only alternatives to the shopper's cart. Loads
/// once with no constraints on creation; [load] re-runs with a budget and
/// the lines that must stay as they are.
class BasketScenariosNotifier extends StateNotifier<BasketScenariosState> {
  BasketScenariosNotifier(this._repository)
    : super(const BasketScenariosState.initial()) {
    unawaited(load());
  }

  final CartRepository _repository;
  int _requestSeq = 0;

  /// A reply to an earlier request is discarded, so a slow first load can't
  /// overwrite the options the shopper asked for afterwards.
  Future<void> load({
    double? budget,
    List<String> keepLineIds = const [],
  }) async {
    final seq = ++_requestSeq;
    state = const BasketScenariosState.loadInProgress();
    final either = await _repository.getScenarios(
      budget: budget,
      keepLineIds: keepLineIds,
    );
    if (!mounted || seq != _requestSeq) return;
    state = either.fold(
      BasketScenariosState.loadFailure,
      BasketScenariosState.loadSuccess,
    );
  }
}

const budgetAboveZeroMessage = 'Enter a budget above zero.';

/// The message to show on the budget field when the backend rejected the
/// budget (a 400 naming `budget`), otherwise null.
String? budgetErrorOf(NetworkExceptions failure) => failure.maybeWhen(
  validation: (_, message, field, errors) {
    for (final error in errors) {
      if (error.field.toLowerCase() == 'budget') {
        return error.message.trim().isNotEmpty
            ? error.message.trim()
            : budgetAboveZeroMessage;
      }
    }
    if ((field ?? '').toLowerCase() != 'budget') return null;
    final text = (message ?? '').trim();
    return text.isNotEmpty ? text : budgetAboveZeroMessage;
  },
  orElse: () => null,
);
