import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/domain/entities/invite_link.dart';
import 'package:stylemint_mobile_frontend/features/social/referrals/domain/repositories/referrals_repository.dart';

part 'referrals_notifier.freezed.dart';

@freezed
abstract class ReferralsState with _$ReferralsState {
  const ReferralsState._();

  const factory ReferralsState.initial() = _Initial;
  const factory ReferralsState.loadInProgress() = _LoadInProgress;
  const factory ReferralsState.loadSuccess({
    required InviteLink link,
    required List<InviteRedemption> redemptions,
  }) = _LoadSuccess;
  const factory ReferralsState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class ReferralsNotifier extends StateNotifier<ReferralsState> {
  ReferralsNotifier(this._repository) : super(const ReferralsState.initial()) {
    unawaited(load());
  }

  final ReferralsRepository _repository;

  Future<void> load() async {
    state = const ReferralsState.loadInProgress();
    final linkEither = await _repository.getOrCreateMyLink();
    if (linkEither.isLeft()) {
      linkEither.fold((f) => state = ReferralsState.loadFailure(f), (_) {});
      return;
    }
    final link = linkEither.getOrElse((_) => throw StateError('unreachable'));

    final redemptionsEither = await _repository.getRedemptions(link.id);
    final redemptions = redemptionsEither.getOrElse((_) => const []);
    state = ReferralsState.loadSuccess(link: link, redemptions: redemptions);
  }
}
