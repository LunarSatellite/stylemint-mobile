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

    state = invites.fold(
      (f) => PartnershipsState.loadFailure(f),
      (i) => active.fold(
        (f) => PartnershipsState.loadFailure(f),
        (a) => PartnershipsState.loadSuccess(invites: i, active: a),
      ),
    );
  }

  Future<void> accept(String inviteId) async {
    await _repository.acceptInvite(inviteId);
    unawaited(load());
  }

  Future<void> decline(String inviteId) async {
    await _repository.declineInvite(inviteId);
    unawaited(load());
  }
}
