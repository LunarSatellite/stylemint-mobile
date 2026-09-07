import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';

part 'partnerships_notifier.freezed.dart';

@freezed
abstract class PartnershipsState with _$PartnershipsState {
  const PartnershipsState._();

  const factory PartnershipsState.initial() = _PartnershipsInitial;
  const factory PartnershipsState.loadInProgress() = _PartnershipsLoadInProgress;
  const factory PartnershipsState.loadSuccess({
    required List<PartnershipInvite> invites,
    required List<ActivePartnership> active,
    required List<EndedPartnership> ended,
  }) = _PartnershipsLoadSuccess;
  const factory PartnershipsState.loadFailure(NetworkExceptions failure) =
      _PartnershipsLoadFailure;
}

class PartnershipsNotifier extends StateNotifier<PartnershipsState> {
  PartnershipsNotifier(this._repository)
    : super(const PartnershipsState.initial()) {
    unawaited(load());
  }

  final PartnershipsRepository _repository;

  Future<void> load() async {
    state = const PartnershipsState.loadInProgress();
    final invites = await _repository.getInvites();
    final active = await _repository.getActivePartnerships();
    final ended = await _repository.getEndedPartnerships();

    state = invites.fold(
      (f) => PartnershipsState.loadFailure(f),
      (i) => active.fold(
        (f) => PartnershipsState.loadFailure(f),
        (a) => ended.fold(
          (f) => PartnershipsState.loadFailure(f),
          (e) => PartnershipsState.loadSuccess(invites: i, active: a, ended: e),
        ),
      ),
    );
  }

  /// Returns whether the invite was accepted. The result used to be
  /// discarded, so a rejected accept still reloaded and the screen still
  /// reported success -- a creator was told the partnership was accepted
  /// when the backend had refused it.
  Future<bool> accept(String inviteId) async {
    final result = await _repository.acceptInvite(inviteId);
    return result.fold(
      (_) => false,
      (_) {
        unawaited(load());
        return true;
      },
    );
  }

  /// Returns whether the invite was declined. See [accept].
  Future<bool> decline(String inviteId) async {
    final result = await _repository.declineInvite(inviteId);
    return result.fold(
      (_) => false,
      (_) {
        unawaited(load());
        return true;
      },
    );
  }
}
