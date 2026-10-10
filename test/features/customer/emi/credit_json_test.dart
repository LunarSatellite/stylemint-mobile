import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/credit_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';

import 'credit_fakes.dart';

void main() {
  group('plan options', () {
    test('reads the menu exactly as the server sends it', () {
      final options = readPlanOptions(planOptionsWire);

      expect(options.price.amount, 60000);
      expect(options.options.map((o) => o.kind), [
        PlanKind.instalment,
        PlanKind.prepay,
      ]);
      final emi = options.of(PlanKind.instalment)!;
      expect(emi.guarantor, PlanGuarantor.vendor);
      expect(emi.tenures, [3, 6]);
      expect(emi.minDownPaymentPercent, 20);
      expect(emi.fromMonthly.amount, 8000);
      expect(emi.requiresVerifiedIdentity, isTrue);
      final prepay = options.of(PlanKind.prepay)!;
      expect(prepay.goodsBeforePaidInFull, isFalse);
      expect(prepay.requiresVerifiedIdentity, isFalse);
      expect(prepay.guarantor, PlanGuarantor.none);
    });

    test('an option this build cannot name is left off, not guessed', () {
      final options = readPlanOptions({
        ...planOptionsWire,
        'options': [
          {...(planOptionsWire['options']! as List).first as Map, 'kind': 99},
        ],
      });

      expect(options.options, isEmpty);
    });

    test('enums read from names as well as numbers', () {
      expect(PlanKind.fromWire('PayLater'), PlanKind.payLater);
      expect(AgreementStatus.fromWire('pending_approval'),
          AgreementStatus.pendingApproval);
      expect(PlanGuarantor.fromWire(2), PlanGuarantor.platform);
      expect(RiskBand.fromWire('2'), RiskBand.b);
    });
  });

  group('quote', () {
    test('reads every figure and the token', () {
      final q = readCreditQuote(quoteWire);

      expect(q.token, 'v1.payload.signature');
      expect(q.kind, PlanKind.instalment);
      expect(q.downPayment.amount, 12000);
      expect(q.financed.amount, 48000);
      expect(q.totalPayable.amount, 60000);
      expect(q.schedule.map((l) => l.amount.amount), [16000, 16000, 16000]);
      expect(q.expiresAt, DateTime.utc(2026, 3, 2, 6, 15));
      expect(q.isExpiredAt(DateTime.utc(2026, 3, 2, 6, 14)), isFalse);
      expect(q.isExpiredAt(DateTime.utc(2026, 3, 2, 6, 15)), isTrue);
    });

    test('a quote without a token or a kind is refused, not shown', () {
      expect(
        () => readCreditQuote({...quoteWire, 'quoteToken': ''}),
        throwsFormatException,
      );
      expect(
        () => readCreditQuote({...quoteWire, 'kind': null}),
        throwsFormatException,
      );
    });
  });

  group('agreement', () {
    test('reads an approved plan awaiting its down payment', () {
      final a = readCreditAgreement(agreementWire());

      expect(a.status, AgreementStatus.approved);
      expect(a.needsActivationPayment, isTrue);
      expect(a.primaryPayment, PaymentPurpose.activation);
      expect(a.canCancel, isTrue);
      expect(a.payoffToday, isNull);
      expect(a.instalments, hasLength(3));
      expect(a.instalments.first.dueDate, isNull);
    });

    test('reads an active plan with an overdue payment', () {
      final a = readCreditAgreement(activeAgreementWire());

      expect(a.status, AgreementStatus.active);
      expect(a.hasOverdue, isTrue);
      expect(a.nextDue!.number, 2);
      expect(a.primaryPayment, PaymentPurpose.instalment);
      expect(a.canCancel, isFalse);
      expect(a.payoffToday!.amount, 32000);
      expect(a.instalments.first.status, InstalmentStatus.paid);
      expect(a.instalments.first.dueDate, DateTime(2026, 4, 2));
    });

    test('one unreadable plan does not hide the others', () {
      final list = readCreditAgreements([
        agreementWire(id: 'a'),
        {...agreementWire(id: 'b'), 'state': 42},
        agreementWire(id: 'c'),
      ]);

      expect(list.map((a) => a.id), ['a', 'c']);
    });
  });

  test('payment start, profile and vendor program read', () {
    final start = readPlanPaymentStart(paymentStartWire);
    expect(start.amount.amount, 12000);
    expect(start.redirectUrl, 'https://pay.example.test/redirect');

    final profile = readCreditProfile(profileWire);
    expect(profile.band, RiskBand.b);
    expect(profile.availableCredit.amount, 150000);
    expect(profile.factors.map((f) => f.code), contains('kyc_verified'));

    final program = readVendorCreditProgram(vendorProgramWire);
    expect(program.prepayEnabled, isTrue);
    expect(program.prepayTenures, [3]);
    expect(program.currentPlatformRiskFeePercent, 3);
    expect(program.payLaterNeedsFeeAcceptance, isFalse);
  });

  group('messages', () {
    test('every reason the risk engine gives has a sentence', () {
      const codes = [
        'kyc_required', 'identity_unavailable', 'band_too_low',
        'buyer_limit_exceeded', 'vendor_exposure_exceeded',
        'reserve_insufficient', 'prior_default', 'velocity_exceeded',
        'too_many_active_agreements', 'cooling_off', 'duplicate_identity',
        'kind_disabled', 'guarantor_disabled', 'amount_below_minimum',
        'amount_above_maximum', 'manual_review_required',
        'interest_requires_partner', 'guarantor_not_allowed_for_kind',
      ];
      for (final code in codes) {
        final sentence = reasonForBuyer(code);
        expect(sentence, endsWith('.'), reason: code);
        expect(sentence.contains('_'), isFalse, reason: code);
      }
    });

    test('a seller\'s own reason is shown as words', () {
      expect(reasonForBuyer('size_unavailable'), 'Size unavailable');
    });

    test('stale and expired quotes ask for a new offer', () {
      for (final code in ['credit_quote.stale', 'credit_quote.expired']) {
        expect(
          creditFailureMessage(EmiFailure(EmiFailureKind.rejected, code: code)),
          contains('new one'),
        );
      }
    });

    test('a failed payment says nothing was charged', () {
      expect(
        creditFailureMessage(
          const EmiFailure(
            EmiFailureKind.server,
            code: 'credit_payment.unavailable',
          ),
        ),
        contains('Nothing has been charged'),
      );
    });
  });
}
