import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/repositories/mall_home_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/adaptive_layout.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/storefront_personalizer.dart';

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
///
/// The page is always the one `GET api/v1/public/home` returned. When the
/// adaptive storefront has something to say about this customer, its ranking
/// is applied to that page before it is shown; when it does not — a guest,
/// paused personalisation, a failed or empty response — the page is shown
/// unchanged, which is the whole of the fallback. The two calls run together
/// and the layout never delays the page: a slow or dead personalisation call
/// costs the Mall nothing.
class MallHomeNotifier extends StateNotifier<MallHomeState> {
  MallHomeNotifier(this._repository, {StorefrontPersonalizer? personalizer})
    : _personalizer = personalizer,
      super(const MallHomeState.initial()) {
    unawaited(load());
  }

  final MallHomeRepository _repository;
  final StorefrontPersonalizer? _personalizer;

  /// Home, with the adaptive ranking applied when there is one.
  Future<Either<NetworkExceptions, MallHome>> _adaptiveHome() async {
    final personalizer = _personalizer;
    if (personalizer == null) return _repository.getHome();
    // Started together so personalisation adds no latency of its own.
    final layoutFuture = personalizer.layout();
    final homeResult = await _repository.getHome();
    final layout = await layoutFuture;
    return homeResult.map((home) {
      // The last line of the invisible fallback. Organising the page is the
      // one part of this that runs on the client, so if it ever throws — a
      // shape from a newer server this build mishandles — the customer gets
      // the ordinary page rather than an error. Never a half-personalised
      // one: the un-applied `home` is exactly what everybody else sees.
      try {
        return applyStorefrontLayout(home, layout);
      } on Object catch (_) {
        return home;
      }
    });
  }

  /// The session changed, so the consent answer may have too.
  void forgetConsent() => _personalizer?.forgetConsent();

  /// Only the newest request may settle the state.
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    state = const MallHomeState.loadInProgress();
    final result = await _adaptiveHome();
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
    final result = await _adaptiveHome();
    if (!mounted || request != _request) return false;
    return result.fold((_) => false, (home) {
      state = MallHomeState.loadSuccess(home);
      return true;
    });
  }
}
