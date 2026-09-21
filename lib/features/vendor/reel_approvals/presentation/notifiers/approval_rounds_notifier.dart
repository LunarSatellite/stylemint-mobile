import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/repositories/reel_approvals_repository.dart';

part 'approval_rounds_notifier.freezed.dart';

@freezed
abstract class ApprovalRoundsState with _$ApprovalRoundsState {
  const ApprovalRoundsState._();

  const factory ApprovalRoundsState.initial() = _RoundsInitial;
  const factory ApprovalRoundsState.loadInProgress() = _RoundsLoadInProgress;
  const factory ApprovalRoundsState.loadSuccess({
    required List<ReelApprovalRequest> rounds,
    @Default(false) bool isSubmitting,
  }) = _RoundsLoadSuccess;
  const factory ApprovalRoundsState.loadFailure(NetworkExceptions failure) =
      _RoundsLoadFailure;
}

/// What a submit attempt actually did.
enum SubmitOutcome {
  submitted,

  /// A round is already pending for this reel. Only one is live at a time.
  alreadyPending,

  /// The reel is not a campaign reel, or this creator may not submit it.
  notAllowed,

  failed,
}

/// The approval history of one reel, and the creator's way into a new round.
class ApprovalRoundsNotifier extends StateNotifier<ApprovalRoundsState> {
  ApprovalRoundsNotifier(this._repository, this._reelId)
    : super(const ApprovalRoundsState.initial()) {
    unawaited(load());
  }

  final ReelApprovalsRepository _repository;
  final String _reelId;

  Future<void> load() async {
    state = const ApprovalRoundsState.loadInProgress();
    final result = await _repository.approvalRounds(_reelId);
    if (!mounted) return;
    state = result.fold(
      ApprovalRoundsState.loadFailure,
      // Newest first: what the brand said last time is the thing the creator
      // is about to act on.
      (rounds) => ApprovalRoundsState.loadSuccess(
        rounds: [...rounds]
          ..sort((a, b) => b.round.compareTo(a.round)),
      ),
    );
  }

  /// Opens a new round.
  ///
  /// Reports the outcome instead of assuming success: a 409 means one is
  /// already pending, and telling a creator their reel was submitted when it
  /// was not would leave them waiting on a review nobody was asked for.
  Future<SubmitOutcome> submit({String? note}) async {
    final current = state;
    if (current is _RoundsLoadSuccess && current.isSubmitting) {
      return SubmitOutcome.failed;
    }
    if (current is _RoundsLoadSuccess) {
      state = current.copyWith(isSubmitting: true);
    }

    final result = await _repository.submitForApproval(
      reelId: _reelId,
      note: note,
    );
    if (!mounted) return SubmitOutcome.failed;

    final outcome = result.fold(
      // `isConflict`, not `maybeWhen(conflict:)`. The shared Dio mapper
      // turns a 409 into `.validation(code: 'state.conflict')` — the
      // backend's own ErrorCodes.Conflict — and never into `.conflict()`,
      // which only a handful of repositories construct by hand. Matching
      // on the union case alone silently never fired.
      (failure) => failure.isConflict
          ? SubmitOutcome.alreadyPending
          : failure.isNotFound
          ? SubmitOutcome.notAllowed
          : SubmitOutcome.failed,
      (_) => SubmitOutcome.submitted,
    );

    // Any answer other than an outright failure changes the history, and a
    // 409 means this view was stale to begin with.
    if (outcome == SubmitOutcome.failed) {
      final s = state;
      if (s is _RoundsLoadSuccess) state = s.copyWith(isSubmitting: false);
    } else {
      unawaited(load());
    }
    return outcome;
  }
}
