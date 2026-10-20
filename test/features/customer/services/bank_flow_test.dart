import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_forms_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/bank_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'services_fakes.dart';

/// Fills the contact fields the enquiry and appointment forms share.
Future<void> _fillContact(WidgetTester tester) async {
  await reveal(tester, find.byKey(const Key('bank-contact-phone')));
  await tester.enterText(
    find.byKey(const Key('bank-contact-phone')),
    '+977 9841-000000',
  );
  await settle(tester);
}

Future<void> _tickConsent(WidgetTester tester) async {
  await tapVisible(tester, find.byKey(BankConsentBox.checkboxKey));
}

void main() {
  group('Enquiry', () {
    testWidgets('consent names the bank and starts unticked', (tester) async {
      await pumpServices(
        tester,
        location: RouteNames.bankEnquiryFormPath(loanId),
      );
      await reveal(tester, find.byKey(BankConsentBox.checkboxKey));
      expect(
        tester.widget<Checkbox>(find.byKey(BankConsentBox.checkboxKey)).value,
        isFalse,
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('bank-consent-text'))).data,
        consentText,
      );
      expect(find.text('Share my details with Himalayan Bank'), findsOneWidget);
    });

    testWidgets('nothing is sent without consent', (tester) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankEnquiryFormPath(loanId),
        banks: repo,
      );
      await tester.enterText(
        find.byKey(BankFormKeys.field('loanAmount')),
        '2500000',
      );
      await _fillContact(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      expect(repo.enquiries, isEmpty);
      await reveal(tester, find.byKey(BankConsentBox.errorKey));
      expect(find.byKey(BankConsentBox.errorKey), findsOneWidget);
    });

    testWidgets('a required answer and a valid phone are checked', (
      tester,
    ) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankEnquiryFormPath(loanId),
        banks: repo,
      );
      await tester.enterText(find.byKey(BankFormKeys.field('loanAmount')), '50');
      await reveal(tester, find.byKey(const Key('bank-contact-phone')));
      await tester.enterText(find.byKey(const Key('bank-contact-phone')), '12');
      await _tickConsent(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      expect(repo.enquiries, isEmpty);
      await reveal(tester, find.text('At least 10000'));
      expect(find.text('At least 10000'), findsOneWidget);
      await reveal(tester, find.text('Enter a valid phone number'));
      expect(find.text('Enter a valid phone number'), findsOneWidget);
    });

    testWidgets('with consent the enquiry is sent and shown as sent', (
      tester,
    ) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankEnquiryFormPath(loanId),
        banks: repo,
      );
      await tester.enterText(
        find.byKey(BankFormKeys.field('loanAmount')),
        '2500000',
      );
      await _fillContact(tester);
      await _tickConsent(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      final sent = repo.enquiries.single;
      expect(sent['bankId'], bankId);
      expect(sent['productId'], loanId);
      expect(sent['answers'], {'loanAmount': '2500000'});
      expect(sent['name'], 'Sita Sharma');
      expect(sent['phone'], '+9779841000000');
      expect(sent['consentVersion'], 'bank-contact-v1');
      expect(
        tester
            .widget<EnquiryDetailScreen>(find.byType(EnquiryDetailScreen))
            .leadId,
        leadId,
      );
      expect(find.byKey(const Key('bank-request-sent')), findsOneWidget);
    });

    testWidgets('outdated consent wording is unticked to be read again', (
      tester,
    ) async {
      final repo = FakeBanksRepository()
        ..submitFailure = const ServiceFailure(
          ServiceFailureKind.conflict,
          code: 'service_enquiry.consent_outdated',
          statusCode: 409,
        );
      await pumpServices(
        tester,
        location: RouteNames.bankEnquiryFormPath(loanId),
        banks: repo,
      );
      await tester.enterText(
        find.byKey(BankFormKeys.field('loanAmount')),
        '2500000',
      );
      await _fillContact(tester);
      await _tickConsent(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      expect(repo.enquiries, hasLength(1));
      await reveal(tester, find.byKey(BankConsentBox.checkboxKey));
      expect(
        tester.widget<Checkbox>(find.byKey(BankConsentBox.checkboxKey)).value,
        isFalse,
      );
    });
  });

  group('Appointment', () {
    testWidgets('branch, day and slot → booked with consent', (tester) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankAppointmentFormPath(bankId),
        banks: repo,
      );

      // The bank's only bookable branch is chosen already.
      await tapVisible(
        tester,
        find.byKey(BankFormKeys.day(DateTime(2026, 10, 20))),
      );
      // A closed day (holiday) is not offered.
      expect(
        find.byKey(BankFormKeys.day(DateTime(2026, 10, 24))),
        findsNothing,
      );
      await tapVisible(tester, find.byKey(BankFormKeys.slot(slotId)));
      await _fillContact(tester);
      await _tickConsent(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      final b = repo.booked.single;
      expect(b['branchId'], branchId);
      expect(b['slotId'], slotId);
      expect(b['date'], DateTime(2026, 10, 20));
      expect(b['consentVersion'], 'bank-contact-v1');
      expect(
        tester
            .widget<AppointmentDetailScreen>(
              find.byType(AppointmentDetailScreen),
            )
            .appointmentId,
        appointmentId,
      );
      expect(find.byKey(const Key('bank-request-sent')), findsOneWidget);
    });

    testWidgets('no slot chosen, nothing booked', (tester) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankAppointmentFormPath(bankId),
        banks: repo,
      );
      await _fillContact(tester);
      await _tickConsent(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      expect(repo.booked, isEmpty);
      await reveal(tester, find.byKey(const Key('bank-slot-error')));
      expect(find.byKey(const Key('bank-slot-error')), findsOneWidget);
    });

    testWidgets('appointment consent is required too', (tester) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankAppointmentFormPath(bankId),
        banks: repo,
      );
      await tapVisible(
        tester,
        find.byKey(BankFormKeys.day(DateTime(2026, 10, 20))),
      );
      await tapVisible(tester, find.byKey(BankFormKeys.slot(slotId)));
      await _fillContact(tester);
      await tapVisible(tester, find.byKey(BankFormKeys.submit));

      expect(repo.booked, isEmpty);
      await reveal(tester, find.byKey(BankConsentBox.errorKey));
      expect(find.byKey(BankConsentBox.errorKey), findsOneWidget);
    });
  });

  group('Request detail', () {
    testWidgets('an enquiry can be withdrawn', (tester) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankEnquiryDetailPath(leadId),
        banks: repo,
      );
      expect(find.text('Sent'), findsOneWidget);
      await tapVisible(tester, find.byKey(EnquiryDetailScreen.withdrawKey));
      await tester.tap(find.byKey(EnquiryDetailScreen.confirmWithdrawKey));
      await settle(tester);

      expect(repo.withdrawn, [leadId]);
      expect(find.text('Withdrawn'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('enquiry-withdrawn')));
      expect(find.byKey(EnquiryDetailScreen.withdrawKey), findsNothing);
    });

    testWidgets('an appointment can be cancelled before it starts', (
      tester,
    ) async {
      final repo = FakeBanksRepository();
      await pumpServices(
        tester,
        location: RouteNames.bankAppointmentDetailPath(appointmentId),
        banks: repo,
      );
      expect(find.text('Booked'), findsOneWidget);
      await tapVisible(tester, find.byKey(AppointmentDetailScreen.cancelKey));
      await tester.tap(find.byKey(AppointmentDetailScreen.confirmCancelKey));
      await settle(tester);

      expect(repo.cancelled, [appointmentId]);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.byKey(AppointmentDetailScreen.cancelKey), findsNothing);
    });
  });
}
