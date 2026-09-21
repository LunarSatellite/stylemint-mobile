import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/repositories/creator_campaigns_repository.dart';

part 'campaign_proposals_notifier.freezed.dart';

@freezed
abstract class CampaignProposalsState with _$CampaignProposalsState {
  const CampaignProposalsState._();

  const factory CampaignProposalsState.initial() = _ProposalsInitial;
  const factory CampaignProposalsState.loadInProgress() =
      _ProposalsLoadInProgress;
  const factory CampaignProposalsState.loadSuccess({
    required List<CampaignProposal> proposals,
    required bool hasMore,
    String? nextCursor,
    @Default(false) bool isLoadingMore,
  }) = _ProposalsLoadSuccess;
  const factory CampaignProposalsState.loadFailure(NetworkExceptions failure) =
      _ProposalsLoadFailure;
}

/// The list of campaigns a creator may apply to.
///
/// The server decides what is open, so this holds exactly what it returned and
/// never filters by date on the client — a clock skew here would hide a live
/// campaign or offer a closed one.
class CampaignProposalsNotifier
    extends StateNotifier<CampaignProposalsState> {
  CampaignProposalsNotifier(this._repository)
    : super(const CampaignProposalsState.initial()) {
    unawaited(load());
  }

  final CreatorCampaignsRepository _repository;

  Future<void> load() async {
    state = const CampaignProposalsState.loadInProgress();
    final result = await _repository.listProposals();
    if (!mounted) return;
    state = result.fold(
      CampaignProposalsState.loadFailure,
      (page) => CampaignProposalsState.loadSuccess(
        proposals: page.items,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Appends the next page. A failure mid-scroll leaves what is already on
  /// screen in place and only clears the loading flag: dropping loaded
  /// campaigns because page three failed would lose the creator's place.
  Future<void> loadMore() async {
    final current = state;
    if (current is! _ProposalsLoadSuccess) return;
    if (!current.hasMore || current.isLoadingMore) return;
    if (current.nextCursor == null) return;

    state = current.copyWith(isLoadingMore: true);
    final result = await _repository.listProposals(cursor: current.nextCursor);
    if (!mounted) return;
    state = result.fold(
      (_) => current.copyWith(isLoadingMore: false),
      (page) => CampaignProposalsState.loadSuccess(
        proposals: [...current.proposals, ...page.items],
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }
}
