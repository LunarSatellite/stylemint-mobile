import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/data/datasources/agent_commerce_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_commerce_copy.dart';

final DateTime _now = DateTime.utc(2026, 9, 19, 12);

void main() {
  group('every limit the backend enforces is expressible here', () {
    test('the four scopes carry the backend bit values', () {
      expect(AgentMandateScope.catalogRead.bit, 1);
      expect(AgentMandateScope.cartWrite.bit, 2);
      expect(AgentMandateScope.checkoutPrepare.bit, 4);
      expect(AgentMandateScope.orderSubmitAfterCustomerConfirmation.bit, 8);
    });

    test('a scope set serialises to the flags bitmask', () {
      const set = AgentScopeSet(<AgentMandateScope>{
        AgentMandateScope.catalogRead,
        AgentMandateScope.checkoutPrepare,
      });
      expect(set.bits, 5);
    });

    test('the client ceilings match AgentPurchaseMandate', () {
      expect(kAgentMandateMaxLifetimeDays, 90);
      expect(kAgentMandateMaxNameLength, 120);
      expect(kAgentMandateMaxOrderAmount, 100000000);
      expect(kAgentMandateMaxAllowedProducts, 500);
    });
  });

  group('an expiry beyond 90 days is refused client-side', () {
    test('91 days is refused', () {
      expect(
        validateMandateExpiry(
          expiresUtc: _now.add(const Duration(days: 91)),
          nowUtc: _now,
        ),
        MandateExpiryProblem.beyondMaxLifetime,
      );
    });

    test('exactly 90 days is allowed', () {
      expect(
        validateMandateExpiry(
          expiresUtc: _now.add(const Duration(days: 90)),
          nowUtc: _now,
        ),
        isNull,
      );
    });

    test('a date in the past is refused', () {
      expect(
        validateMandateExpiry(
          expiresUtc: _now.subtract(const Duration(minutes: 1)),
          nowUtc: _now,
        ),
        MandateExpiryProblem.notInFuture,
      );
    });

    test('the refusal names the limit and the latest allowed date', () {
      final message = AgentCommerceCopy.expiryProblem(
        MandateExpiryProblem.beyondMaxLifetime,
        _now,
      );
      expect(message, contains('90 days'));
      // 19 Sep 2026 + 90 days = 18 Dec 2026, in the customer's own words.
      expect(message, contains('18 Dec 2026'));
    });
  });

  group('the spend cap and the currency are checked before the request', () {
    test('an empty cap is a problem, not an unlimited mandate', () {
      expect(validateMandateCap(''), MandateCapProblem.missing);
      expect(
        AgentCommerceCopy.capProblem(MandateCapProblem.missing),
        contains('no unlimited option'),
      );
    });

    test('zero, gibberish and above-ceiling are each named', () {
      expect(validateMandateCap('0'), MandateCapProblem.notPositive);
      expect(validateMandateCap('lots'), MandateCapProblem.notANumber);
      expect(
        validateMandateCap('100000001'),
        MandateCapProblem.aboveCeiling,
      );
      expect(validateMandateCap('25,000.50'), isNull);
    });

    test('a currency is three letters or it is refused', () {
      expect(validateMandateCurrency('NPR'), isNull);
      expect(validateMandateCurrency('NP'), MandateCurrencyProblem.wrongLength);
      expect(validateMandateCurrency('N3R'), MandateCurrencyProblem.notLetters);
    });
  });

  group('unknown future scopes degrade gracefully', () {
    test('a bit this build cannot name is kept, not dropped', () {
      final set = AgentScopeSet.fromBits(1 | 64);
      expect(set.has(AgentMandateScope.catalogRead), isTrue);
      expect(set.hasUnrecognised, isTrue);
      expect(set.unrecognisedCount, 1);
      expect(
        AgentCommerceCopy.unrecognisedScopes(set.unrecognisedCount),
        contains('does not recognise'),
      );
    });

    test('an unknown bit is never echoed back when issuing', () {
      // The app only ever asks for permissions it can name.
      expect(AgentScopeSet.fromBits(1 | 64).bits, 1);
    });

    test('a string flags list is read, and an unknown name raises a bit', () {
      expect(parseScopeBits('CatalogRead, CartWrite'), 3);
      expect(parseScopeBits(6), 6);
      expect(
        AgentScopeSet.fromBits(
          parseScopeBits('CatalogRead, Teleport'),
        ).hasUnrecognised,
        isTrue,
      );
    });
  });

  group('unknown future proposal statuses degrade gracefully', () {
    test('an unmapped wire value reads as unknown, never as pending', () {
      final status = AgentProposalStatus.fromWire(99);
      expect(status, AgentProposalStatus.unknown);
      expect(status.awaitsCustomer, isFalse);
      expect(
        AgentCommerceCopy.proposalStatusLabel(status, rawStatus: 99),
        contains('99'),
      );
    });

    test('a proposal with an unknown status is not actionable', () {
      final proposal = _proposal(status: AgentProposalStatus.unknown);
      expect(proposal.actionableAt(_now), isFalse);
    });

    test('an expired pending proposal is not actionable either', () {
      final proposal = _proposal(
        expiresUtc: _now.subtract(const Duration(minutes: 1)),
      );
      expect(proposal.expiredAt(_now), isTrue);
      expect(proposal.actionableAt(_now), isFalse);
    });
  });

  group('parsing', () {
    test('a mandate row maps every limit', () {
      final mandate = parseAgentMandate(<String, dynamic>{
        'id': 'm-1',
        'agentName': 'Marlowe',
        'scopes': 3,
        'maxOrderAmount': 25000,
        'currency': 'npr',
        'allowedProductIds': ['p-1', 'p-2'],
        'expiresUtc': '2026-10-19T12:00:00Z',
        'createdUtc': '2026-09-19T12:00:00Z',
      });
      expect(mandate.agentName, 'Marlowe');
      expect(mandate.currency, 'NPR');
      expect(mandate.maxOrderAmount, 25000);
      expect(mandate.allowedProductIds, hasLength(2));
      expect(mandate.isProductLimited, isTrue);
      expect(mandate.effectiveStateAt(_now), AgentMandateState.active);
    });

    test('a revoked mandate reads as revoked, not merely expired', () {
      final mandate = parseAgentMandate(<String, dynamic>{
        'id': 'm-2',
        'expiresUtc': '2026-10-19T12:00:00Z',
        'createdUtc': '2026-09-19T12:00:00Z',
        'revokedUtc': '2026-09-19T13:00:00Z',
      });
      expect(mandate.effectiveStateAt(_now), AgentMandateState.revoked);
    });

    test('only the create response yields a credential', () {
      final issued = parseIssuedAgentMandate(<String, dynamic>{
        'mandate': <String, dynamic>{
          'id': 'm-3',
          'agentName': 'Marlowe',
          'expiresUtc': '2026-10-19T12:00:00Z',
          'createdUtc': '2026-09-19T12:00:00Z',
        },
        'agentToken': 'sma_abc123',
      });
      expect(issued.credential, 'sma_abc123');
      // Nothing on the mandate itself can carry it.
      expect(
        issued.mandate.toString(),
        isNot(contains('sma_')),
        reason: 'AgentMandate has no credential field',
      );
    });

    test('an activity row with no `allowed` flag reads as a refusal', () {
      final entry = parseAgentActivityEntry(<String, dynamic>{
        'id': 'a-1',
        'agentName': 'Marlowe',
        'action': 'cart.add',
        'recordedUtc': '2026-09-19T12:00:00Z',
      });
      expect(entry.allowed, isFalse);
    });

    test('a proposal line falls back to unit price times quantity', () {
      final line = parseAgentProposalLine(<String, dynamic>{
        'productId': 'p-1',
        'productTitleSnapshot': 'Linen shirt',
        'quantity': 3,
        'unitPriceAmount': 1000,
      }, 'NPR');
      expect(line.lineSubtotalAmount, 3000);
      expect(line.currency, 'NPR');
    });
  });

  group('money is written out, never guessed at', () {
    test('the pinned code is printed with the amount', () {
      expect(AgentCommerceCopy.money(1234567.5, 'npr'), 'NPR 1,234,567.50');
      expect(AgentCommerceCopy.money(0.5, 'USD'), 'USD 0.50');
    });
  });

  group("refusals are explained in the customer's terms", () {
    test('every external-agent error code has a sentence', () {
      const codes = <String>[
        'external_agent.credential_missing',
        'external_agent.credential_malformed',
        'external_agent.credential_unknown',
        'external_agent.credential_revoked',
        'external_agent.credential_expired',
        'external_agent.credential_ambiguous',
        'external_agent.directory_unreadable',
        'external_agent.scope_not_granted',
        'external_agent.product_outside_mandate',
        'external_agent.amount_over_limit',
        'external_agent.currency_mismatch',
        'external_agent.identity_caller_supplied',
        'external_agent.human_approval_required',
        'external_agent.mandate_withdrawn_in_flight',
      ];
      for (final code in codes) {
        final reason = AgentCommerceCopy.refusalReason(code);
        expect(reason, isNotEmpty, reason: code);
        expect(reason, isNot(contains('external_agent')), reason: code);
      }
    });

    test('an unknown code still says it was refused', () {
      expect(
        AgentCommerceCopy.refusalReason('external_agent.some_future_rule'),
        contains('refused'),
      );
    });
  });

  test('the boundary the customer is told about matches the backend', () {
    final text = AgentCommerceCopy.neverCan.join(' ').toLowerCase();
    expect(text, contains('never set a price'));
    expect(text, contains('never reserve stock'));
    expect(text, contains('never move money'));
    expect(text, contains('never complete a purchase'));
    expect(
      AgentCommerceCopy.revocationPromise.toLowerCase(),
      contains('already running'),
    );
  });
}

AgentProposal _proposal({
  AgentProposalStatus status = AgentProposalStatus.pendingCustomerConfirmation,
  DateTime? expiresUtc,
}) => AgentProposal(
  id: 'pr-1',
  mandateId: 'm-1',
  lines: const <AgentProposalLine>[],
  quotedTotal: 100,
  currency: 'NPR',
  status: status,
  expiresUtc: expiresUtc ?? _now.add(const Duration(minutes: 20)),
  createdUtc: _now,
);
