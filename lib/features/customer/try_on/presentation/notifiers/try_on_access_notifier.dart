import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/repositories/try_on_repository.dart';

part 'try_on_access_notifier.freezed.dart';

@freezed
abstract class TryOnAccessState with _$TryOnAccessState {
  const TryOnAccessState._();

  const factory TryOnAccessState.initial() = _Initial;
  const factory TryOnAccessState.loadInProgress() = _LoadInProgress;
  const factory TryOnAccessState.loadSuccess(TryOnAccess access) = _LoadSuccess;
  const factory TryOnAccessState.loadFailure(TryOnFailure failure) =
      _LoadFailure;

  TryOnAccess? get accessOrNull =>
      maybeWhen(loadSuccess: (a) => a, orElse: () => null);
}

/// The signed-in buyer's try-on access — one instance shared by the product
/// page's entry point, the paywall and "My try-on plan", so a trial started
/// on the paywall unlocks the product page without a refetch of its own.
class TryOnAccessNotifier extends StateNotifier<TryOnAccessState> {
  TryOnAccessNotifier(this._repository)
    : super(const TryOnAccessState.initial());

  final TryOnRepository _repository;

  /// Loads once; later calls are no-ops unless [force] or the last load
  /// failed.
  Future<void> ensureLoaded() async {
    final loaded = state.maybeWhen(
      loadSuccess: (_) => true,
      loadInProgress: () => true,
      orElse: () => false,
    );
    if (!loaded) await refresh();
  }

  Future<void> refresh() async {
    // Keep showing the old value while refreshing, so the paywall does not
    // flash a spinner after a purchase.
    if (state.accessOrNull == null) {
      state = const TryOnAccessState.loadInProgress();
    }
    final result = await _repository.getAccess();
    if (!mounted) return;
    state = result.fold(
      TryOnAccessState.loadFailure,
      TryOnAccessState.loadSuccess,
    );
  }

  /// Applies an access value a mutation returned (e.g. `POST /trial`).
  void apply(TryOnAccess access) =>
      state = TryOnAccessState.loadSuccess(access);
}
