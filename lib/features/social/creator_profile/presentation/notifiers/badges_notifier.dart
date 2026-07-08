import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/entities/badge_award.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/domain/repositories/creator_profile_repository.dart';

part 'badges_notifier.freezed.dart';

// ── Load badges ───────────────────────────────────────────────────────────────

@freezed
abstract class BadgesState with _$BadgesState {
  const BadgesState._();

  const factory BadgesState.initial() = _BadgesInitial;
  const factory BadgesState.loadInProgress() = _BadgesLoadInProgress;
  const factory BadgesState.loadSuccess(List<BadgeAward> badges) =
      _BadgesLoadSuccess;
  const factory BadgesState.loadFailure(NetworkExceptions failure) =
      _BadgesLoadFailure;
}

class BadgesNotifier extends StateNotifier<BadgesState> {
  BadgesNotifier(this._repository) : super(const BadgesState.initial()) {
    unawaited(load());
  }

  final CreatorProfileRepository _repository;

  Future<void> load() async {
    state = const BadgesState.loadInProgress();
    final either = await _repository.listMyBadges();
    state = either.fold(
      BadgesState.loadFailure,
      BadgesState.loadSuccess,
    );
  }
}

// ── Update showcase ───────────────────────────────────────────────────────────

@freezed
abstract class UpdateShowcaseState with _$UpdateShowcaseState {
  const UpdateShowcaseState._();

  const factory UpdateShowcaseState.initial() = _UpdateShowcaseInitial;
  const factory UpdateShowcaseState.submitting() = _UpdateShowcaseSubmitting;
  const factory UpdateShowcaseState.success(List<BadgeAward> badges) =
      _UpdateShowcaseSuccess;
  const factory UpdateShowcaseState.failure(NetworkExceptions failure) =
      _UpdateShowcaseFailure;
}

class UpdateShowcaseNotifier extends StateNotifier<UpdateShowcaseState> {
  UpdateShowcaseNotifier(this._repository)
      : super(const UpdateShowcaseState.initial());

  final CreatorProfileRepository _repository;

  Future<void> submit(List<String> awardIdsInOrder) async {
    state = const UpdateShowcaseState.submitting();
    final either =
        await _repository.updateBadgeShowcase(awardIdsInOrder);
    state = either.fold(
      UpdateShowcaseState.failure,
      UpdateShowcaseState.success,
    );
  }

  void reset() => state = const UpdateShowcaseState.initial();
}
