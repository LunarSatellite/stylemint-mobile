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
  const factory RecommendationsState.loadInProgress() =
      _RecommendationsLoadInProgress;
  const factory RecommendationsState.loadSuccess({
    required List<MatchRecommendation> recommendations,
    required bool hasMore,
    required bool loadMoreInProgress,
  }) = _RecommendationsLoadSuccess;
  const factory RecommendationsState.loadFailure(NetworkExceptions failure) =
      _RecommendationsLoadFailure;
}

@freezed
abstract class InviteState with _$InviteState {
  const InviteState._();

  const factory InviteState.initial() = _InviteInitial;
  const factory InviteState.submitting() = _InviteSubmitting;
  const factory InviteState.success(PartnershipPrefill prefill) =
      _InviteSuccess;
  const factory InviteState.failure(NetworkExceptions failure) = _InviteFailure;
}

class MatchmakingNotifier extends StateNotifier<RecommendationsState> {
  MatchmakingNotifier(this._repository)
    : super(const RecommendationsState.initial()) {
    unawaited(loadRecommendations());
  }

  final MatchmakingRepository _repository;

  static const _pageSize = 10;
  String? _nextCursor;

  Future<void> loadRecommendations() async {
    state = const RecommendationsState.loadInProgress();
    final result = await _repository.getRecommendations(
      pageSize: _pageSize,
    );
    state = result.fold(
      RecommendationsState.loadFailure,
      (paged) {
        _nextCursor = paged.nextCursor;
        return RecommendationsState.loadSuccess(
          recommendations: paged.items,
          hasMore: paged.hasMore,
          loadMoreInProgress: false,
        );
      },
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! _RecommendationsLoadSuccess ||
        !current.hasMore ||
        _nextCursor == null) {
      return;
    }
    state = current.copyWith(loadMoreInProgress: true);
    final result = await _repository.getRecommendations(
      pageSize: _pageSize,
      cursor: _nextCursor,
    );
    state = result.fold(
      RecommendationsState.loadFailure,
      (paged) {
        _nextCursor = paged.nextCursor;
        return RecommendationsState.loadSuccess(
          recommendations: [...current.recommendations, ...paged.items],
          hasMore: paged.hasMore,
          loadMoreInProgress: false,
        );
      },
    );
  }

  Future<bool> dismissMatch(String matchId) async {
    final current = state;
    if (current is! _RecommendationsLoadSuccess) return false;
    final result = await _repository.dismissMatch(matchId);
    return result.fold((_) => false, (_) {
      state = current.copyWith(
        recommendations: current.recommendations
            .where((r) => r.id != matchId)
            .toList(growable: false),
      );
      return true;
    });
  }
}

class InviteCreatorNotifier extends StateNotifier<InviteState> {
  InviteCreatorNotifier(this._repository) : super(const InviteState.initial());

  final MatchmakingRepository _repository;

  Future<void> invite(String matchId) async {
    state = const InviteState.submitting();
    final result = await _repository.invite(matchId);
    state = result.fold(InviteState.failure, InviteState.success);
  }

  void reset() {
    state = const InviteState.initial();
  }
}
