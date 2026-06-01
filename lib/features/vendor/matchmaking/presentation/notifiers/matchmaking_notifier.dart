import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/repositories/matchmaking_repository.dart';

part 'matchmaking_notifier.freezed.dart';

@freezed
abstract class RecommendationsState with _$RecommendationsState {
  const RecommendationsState._();

  const factory RecommendationsState.initial() = _RecommendationsInitial;
  const factory RecommendationsState.loadInProgress() = _RecommendationsLoadInProgress;
  const factory RecommendationsState.loadSuccess({
    required List<MatchRecommendation> recommendations,
  }) = _RecommendationsLoadSuccess;
  const factory RecommendationsState.loadFailure(NetworkExceptions failure) =
      _RecommendationsLoadFailure;
}

@freezed
abstract class InviteState with _$InviteState {
  const InviteState._();

  const factory InviteState.initial() = _InviteInitial;
  const factory InviteState.submitting() = _InviteSubmitting;
  const factory InviteState.success() = _InviteSuccess;
  const factory InviteState.failure(NetworkExceptions failure) = _InviteFailure;
}

class MatchmakingNotifier extends StateNotifier<RecommendationsState> {
  MatchmakingNotifier(this._repository)
      : super(const RecommendationsState.initial()) {
    unawaited(loadRecommendations());
  }

  final MatchmakingRepository _repository;

  Future<void> loadRecommendations({MatchmakingFilter? filters}) async {
    state = const RecommendationsState.loadInProgress();
    final result = await _repository.getRecommendations(filters: filters);
    state = result.fold(
      RecommendationsState.loadFailure,
      (recs) => RecommendationsState.loadSuccess(recommendations: recs),
    );
  }

  Future<int> getScore(String creatorId) async {
    final result = await _repository.getCompatibilityScore(creatorId);
    return result.fold((_) => 0, (score) => score);
  }
}

class InviteCreatorNotifier extends StateNotifier<InviteState> {
  InviteCreatorNotifier(this._repository) : super(const InviteState.initial());

  final MatchmakingRepository _repository;

  Future<void> invite(String campaignId, String creatorId) async {
    state = const InviteState.submitting();
    final result = await _repository.inviteToCampaign(campaignId, creatorId);
    state = result.fold(InviteState.failure, (_) => const InviteState.success());
  }

  void reset() {
    state = const InviteState.initial();
  }
}
