import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/data/models/clienteling_dtos.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';

/// The payloads below are shaped exactly like the API's view models
/// (`ClientelingVms.cs`): camelCase keys and integer enums, because the API
/// registers no `JsonStringEnumConverter`.
void main() {
  group('ClientAssignmentVm', () {
    test('maps a full assignment page', () {
      final page = ClientAssignmentPageDto.fromJson({
        'items': [
          {
            'assignmentId': '11111111-1111-1111-1111-111111111111',
            'vendorAccountId': '22222222-2222-2222-2222-222222222222',
            'associateAccountId': '33333333-3333-3333-3333-333333333333',
            'customerAccountId': '44444444-4444-4444-4444-444444444444',
            'customerDisplayName': 'Aarati Shrestha',
            'customerHandle': 'aarati',
            'status': 1,
            'note': 'Winter coat fitting',
            'grantedUtc': '2026-09-01T10:00:00Z',
            'revokedUtc': null,
          },
        ],
        'totalCount': 1,
        'nextCursor': 'cursor-2',
        'previousCursor': null,
        'pageSize': 20,
      });

      expect(page.items, hasLength(1));
      expect(page.nextCursor, 'cursor-2');
      final a = page.items.single;
      expect(a.customerDisplayName, 'Aarati Shrestha');
      expect(a.customerHandle, 'aarati');
      expect(a.status, ClientAssignmentStatus.active);
      expect(a.grantedUtc, DateTime.utc(2026, 9, 1, 10));
      expect(a.revokedUtc, isNull);
    });

    test('a blank display name reads as absent, not as an empty name', () {
      final a = clientAssignmentFromJson({
        'assignmentId': 'a1',
        'customerAccountId': '44444444-4444-4444-4444-444444444444',
        'customerDisplayName': '',
        'customerHandle': null,
        'status': 2,
      });

      expect(a.customerDisplayName, isNull);
      expect(a.customerHandle, isNull);
      expect(a.status, ClientAssignmentStatus.revoked);
      expect(a.grantedUtc, isNull, reason: 'no timestamp sent, none invented');
    });

    test('an unrecognised status never becomes active', () {
      expect(
        clientAssignmentFromJson({'status': 99}).status,
        ClientAssignmentStatus.unknown,
      );
    });
  });

  group('ClientBriefVm', () {
    test('maps contactability, orders and the withheld list', () {
      final brief = clientBriefFromJson({
        'assignmentId': 'a1',
        'vendorAccountId': 'v1',
        'associateAccountId': 's1',
        'customerAccountId': 'c1',
        'customerDisplayName': 'Aarati Shrestha',
        'customerHandle': null,
        'customerAccountActive': true,
        'contactability': [
          {
            'channel': 1,
            'allowed': true,
            'decision': 1,
            'reason': 'Consented to marketing email.',
          },
          {
            'channel': 2,
            'allowed': false,
            'decision': 2,
            'reason': 'No consent to be contacted by SMS.',
          },
        ],
        'recentOrdersWithThisVendor': [
          {
            'orderId': 'o1',
            'orderNumber': 'SM-1042',
            'vendorSubOrderStatus': 'Delivered',
            'placedUtc': '2026-08-20T09:30:00Z',
            'itemCount': 3,
          },
        ],
        'withheld': ['email address', 'order totals, prices and discounts'],
      });

      expect(brief.customerAccountActive, isTrue);
      expect(brief.contactability, hasLength(2));
      expect(
        brief.contactability.first.channel,
        ClientelingOutreachChannel.email,
      );
      expect(brief.contactability.first.allowed, isTrue);
      expect(
        brief.contactability.last.decision,
        ClientelingOutreachDecision.blockedNoConsent,
      );
      expect(brief.contactability.last.reason, contains('No consent'));

      final order = brief.recentOrdersWithThisVendor.single;
      expect(order.orderNumber, 'SM-1042');
      expect(order.vendorSubOrderStatus, 'Delivered');
      expect(order.itemCount, 3);
      expect(order.placedUtc, DateTime.utc(2026, 8, 20, 9, 30));

      expect(brief.withheld, contains('email address'));
    });

    test('an absent item count stays null rather than becoming zero', () {
      final order = clientOrderSummaryFromJson({
        'orderId': 'o1',
        'orderNumber': 'SM-1042',
      });
      expect(order.itemCount, isNull);
      expect(order.placedUtc, isNull);
      expect(order.vendorSubOrderStatus, isNull);
    });

    test('missing collections read as empty lists, not as nulls', () {
      final brief = clientBriefFromJson({'customerAccountId': 'c1'});
      expect(brief.contactability, isEmpty);
      expect(brief.recentOrdersWithThisVendor, isEmpty);
      expect(brief.withheld, isEmpty);
      expect(brief.customerAccountActive, isFalse);
    });
  });

  group('AssistedOutcomeVm', () {
    test('a claim is not credit', () {
      final outcome = assistedOutcomeFromJson({
        'outcomeId': 'x1',
        'sessionId': 's1',
        'vendorAccountId': 'v1',
        'associateAccountId': 'a1',
        'customerAccountId': 'c1',
        'orderId': 'o1',
        'orderNumber': 'SM-1042',
        'orderPlacedUtc': '2026-08-20T09:30:00Z',
        'status': 1,
        'note': 'Helped choose the size.',
        'claimedUtc': '2026-08-20T10:00:00Z',
        'confirmedByAccountId': null,
        'decidedUtc': null,
        'isCredited': false,
      });

      expect(outcome.status, AssistedOutcomeStatus.claimed);
      expect(outcome.isCredited, isFalse);
      expect(outcome.awaitsCustomerAnswer, isTrue);
      expect(outcome.decidedUtc, isNull);
    });

    test('a customer-confirmed outcome is credit', () {
      final outcome = assistedOutcomeFromJson({
        'outcomeId': 'x1',
        'status': 2,
        'confirmedByAccountId': 'c1',
        'decidedUtc': '2026-08-21T08:00:00Z',
        'isCredited': true,
      });

      expect(outcome.status, AssistedOutcomeStatus.confirmed);
      expect(outcome.isCredited, isTrue);
      expect(outcome.awaitsCustomerAnswer, isFalse);
    });
  });

  group('OutreachAttemptVm', () {
    test('a blocked attempt is a recorded attempt, not a failure', () {
      final attempt = outreachAttemptFromJson({
        'outreachId': 'r1',
        'customerAccountId': 'c1',
        'sessionId': 's1',
        'channel': 2,
        'decision': 3,
        'sent': false,
        'subject': 'Your coat is in',
        'decisionReason': 'Quiet hours in the customer timezone.',
        'requestedUtc': '2026-09-02T21:00:00Z',
      });

      expect(attempt.channel, ClientelingOutreachChannel.sms);
      expect(attempt.decision, ClientelingOutreachDecision.blockedQuietHours);
      expect(attempt.sent, isFalse);
      expect(attempt.decisionReason, contains('Quiet hours'));
    });
  });

  group('ClientelingActivityVm', () {
    test('maps a bare activity array', () {
      final rows = clientelingActivityListFromJson([
        {
          'activityId': 'g1',
          'vendorAccountId': 'v1',
          'associateAccountId': 'a1',
          'customerAccountId': 'c1',
          'sessionId': null,
          'type': 1,
          'detail': null,
          'subjectId': null,
          'occurredUtc': '2026-09-02T12:00:00Z',
        },
        {'activityId': 'g2', 'type': 8},
      ]);

      expect(rows, hasLength(2));
      expect(rows.first.type, ClientelingActivityType.briefViewed);
      expect(rows.first.sessionId, isNull);
      expect(rows.last.type, ClientelingActivityType.accessRefused);
      expect(rows.last.occurredUtc, isNull);
    });

    test('a non-list body maps to no rows rather than throwing', () {
      expect(clientelingActivityListFromJson(null), isEmpty);
      expect(assistedOutcomeListFromJson('not a list'), isEmpty);
    });
  });

  group('enum names are tolerated if the API ever adds a string converter', () {
    test('named values map to the same members', () {
      expect(
        outreachChannelFromJson('Sms'),
        ClientelingOutreachChannel.sms,
      );
      expect(
        outreachDecisionFromJson('BlockedNoConsent'),
        ClientelingOutreachDecision.blockedNoConsent,
      );
      expect(
        assistedOutcomeStatusFromJson('Confirmed'),
        AssistedOutcomeStatus.confirmed,
      );
      expect(
        clientelingActivityTypeFromJson('OutcomeRejected'),
        ClientelingActivityType.outcomeRejected,
      );
    });
  });

  group('outreachChannelToJson', () {
    test('sends the integer the API expects', () {
      expect(outreachChannelToJson(ClientelingOutreachChannel.email), 1);
      expect(outreachChannelToJson(ClientelingOutreachChannel.sms), 2);
    });
  });
}
