import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/data/models/campaign_application_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/data/models/reel_approval_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';

void main() {
  group('CampaignApplicationState', () {
    test('wire values match the backend enum', () {
      expect(CampaignApplicationState.pending.wire, 1);
      expect(CampaignApplicationState.withdrawn.wire, 2);
      expect(CampaignApplicationState.accepted.wire, 3);
      expect(CampaignApplicationState.declined.wire, 4);
    });

    test('pending and accepted are the live pair', () {
      expect(CampaignApplicationState.pending.isLive, isTrue);
      expect(CampaignApplicationState.accepted.isLive, isTrue);
      expect(CampaignApplicationState.withdrawn.isLive, isFalse);
      expect(CampaignApplicationState.declined.isLive, isFalse);
    });

    test('only a pending application can be withdrawn', () {
      expect(CampaignApplicationState.pending.canWithdraw, isTrue);
      for (final s in CampaignApplicationState.values.where(
        (s) => s != CampaignApplicationState.pending,
      )) {
        expect(s.canWithdraw, isFalse, reason: '$s must not offer withdraw');
      }
    });

    test('an unknown wire value maps to null, not to pending', () {
      // Defaulting to pending would tell a creator their application is live
      // when the server may already have settled it.
      expect(CampaignApplicationState.tryParseWire(99), isNull);
      expect(CampaignApplicationState.tryParseWire(null), isNull);
    });

    test('an application in an unknown state offers no withdraw', () {
      final application = CampaignApplicationDto.fromJson({
        'id': 'a1',
        'state': 99,
        'submittedUtc': '2026-09-21T10:00:00Z',
      }).toDomain();

      expect(application.state, isNull);
      expect(application.canWithdraw, isFalse);
    });

    test('a decline with no reason keeps the reason null', () {
      final application = CampaignApplicationDto.fromJson({
        'id': 'a1',
        'state': 4,
        'submittedUtc': '2026-09-21T10:00:00Z',
      }).toDomain();

      expect(application.state, CampaignApplicationState.declined);
      expect(application.declineReason, isNull);
    });
  });

  group('ReelApprovalState', () {
    test('wire values match the backend enum', () {
      expect(ReelApprovalState.pending.wire, 1);
      expect(ReelApprovalState.approved.wire, 2);
      expect(ReelApprovalState.rejected.wire, 3);
      expect(ReelApprovalState.expired.wire, 4);
    });

    test('expired is distinct from rejected', () {
      // A brand that said nothing did not say no. Collapsing the two would
      // tell a creator they were turned down when they were only ignored.
      expect(ReelApprovalState.expired, isNot(ReelApprovalState.rejected));
      expect(ReelApprovalState.tryParseWire(4), ReelApprovalState.expired);
      expect(ReelApprovalState.tryParseWire(3), ReelApprovalState.rejected);
    });

    test('an unknown wire value maps to null and is not pending', () {
      expect(ReelApprovalState.tryParseWire(7), isNull);

      final request = ReelApprovalRequestDto.fromJson({
        'id': 'r1',
        'state': 7,
        'submittedUtc': '2026-09-21T10:00:00Z',
      }).toDomain();

      expect(request.state, isNull);
      expect(request.isPending, isFalse);
    });

    test('round defaults to 1 and marks the first submission', () {
      final first = ReelApprovalRequestDto.fromJson({
        'id': 'r1',
        'submittedUtc': '2026-09-21T10:00:00Z',
      }).toDomain();
      final third = ReelApprovalRequestDto.fromJson({
        'id': 'r2',
        'round': 3,
        'submittedUtc': '2026-09-21T10:00:00Z',
      }).toDomain();

      expect(first.round, 1);
      expect(first.isFirstRound, isTrue);
      expect(third.isFirstRound, isFalse);
    });

    test('a rejection with no reason keeps the reason null', () {
      final request = ReelApprovalRequestDto.fromJson({
        'id': 'r1',
        'state': 3,
        'rejectionReason': '   ',
        'submittedUtc': '2026-09-21T10:00:00Z',
      }).toDomain();

      expect(request.state, ReelApprovalState.rejected);
      expect(request.rejectionReason, isNull);
    });
  });
}
