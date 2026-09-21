import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/repositories/creator_campaigns_repository.dart';

part 'campaign_applications_notifier.freezed.dart';

@freezed
abstract class CampaignApplicationsState with _$CampaignApplicationsState {
  const CampaignApplicationsState._();

  const factory CampaignApplicationsState.initial() = _ApplicationsInitial;
  const factory CampaignApplicationsState.loadInProgress() =
      _ApplicationsLoadInProgress;
  const factory CampaignApplicationsState.loadSuccess({
    required List<CampaignApplication> applications,
    required bool hasMore,
    String? nextCursor,
  }) = _ApplicationsLoadSuccess;
  const factory CampaignApplicationsState.loadFailure(
    NetworkExceptions failure,
  ) = _ApplicationsLoadFailure;
}

/// What came of the creator's applications.
class CampaignApplicationsNotifier
    extends StateNotifier<CampaignApplicationsState> {
  CampaignApplicationsNotifier(this._repository)
    : super(const CampaignApplicationsState.initial()) {
    unawaited(load());
  }

  final CreatorCampaignsRepository _repository;

  Future<void> load() async {
    state = const CampaignApplicationsState.loadInProgress();
    final result = await _repository.listApplications();
    if (!mounted) return;
    state = result.fold(
      CampaignApplicationsState.loadFailure,
      (page) => CampaignApplicationsState.loadSuccess(
        applications: page.items,
        hasMore: page.hasMore,
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Withdraws one application and reports what happened, rather than assuming
  /// success and reloading: the vendor may have accepted or declined between
  /// this screen rendering and the tap, in which case the server answers 409
  /// and the creator must be told their application was already decided — not
  /// shown a withdrawal that never occurred.
  Future<WithdrawOutcome> withdraw(String applicationId) async {
    final result = await _repository.withdraw(applicationId);
    final outcome = result.fold(
      (failure) => failure.maybeWhen(
        conflict: () => WithdrawOutcome.alreadyDecided,
        orElse: () => WithdrawOutcome.failed,
      ),
      (_) => WithdrawOutcome.withdrawn,
    );
    // Both the success and the 409 mean this screen is now stale: reload so
    // the row shows whatever the server actually holds.
    if (outcome != WithdrawOutcome.failed) unawaited(load());
    return outcome;
  }
}

/// What a withdraw attempt actually did.
enum WithdrawOutcome {
  withdrawn,

  /// The vendor had already accepted or declined it.
  alreadyDecided,

  failed,
}
