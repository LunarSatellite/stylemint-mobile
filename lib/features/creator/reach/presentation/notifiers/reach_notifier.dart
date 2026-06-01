import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/repositories/reach_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'reach_notifier.freezed.dart';

@freezed
abstract class ReachState with _$ReachState {
  const ReachState._();

  const factory ReachState.initial() = _ReachInitial;
  const factory ReachState.loadInProgress() = _ReachLoadInProgress;
  const factory ReachState.loadSuccess({
    required List<PublishTarget> targets,
    required List<BoostCampaign> campaigns,
    required ReachAnalytics analytics,
  }) = _ReachLoadSuccess;
  const factory ReachState.loadFailure(NetworkExceptions failure) = _ReachLoadFailure;
}

@freezed
abstract class CreateBoostState with _$CreateBoostState {
  const CreateBoostState._();

  const factory CreateBoostState.editing({
    required String reelId,
    @Default(0) double budget,
    @Default(7) int durationDays,
    @Default('instagram') String platform,
  }) = _CreateBoostEditing;
  const factory CreateBoostState.submitting() = _CreateBoostSubmitting;
  const factory CreateBoostState.success(BoostCampaign campaign) =
      _CreateBoostSuccess;
  const factory CreateBoostState.failure(NetworkExceptions failure) =
      _CreateBoostFailure;
}

class ReachNotifier extends StateNotifier<ReachState> {
  ReachNotifier(this._repository) : super(const ReachState.initial()) {
    unawaited(load());
  }

  final ReachRepository _repository;

  Future<void> load() async {
    state = const ReachState.loadInProgress();
    final targets = await _repository.getPublishTargets();
    final campaigns = await _repository.getBoostCampaigns();
    final analytics = await _repository.getAnalytics();

    state = targets.fold(
      (f) => ReachState.loadFailure(f),
      (t) => campaigns.fold(
        (f) => ReachState.loadFailure(f),
        (c) => analytics.fold(
          (f) => ReachState.loadFailure(f),
          (a) => ReachState.loadSuccess(
            targets: t,
            campaigns: c,
            analytics: a,
          ),
        ),
      ),
    );
  }
}

class CreateBoostNotifier extends StateNotifier<CreateBoostState> {
  CreateBoostNotifier(this._repository, {required String reelId})
    : super(CreateBoostState.editing(reelId: reelId));

  final ReachRepository _repository;

  void setBudget(double budget) {
    state = state.maybeWhen(
      editing:
          (reelId, _, durationDays, platform) => CreateBoostState.editing(
            reelId: reelId,
            budget: budget,
            durationDays: durationDays,
            platform: platform,
          ),
      orElse: () => state,
    );
  }

  void setDuration(int days) {
    state = state.maybeWhen(
      editing:
          (reelId, budget, _, platform) => CreateBoostState.editing(
            reelId: reelId,
            budget: budget,
            durationDays: days,
            platform: platform,
          ),
      orElse: () => state,
    );
  }

  void setPlatform(String platform) {
    state = state.maybeWhen(
      editing:
          (reelId, budget, durationDays, _) => CreateBoostState.editing(
            reelId: reelId,
            budget: budget,
            durationDays: durationDays,
            platform: platform,
          ),
      orElse: () => state,
    );
  }

  Future<void> submit() async {
    final editing = state;
    if (editing is! _CreateBoostEditing) return;

    state = const CreateBoostState.submitting();
    final either = await _repository.createBoostCampaign(
      reelId: editing.reelId,
      platform: editing.platform,
      budget: Money(amount: editing.budget, currency: 'NPR'),
      durationDays: editing.durationDays,
    );
    state = either.fold(
      CreateBoostState.failure,
      CreateBoostState.success,
    );
  }
}
