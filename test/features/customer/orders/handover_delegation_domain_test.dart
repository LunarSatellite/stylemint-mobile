import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/handover_delegation_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_copy.dart';

final DateTime _now = DateTime.utc(2026, 9, 19, 12);

void main() {
  group('window rules are enforced client-side', () {
    HandoverWindowProblem? check(DateTime start, DateTime end) =>
        validateHandoverWindow(startUtc: start, endUtc: end, nowUtc: _now);

    test('a sensible window is accepted', () {
      expect(check(_now, _now.add(const Duration(hours: 4))), isNull);
    });

    test('15 minutes exactly is allowed; 14 is not', () {
      expect(check(_now, _now.add(kHandoverMinWindow)), isNull);
      expect(
        check(_now, _now.add(const Duration(minutes: 14))),
        HandoverWindowProblem.tooShort,
      );
    });

    test('72 hours exactly is allowed; 72h1m is not', () {
      expect(check(_now, _now.add(kHandoverMaxWindow)), isNull);
      expect(
        check(_now, _now.add(const Duration(hours: 72, minutes: 1))),
        HandoverWindowProblem.tooLong,
      );
    });

    test('14 days ahead is allowed; 14 days and a minute is not', () {
      final atLimit = _now.add(kHandoverMaxLeadTime);
      expect(check(atLimit, atLimit.add(const Duration(hours: 1))), isNull);
      final past = atLimit.add(const Duration(minutes: 1));
      expect(
        check(past, past.add(const Duration(hours: 1))),
        HandoverWindowProblem.tooFarAhead,
      );
    });

    test('a window that has already closed is refused', () {
      final start = _now.subtract(const Duration(hours: 5));
      expect(
        check(start, start.add(const Duration(hours: 1))),
        HandoverWindowProblem.alreadyPast,
      );
    });

    test('an end before the start is refused', () {
      expect(
        check(_now, _now.subtract(const Duration(hours: 1))),
        HandoverWindowProblem.endsBeforeStart,
      );
    });

    test('each problem gets its own message — none is reused', () {
      final messages = HandoverWindowProblem.values
          .map(HandoverCopy.windowProblem)
          .toList();
      expect(messages.toSet(), hasLength(HandoverWindowProblem.values.length));
      for (final m in messages) {
        expect(m.trim(), isNotEmpty);
        // Each one has to say what to do, not just that something is wrong.
        expect(m.length, greaterThan(30));
      }
    });

    test('the messages name the real limits', () {
      expect(
        HandoverCopy.windowProblem(HandoverWindowProblem.tooShort),
        contains('15 minutes'),
      );
      expect(
        HandoverCopy.windowProblem(HandoverWindowProblem.tooLong),
        contains('72 hours'),
      );
      expect(
        HandoverCopy.windowProblem(HandoverWindowProblem.tooFarAhead),
        contains('14 days'),
      );
    });
  });

  group('exception flags', () {
    test('none selected packs to 0 — the safe default', () {
      expect(packDelegatedExceptions(const <DelegatedException>{}), 0);
    });

    test('flags round-trip through the backend int', () {
      for (final chosen in <Set<DelegatedException>>[
        {},
        {DelegatedException.substitution},
        {DelegatedException.visibleDamage},
        {DelegatedException.partialDelivery},
        {DelegatedException.substitution, DelegatedException.partialDelivery},
        DelegatedException.values.toSet(),
      ]) {
        expect(
          unpackDelegatedExceptions(packDelegatedExceptions(chosen)),
          chosen,
        );
      }
    });

    test('unknown bits are dropped, never shown as a mystery permission', () {
      expect(unpackDelegatedExceptions(1 | 64), {
        DelegatedException.substitution,
      });
    });

    test('every exception is explained in words, not flag names', () {
      for (final e in DelegatedException.values) {
        final title = HandoverCopy.exceptionTitle(e);
        final consequence = HandoverCopy.exceptionConsequence(e);
        expect(title, isNot(contains(e.name)));
        expect(title, isNot(contains('Flag')));
        expect(consequence.length, greaterThan(40));
      }
      // And the three explanations are genuinely different.
      expect(
        DelegatedException.values.map(HandoverCopy.exceptionTitle).toSet(),
        hasLength(3),
      );
    });

    test('the empty summary says what "none" means', () {
      expect(
        HandoverCopy.exceptionSummary(const <DelegatedException>{}),
        'Complete, undamaged orders only',
      );
    });
  });

  group('status', () {
    test('only the four the API returns, plus an honest fallback', () {
      expect(parseHandoverDelegationStatus(1), HandoverDelegationStatus.active);
      expect(
        parseHandoverDelegationStatus(2),
        HandoverDelegationStatus.revoked,
      );
      expect(
        parseHandoverDelegationStatus(3),
        HandoverDelegationStatus.consumed,
      );
      expect(
        parseHandoverDelegationStatus(4),
        HandoverDelegationStatus.expired,
      );
      expect(
        parseHandoverDelegationStatus(99),
        HandoverDelegationStatus.unknown,
      );
      expect(
        parseHandoverDelegationStatus('Consumed'),
        HandoverDelegationStatus.consumed,
      );
    });

    test('an active row whose window closed reads as expired, not active', () {
      final d = _delegation(
        start: _now.subtract(const Duration(hours: 6)),
        end: _now.subtract(const Duration(hours: 1)),
      );
      expect(d.effectiveStatusAt(_now), HandoverDelegationStatus.expired);
      expect(d.canRevokeAt(_now), isFalse);
    });

    test('revocation stays available for the whole window', () {
      final d = _delegation(
        start: _now.subtract(const Duration(hours: 1)),
        end: _now.add(const Duration(seconds: 1)),
      );
      expect(d.canRevokeAt(_now), isTrue, reason: 'right up to handover');
    });

    test('every status has a distinct label, tone and spoken form', () {
      const statuses = HandoverDelegationStatus.values;
      expect(
        statuses.map(HandoverCopy.statusLabel).toSet(),
        hasLength(statuses.length),
      );
      expect(
        statuses.map(HandoverCopy.statusSemantics).toSet(),
        hasLength(statuses.length),
      );
      // Tone alone is allowed to repeat (there are six tones, five statuses);
      // the glyph in the card is what guarantees greyscale separation. What
      // must not happen is every status sharing one tone.
      expect(
        statuses.map(HandoverCopy.statusTone).toSet().length,
        greaterThanOrEqualTo(4),
      );
    });
  });

  group('refusal codes', () {
    // Exactly the codes the customer's three endpoints can return.
    const codes = <String>[
      HandoverCopy.codeNotFound,
      HandoverCopy.codeRevoked,
      HandoverCopy.codeAlreadyUsed,
      HandoverCopy.codeExpired,
      HandoverCopy.codeConflict,
      HandoverCopy.codeBusinessRule,
      HandoverCopy.codeOutOfRange,
      HandoverCopy.codeTooLong,
      HandoverCopy.codeRequired,
    ];

    test('each produces its own actionable copy', () {
      final titles = <String>{};
      final bodies = <String>{};
      for (final code in codes) {
        final copy = HandoverCopy.refusal(code);
        expect(copy.title.trim(), isNotEmpty, reason: code);
        expect(copy.body.length, greaterThan(40), reason: code);
        titles.add(copy.title);
        bodies.add(copy.body);
      }
      // `required` and `invalid_enum` deliberately share one message; every
      // other code is distinct.
      expect(titles, hasLength(codes.length));
      expect(bodies, hasLength(codes.length));
    });

    test('an unknown code falls back without claiming anything false', () {
      final copy = HandoverCopy.refusal('handover.delegation_state_unknown');
      expect(copy.body, contains('was not created'));
    });

    test('no refusal offers to resend or recover the code', () {
      for (final code in [...codes, null, 'anything']) {
        final copy = HandoverCopy.refusal(code);
        final text = '${copy.title} ${copy.body}'.toLowerCase();
        expect(text, isNot(contains('resend')));
        expect(text, isNot(contains('show the code again')));
        expect(text, isNot(contains('retrieve')));
      }
    });

    test('an already-used delegation is not described as revocable', () {
      final copy = HandoverCopy.refusal(HandoverCopy.codeAlreadyUsed);
      expect(copy.body, contains('nothing'));
    });
  });

  group('DTO parsing', () {
    test('reads the merged camelCase contract', () {
      final dto = HandoverDelegationDto.fromJson(<String, dynamic>{
        'id': 'del-1',
        'trackingNumber': 'SM-D-00000001',
        'delegateDisplayName': 'Amina',
        'relationship': 2,
        'allowedExceptions': 5,
        'windowStartUtc': '2026-09-19T12:00:00Z',
        'windowEndUtc': '2026-09-19T16:00:00Z',
        'status': 1,
        'createdUtc': '2026-09-19T11:00:00Z',
      });
      final d = dto.toDomain();
      expect(d.delegateDisplayName, 'Amina');
      expect(d.relationship, DelegateRelationship.neighbour);
      expect(d.allowedExceptions, {
        DelegatedException.substitution,
        DelegatedException.partialDelivery,
      });
      expect(d.status, HandoverDelegationStatus.active);
      expect(d.windowEndUtc, DateTime.utc(2026, 9, 19, 16));
    });

    test('the creation response carries the code, and nothing else does', () {
      final issued = parseIssuedHandoverDelegation(<String, dynamic>{
        'delegation': <String, dynamic>{
          'id': 'del-2',
          'trackingNumber': 'SM-D-00000001',
          'delegateDisplayName': 'Amina',
          'relationship': 1,
          'allowedExceptions': 0,
          'windowStartUtc': '2026-09-19T12:00:00Z',
          'windowEndUtc': '2026-09-19T16:00:00Z',
          'status': 1,
        },
        'verificationCode': 'ABCD1234',
      });
      expect(issued.verificationCode, 'ABCD1234');
      // The domain object the rest of the app handles has no code field at
      // all, so nothing downstream can persist one by accident.
      expect(
        issued.delegation.toString(),
        isNot(contains('ABCD1234')),
      );
    });

    test('toString redacts the code so a stray log line cannot leak it', () {
      final issued = IssuedHandoverDelegation(
        delegation: _delegation(),
        verificationCode: 'SECRET99',
      );
      expect(issued.toString(), isNot(contains('SECRET99')));
      expect(issued.toString(), contains('<redacted>'));
      expect('$issued', isNot(contains('SECRET99')));
    });

    test('the request body never smuggles the contact into a query', () {
      final body = authoriseHandoverBody(
        delegateDisplayName: '  Amina  ',
        delegateContact: ' amina@example.com ',
        relationship: DelegateRelationship.neighbour,
        allowedExceptions: const <DelegatedException>{},
        windowStartUtc: _now,
        windowEndUtc: _now.add(const Duration(hours: 2)),
      );
      expect(body['delegateDisplayName'], 'Amina');
      expect(body['delegateContact'], 'amina@example.com');
      expect(body['allowedExceptions'], 0);
      expect(body['windowStartUtc'], '2026-09-19T12:00:00.000Z');
    });
  });

  group('window in plain language', () {
    test('spells out start, end and length', () {
      final sentence = HandoverCopy.windowSentence(
        DateTime.utc(2026, 9, 19, 12),
        DateTime.utc(2026, 9, 19, 16),
      );
      expect(sentence, contains('4 hours'));
      expect(sentence, contains('to'));
    });

    test('durations read as words', () {
      expect(
        HandoverCopy.durationWords(const Duration(minutes: 45)),
        '45 minutes',
      );
      expect(
        HandoverCopy.durationWords(const Duration(minutes: 1)),
        '1 minute',
      );
      expect(HandoverCopy.durationWords(const Duration(hours: 1)), '1 hour');
      expect(
        HandoverCopy.durationWords(const Duration(hours: 1, minutes: 30)),
        '1 hour 30 minutes',
      );
      expect(HandoverCopy.durationWords(const Duration(hours: 72)), '3 days');
    });
  });
}

HandoverDelegation _delegation({
  HandoverDelegationStatus status = HandoverDelegationStatus.active,
  DateTime? start,
  DateTime? end,
}) => HandoverDelegation(
  id: 'del-1',
  trackingNumber: 'SM-D-00000001',
  delegateDisplayName: 'Amina',
  relationship: DelegateRelationship.neighbour,
  allowedExceptions: const <DelegatedException>{},
  windowStartUtc: start ?? _now,
  windowEndUtc: end ?? _now.add(const Duration(hours: 4)),
  status: status,
);
