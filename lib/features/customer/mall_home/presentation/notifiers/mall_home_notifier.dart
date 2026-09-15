import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';

part 'mall_home_notifier.freezed.dart';

@freezed
abstract class MallHomeState with _$MallHomeState {
  const MallHomeState._();

  const factory MallHomeState.initial() = _Initial;
  const factory MallHomeState.loadInProgress() = _LoadInProgress;
  const factory MallHomeState.loadSuccess(MallHome home) = _LoadSuccess;
  const factory MallHomeState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;

  MallHome? get homeOrNull =>
      maybeWhen(loadSuccess: (home) => home, orElse: () => null);
}

/// The Mall home page. [refresh] keeps the current page on screen while it
/// refetches; only a first load shows skeletons.
class MallHomeNotifier extends StateNotifier<MallHomeState> {
  MallHomeNotifier(this._repository) : super(const MallHomeState.initial()) {
    unawaited(load());
  }

  final MallHomeRepository _repository;

  /// Only the newest request may settle the state.
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    state = const MallHomeState.loadInProgress();
    final result = await _repository.getHome();
    if (!mounted || request != _request) return;
    state = result.fold(MallHomeState.loadFailure, MallHomeState.loadSuccess);
  }

  /// Pull to refresh and Home re-taps. Returns whether the page updated; a
  /// failure keeps what is already shown.
  Future<bool> refresh() async {
    if (state.homeOrNull == null) {
      await load();
      return mounted && state.homeOrNull != null;
    }
    final request = ++_request;
    final result = await _repository.getHome();
    if (!mounted || request != _request) return false;
    return result.fold((_) => false, (home) {
      state = MallHomeState.loadSuccess(home);
      return true;
    });
  }
}
