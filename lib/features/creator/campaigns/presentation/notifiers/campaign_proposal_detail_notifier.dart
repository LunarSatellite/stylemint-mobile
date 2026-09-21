import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/repositories/creator_campaigns_repository.dart';

part 'campaign_proposal_detail_notifier.freezed.dart';

@freezed
abstract class CampaignProposalDetailState
    with _$CampaignProposalDetailState {
  const CampaignProposalDetailState._();

  const factory CampaignProposalDetailState.initial() = _DetailInitial;
  const factory CampaignProposalDetailState.loadInProgress() =
      _DetailLoadInProgress;
  const factory CampaignProposalDetailState.loadSuccess({
    required CampaignProposal proposal,
    @Default(false) bool isApplying,
  }) = _DetailLoadSuccess;
  const factory CampaignProposalDetailState.loadFailure(
    NetworkExceptions failure,
  ) = _DetailLoadFailure;
}

/// What an apply attempt actually did. The screen must report these
/// differently: telling a creator "applied" when the server refused would
/// leave them waiting on a vendor who never received anything.
enum ApplyOutcome {
  applied,

  /// A live application on this brief's lineage already exists. One slot per
  /// lineage, held by a pending or accepted application.
  alreadyApplied,

  /// The brief is no longer readable — retired, or its application window
  /// closed while the screen was open. The server answers 404 for every such
  /// case alike, so this says only that it is unavailable.
  unavailable,

  failed,
}

class CampaignProposalDetailNotifier
    extends StateNotifier<CampaignProposalDetailState> {
  CampaignProposalDetailNotifier(this._repository, this._briefId)
    : super(const CampaignProposalDetailState.initial()) {
    unawaited(load());
  }

  final CreatorCampaignsRepository _repository;
  final String _briefId;

  Future<void> load() async {
    state = const CampaignProposalDetailState.loadInProgress();
    final result = await _repository.getProposal(_briefId);
    if (!mounted) return;
    state = result.fold(
      CampaignProposalDetailState.loadFailure,
      (p) => CampaignProposalDetailState.loadSuccess(proposal: p),
    );
  }

  /// Applies, and returns both the outcome and the application when there is
  /// one. The application is returned rather than discarded so the caller can
  /// show what was actually created instead of re-fetching it.
  Future<(ApplyOutcome, CampaignApplication?)> apply({String? message}) async {
    final current = state;
    if (current is! _DetailLoadSuccess) return (ApplyOutcome.failed, null);
    if (current.isApplying) return (ApplyOutcome.failed, null);

    state = current.copyWith(isApplying: true);
    final result = await _repository.apply(
      briefId: _briefId,
      message: message,
    );
    if (!mounted) return (ApplyOutcome.failed, null);

    return result.fold(
      (failure) {
        state = current.copyWith(isApplying: false);
        // See CampaignApplicationsNotifier: a 409 arrives as
        // `.validation(code: 'state.conflict')`, so `isConflict` is the only
        // check that sees it. 404 does map to `.notFound()`.
        final outcome = failure.isConflict
            ? ApplyOutcome.alreadyApplied
            : failure.isNotFound
            ? ApplyOutcome.unavailable
            : ApplyOutcome.failed;
        return (outcome, null);
      },
      (application) {
        state = current.copyWith(isApplying: false);
        return (ApplyOutcome.applied, application);
      },
    );
  }
}
