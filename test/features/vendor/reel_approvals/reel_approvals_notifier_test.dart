import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/repositories/reel_approvals_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/presentation/notifiers/approval_rounds_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/presentation/notifiers/reel_approvals_notifier.dart';

ReelApprovalRequest _request({
  String id = 'r1',
  int round = 1,
  ReelApprovalState? state = ReelApprovalState.pending,
}) => ReelApprovalRequest(
  id: id,
  reelId: 'reel1',
  creatorAccountId: 'c1',
  vendorAccountId: 'v1',
  partnershipId: 'p1',
  brandBriefId: 'b1',
  brandBriefVersion: 1,
  round: round,
  state: state,
  submittedUtc: DateTime.utc(2026, 9, 21),
);

class _FakeRepo implements ReelApprovalsRepository {
  _FakeRepo({
    this.pending = const [],
    this.approveResult,
    this.rejectResult,
    this.submitResult,
    this.rounds = const [],
  });

  List<ReelApprovalRequest> pending;
  List<ReelApprovalRequest> rounds;
  Either<NetworkExceptions, Unit>? approveResult;
  Either<NetworkExceptions, ReelApprovalRequest>? rejectResult;
  Either<NetworkExceptions, ReelApprovalRequest>? submitResult;

  int listCalls = 0;
  int roundsCalls = 0;
  String? lastReason;
  String? lastNote;

  @override
  Future<Either<NetworkExceptions, List<ReelApprovalRequest>>>
  listPending() async {
    listCalls++;
    return right(pending);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> approve(String requestId) async =>
      approveResult ?? right(unit);

  @override
  Future<Either<NetworkExceptions, ReelApprovalRequest>> reject({
    required String requestId,
    String? reason,
  }) async {
    lastReason = reason;
    return rejectResult ??
        right(_request(state: ReelApprovalState.rejected));
  }

  @override
  Future<Either<NetworkExceptions, ReelApprovalRequest>> submitForApproval({
    required String reelId,
    String? note,
  }) async {
    lastNote = note;
    return submitResult ?? right(_request());
  }

  @override
  Future<Either<NetworkExceptions, List<ReelApprovalRequest>>> approvalRounds(
    String reelId,
  ) async {
    roundsCalls++;
    return right(rounds);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('ReelApprovalsNotifier', () {
    test('loads the inbox on construction', () async {
      final repo = _FakeRepo(pending: [_request()]);
      final notifier = ReelApprovalsNotifier(repo);
      await _settle();

      expect(repo.listCalls, 1);
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (r, _) => r.length,
          orElse: () => -1,
        ),
        1,
      );
    });

    test('approve reports approved and reloads', () async {
      final repo = _FakeRepo(pending: [_request()]);
      final notifier = ReelApprovalsNotifier(repo);
      await _settle();
      final before = repo.listCalls;

      final outcome = await notifier.approve('r1');
      await _settle();

      expect(outcome, DecisionOutcome.approved);
      expect(repo.listCalls, greaterThan(before));
    });

    test('a 409 on approve reports alreadySettled, not approved', () async {
      // The expiry sweep may have returned the reel to draft while the inbox
      // was open. Saying "approved" would claim a reel went live when it did
      // not.
      final repo = _FakeRepo(
        pending: [_request()],
        approveResult: left(const NetworkExceptions.conflict()),
      );
      final notifier = ReelApprovalsNotifier(repo);
      await _settle();

      final outcome = await notifier.approve('r1');
      expect(outcome, DecisionOutcome.alreadySettled);
    });

    test('a failed decision clears only that row lock', () async {
      final repo = _FakeRepo(
        pending: [_request(), _request(id: 'r2')],
        approveResult: left(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = ReelApprovalsNotifier(repo);
      await _settle();

      final outcome = await notifier.approve('r1');
      expect(outcome, DecisionOutcome.failed);
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (_, deciding) => deciding,
          orElse: () => {'unexpected'},
        ),
        isEmpty,
      );
    });

    test('rejecting with an empty reason passes it through untouched', () async {
      final repo = _FakeRepo(pending: [_request()]);
      final notifier = ReelApprovalsNotifier(repo);
      await _settle();

      await notifier.reject(requestId: 'r1', reason: '');
      // The datasource is what drops an empty reason from the body; the
      // notifier must not second-guess it, because a vendor may reject
      // without saying why and that is a real outcome.
      expect(repo.lastReason, '');
    });
  });

  group('ApprovalRoundsNotifier', () {
    test('orders rounds newest first', () async {
      final repo = _FakeRepo(
        rounds: [
          _request(id: 'r1', round: 1, state: ReelApprovalState.rejected),
          _request(id: 'r3', round: 3),
          _request(id: 'r2', round: 2, state: ReelApprovalState.expired),
        ],
      );
      final notifier = ApprovalRoundsNotifier(repo, 'reel1');
      await _settle();

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (rounds, _) => rounds.map((r) => r.round).toList(),
          orElse: () => <int>[],
        ),
        [3, 2, 1],
      );
    });

    test('submit reports submitted and reloads the history', () async {
      final repo = _FakeRepo();
      final notifier = ApprovalRoundsNotifier(repo, 'reel1');
      await _settle();
      final before = repo.roundsCalls;

      final outcome = await notifier.submit(note: 'take two');
      await _settle();

      expect(outcome, SubmitOutcome.submitted);
      expect(repo.lastNote, 'take two');
      expect(repo.roundsCalls, greaterThan(before));
    });

    test('a 409 reports alreadyPending, not submitted', () async {
      // Only one round is live at a time. Claiming a submission would leave
      // the creator waiting on a review nobody was asked for.
      final repo = _FakeRepo(
        submitResult: left(const NetworkExceptions.conflict()),
      );
      final notifier = ApprovalRoundsNotifier(repo, 'reel1');
      await _settle();

      expect(await notifier.submit(), SubmitOutcome.alreadyPending);
    });

    test('a 404 reports notAllowed rather than a generic failure', () async {
      final repo = _FakeRepo(
        submitResult: left(const NetworkExceptions.notFound()),
      );
      final notifier = ApprovalRoundsNotifier(repo, 'reel1');
      await _settle();

      expect(await notifier.submit(), SubmitOutcome.notAllowed);
    });
  });
}
