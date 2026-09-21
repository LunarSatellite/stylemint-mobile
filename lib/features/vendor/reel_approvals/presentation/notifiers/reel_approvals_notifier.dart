import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/repositories/reel_approvals_repository.dart';

part 'reel_approvals_notifier.freezed.dart';

@freezed
abstract class ReelApprovalsState with _$ReelApprovalsState {
  const ReelApprovalsState._();

  const factory ReelApprovalsState.initial() = _ApprovalsInitial;
  const factory ReelApprovalsState.loadInProgress() = _ApprovalsLoadInProgress;
  const factory ReelApprovalsState.loadSuccess({
    required List<ReelApprovalRequest> requests,

    /// Ids currently being approved or rejected, so each row can disable only
    /// its own buttons instead of locking the whole inbox.
    @Default(<String>{}) Set<String> deciding,
  }) = _ApprovalsLoadSuccess;
  const factory ReelApprovalsState.loadFailure(NetworkExceptions failure) =
      _ApprovalsLoadFailure;
}

/// What a decision actually did.
enum DecisionOutcome {
  approved,
  rejected,

  /// The round was already settled — the other decision landed first, or the
  /// expiry sweep returned the reel to draft while this screen was open.
  alreadySettled,

  failed,
}

/// The vendor's inbox of campaign reels awaiting review.
class ReelApprovalsNotifier extends StateNotifier<ReelApprovalsState> {
  ReelApprovalsNotifier(this._repository)
    : super(const ReelApprovalsState.initial()) {
    unawaited(load());
  }

  final ReelApprovalsRepository _repository;

  Future<void> load() async {
    state = const ReelApprovalsState.loadInProgress();
    final result = await _repository.listPending();
    if (!mounted) return;
    state = result.fold(
      ReelApprovalsState.loadFailure,
      (requests) => ReelApprovalsState.loadSuccess(requests: requests),
    );
  }

  /// Approving publishes the reel. Reports what happened rather than assuming
  /// success: a 409 means the round was settled behind the vendor's back, and
  /// telling them "approved" would claim a reel went live when it did not.
  Future<DecisionOutcome> approve(String requestId) => _decide(
    requestId,
    () => _repository.approve(requestId),
    DecisionOutcome.approved,
  );

  /// Rejecting returns the reel to the creator as a draft they may revise and
  /// resubmit. [reason] is optional and stays optional — see the repository.
  Future<DecisionOutcome> reject({
    required String requestId,
    String? reason,
  }) => _decide(
    requestId,
    () => _repository.reject(requestId: requestId, reason: reason),
    DecisionOutcome.rejected,
  );

  /// Runs one decision. The two calls answer different right-hand types —
  /// approve gives [Unit], reject gives the settled request — but `Either` is
  /// covariant in that type, so both are an `Either<NetworkExceptions, Object>`
  /// and only the left side is ever inspected here.
  Future<DecisionOutcome> _decide(
    String requestId,
    Future<Either<NetworkExceptions, Object>> Function() call,
    DecisionOutcome success,
  ) async {
    final current = state;
    if (current is! _ApprovalsLoadSuccess) return DecisionOutcome.failed;
    if (current.deciding.contains(requestId)) return DecisionOutcome.failed;

    state = current.copyWith(deciding: {...current.deciding, requestId});

    final result = await call();
    if (!mounted) return DecisionOutcome.failed;

    final outcome = result.fold(
      // `isConflict`, not `maybeWhen(conflict:)`. The shared Dio mapper
      // turns a 409 into `.validation(code: 'state.conflict')` — the
      // backend's own ErrorCodes.Conflict — and never into `.conflict()`,
      // which only a handful of repositories construct by hand. Matching
      // on the union case alone silently never fired.
      (failure) => failure.isConflict
          ? DecisionOutcome.alreadySettled
          : DecisionOutcome.failed,
      (_) => success,
    );

    if (outcome == DecisionOutcome.failed) {
      final s = state;
      if (s is _ApprovalsLoadSuccess) {
        state = s.copyWith(
          deciding: {...s.deciding}..remove(requestId),
        );
      }
    } else {
      // A settled 409 means this inbox is stale too, so both it and a real
      // decision reload.
      unawaited(load());
    }
    return outcome;
  }
}
