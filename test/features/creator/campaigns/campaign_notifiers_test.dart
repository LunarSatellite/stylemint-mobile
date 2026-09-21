import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_proposal.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/repositories/creator_campaigns_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_applications_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_proposal_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/presentation/notifiers/campaign_proposals_notifier.dart';

/// What the shared Dio mapper actually returns for an HTTP 409.
///
/// It is NOT `NetworkExceptions.conflict()` — that case exists but only a
/// handful of repositories build it by hand. A 409 through
/// `mapDioExceptionToNetworkException` becomes `.validation` carrying the
/// backend's `ErrorCodes.Conflict`, which is the literal string
/// `state.conflict`. Tests that assert with `.conflict()` pass while the real
/// app never takes the branch, so these use the real shape.
NetworkExceptions _conflict409() =>
    const NetworkExceptions.validation(code: 'state.conflict');


CampaignProposal _proposal(String id) => CampaignProposal(
  id: id,
  vendorProfileId: 'v1',
  version: 1,
  rootBriefId: 'root',
  title: 'Campaign $id',
  commission: const CommissionBand(minPercent: 10, maxPercent: 20),
);

CampaignApplication _application({
  String id = 'a1',
  CampaignApplicationState? state = CampaignApplicationState.pending,
}) => CampaignApplication(
  id: id,
  brandBriefId: 'b1',
  brandBriefRootId: 'root',
  brandBriefVersion: 1,
  vendorProfileId: 'v1',
  creatorProfileId: 'c1',
  state: state,
  submittedUtc: DateTime.utc(2026, 9, 21),
);

class _FakeRepo implements CreatorCampaignsRepository {
  _FakeRepo({
    this.proposalPages = const [],
    this.applyResult,
    this.withdrawResult,
    this.applications = const [],
  });

  List<CampaignPage<CampaignProposal>> proposalPages;
  Either<NetworkExceptions, CampaignApplication>? applyResult;
  Either<NetworkExceptions, CampaignApplication>? withdrawResult;
  List<CampaignApplication> applications;

  int listProposalCalls = 0;
  int listApplicationCalls = 0;
  final List<String?> cursorsSeen = [];

  @override
  Future<Either<NetworkExceptions, CampaignPage<CampaignProposal>>>
  listProposals({String? cursor, int pageSize = 25}) async {
    cursorsSeen.add(cursor);
    final page = proposalPages.isEmpty
        ? const CampaignPage<CampaignProposal>(
            items: [],
            nextCursor: null,
            hasMore: false,
          )
        : proposalPages[listProposalCalls.clamp(
            0,
            proposalPages.length - 1,
          )];
    listProposalCalls++;
    return right(page);
  }

  @override
  Future<Either<NetworkExceptions, CampaignProposal>> getProposal(
    String briefId,
  ) async => right(_proposal(briefId));

  @override
  Future<Either<NetworkExceptions, CampaignApplication>> apply({
    required String briefId,
    String? message,
  }) async => applyResult ?? right(_application());

  @override
  Future<Either<NetworkExceptions, CampaignPage<CampaignApplication>>>
  listApplications({
    List<CampaignApplicationState>? states,
    String? cursor,
    int pageSize = 25,
  }) async {
    listApplicationCalls++;
    return right(
      CampaignPage<CampaignApplication>(
        items: applications,
        nextCursor: null,
        hasMore: false,
      ),
    );
  }

  @override
  Future<Either<NetworkExceptions, CampaignApplication>> withdraw(
    String applicationId,
  ) async => withdrawResult ?? right(_application(state: null));
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('CampaignProposalsNotifier', () {
    test('loads the first page on construction', () async {
      final repo = _FakeRepo(
        proposalPages: [
          CampaignPage(
            items: [_proposal('b1')],
            nextCursor: 'c2',
            hasMore: true,
          ),
        ],
      );
      final notifier = CampaignProposalsNotifier(repo);
      await _settle();

      expect(repo.listProposalCalls, 1);
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (p, _, _, _) => p.length,
          orElse: () => -1,
        ),
        1,
      );
    });

    test('loadMore appends rather than replacing', () async {
      final repo = _FakeRepo(
        proposalPages: [
          CampaignPage(
            items: [_proposal('b1')],
            nextCursor: 'c2',
            hasMore: true,
          ),
          CampaignPage(
            items: [_proposal('b2')],
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );
      final notifier = CampaignProposalsNotifier(repo);
      await _settle();
      await notifier.loadMore();

      expect(repo.cursorsSeen, [null, 'c2']);
      expect(
        notifier.state.maybeWhen(
          loadSuccess: (p, _, _, _) => p.map((x) => x.id).toList(),
          orElse: () => <String>[],
        ),
        ['b1', 'b2'],
      );
    });

    test('loadMore does nothing when the server says there is no more', () async {
      final repo = _FakeRepo(
        proposalPages: [
          CampaignPage(
            items: [_proposal('b1')],
            nextCursor: null,
            hasMore: false,
          ),
        ],
      );
      final notifier = CampaignProposalsNotifier(repo);
      await _settle();
      await notifier.loadMore();

      expect(repo.listProposalCalls, 1);
    });
  });

  group('CampaignProposalDetailNotifier.apply', () {
    test('reports applied on success', () async {
      final notifier = CampaignProposalDetailNotifier(_FakeRepo(), 'b1');
      await _settle();

      final (outcome, application) = await notifier.apply(message: 'hi');
      expect(outcome, ApplyOutcome.applied);
      expect(application, isNotNull);
    });

    test('a 409 reports alreadyApplied, not applied', () async {
      // Reporting success here would leave the creator believing a second
      // application was sent when one slot per brief lineage is the rule.
      final repo = _FakeRepo(
        applyResult: left(_conflict409()),
      );
      final notifier = CampaignProposalDetailNotifier(repo, 'b1');
      await _settle();

      final (outcome, application) = await notifier.apply();
      expect(outcome, ApplyOutcome.alreadyApplied);
      expect(application, isNull);
    });

    test('a 404 reports unavailable, naming no cause', () async {
      final repo = _FakeRepo(
        applyResult: left(const NetworkExceptions.notFound()),
      );
      final notifier = CampaignProposalDetailNotifier(repo, 'b1');
      await _settle();

      final (outcome, _) = await notifier.apply();
      expect(outcome, ApplyOutcome.unavailable);
    });

    test('clears the applying flag after a failure so retry is possible', () async {
      final repo = _FakeRepo(
        applyResult: left(_conflict409()),
      );
      final notifier = CampaignProposalDetailNotifier(repo, 'b1');
      await _settle();
      await notifier.apply();

      expect(
        notifier.state.maybeWhen(
          loadSuccess: (_, isApplying) => isApplying,
          orElse: () => true,
        ),
        isFalse,
      );
    });
  });

  group('CampaignApplicationsNotifier.withdraw', () {
    test('reports withdrawn and reloads on success', () async {
      final repo = _FakeRepo(applications: [_application()]);
      final notifier = CampaignApplicationsNotifier(repo);
      await _settle();
      final before = repo.listApplicationCalls;

      final outcome = await notifier.withdraw('a1');
      await _settle();

      expect(outcome, WithdrawOutcome.withdrawn);
      expect(repo.listApplicationCalls, greaterThan(before));
    });

    test('a 409 reports alreadyDecided and still reloads', () async {
      // The vendor may have decided between the screen rendering and the tap.
      // Claiming a withdrawal would describe something that never happened,
      // and leaving the list untouched would keep showing a stale row.
      final repo = _FakeRepo(
        applications: [_application()],
        withdrawResult: left(_conflict409()),
      );
      final notifier = CampaignApplicationsNotifier(repo);
      await _settle();
      final before = repo.listApplicationCalls;

      final outcome = await notifier.withdraw('a1');
      await _settle();

      expect(outcome, WithdrawOutcome.alreadyDecided);
      expect(repo.listApplicationCalls, greaterThan(before));
    });

    test('a transport failure reports failed and does not reload', () async {
      final repo = _FakeRepo(
        applications: [_application()],
        withdrawResult: left(const NetworkExceptions.noInternetConnection()),
      );
      final notifier = CampaignApplicationsNotifier(repo);
      await _settle();
      final before = repo.listApplicationCalls;

      final outcome = await notifier.withdraw('a1');
      await _settle();

      expect(outcome, WithdrawOutcome.failed);
      expect(repo.listApplicationCalls, before);
    });
  });
}
