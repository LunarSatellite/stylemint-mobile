import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_appointment_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_appointments_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_leads_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_contact.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';

import 'service_fixtures.dart';

void _stubLeads(
  MockBankLeadsRepository repo, {
  List<BankLead>? leads,
  ServiceFailure? failure,
}) {
  when(
    () => repo.listLeads(
      status: any(named: 'status'),
      kind: any(named: 'kind'),
      search: any(named: 'search'),
      cursor: any(named: 'cursor'),
    ),
  ).thenAnswer(
    (_) async => failure != null
        ? left(failure)
        : ok(
            page(
              leads ??
                  [
                    lead(),
                    lead(
                      id: lead2Id,
                      status: 2,
                      kind: 2,
                      contact: contactWire(name: 'Hari Gurung'),
                      productName: 'Savings Plus',
                      appointment: appointmentWire(),
                    ),
                  ],
            ),
          ),
  );
}

void _stubLead(
  MockBankLeadsRepository repo,
  BankLead l, {
  List<BankLeadNote> notes = const [],
}) {
  when(() => repo.getLead(l.id)).thenAnswer((_) async => ok(l));
  when(() => repo.listNotes(l.id)).thenAnswer((_) async => ok(notes));
}

void main() {
  setUpAll(registerServiceFallbacks);

  group('reading leads (contract v1)', () {
    test('a lead carries the consented contact, answers and appointment', () {
      final l = lead(appointment: appointmentWire());
      expect(l.reference, 'ENQ-7F3A2C');
      expect(l.kind, BankLeadKind.enquiry);
      expect(l.status, BankLeadStatus.newLead);
      expect(l.productType, BankProductType.loan);
      expect(l.contact?.name, 'Sita Sharma');
      expect(l.consentedPhone, '+977 9841-000000');
      expect(l.contact?.preferredMethod, BankContactMethod.phone);
      expect(l.consent?.version, 'bank-contact-v1');
      expect(l.answers.map((a) => a.label), [
        'Loan amount (NPR)',
        'Purpose',
      ]);
      expect(l.appointment?.id, appointmentId);
      expect(l.appointment?.timeText, '10:00–10:30');
      expect(l.appointment?.date, DateTime(2026, 10, 21));
    });

    test('a withdrawn lead has no contact details, whatever is sent', () {
      final json = leadWire()..['withdrawnUtc'] = '2026-10-20T10:00:00Z';
      final l = readBankLead(json);
      expect(l.isWithdrawn, isTrue);
      expect(l.contact, isNull);
      expect(l.consentedPhone, isNull);
      expect(l.displayName, 'Withdrawn by the buyer');
    });

    test('the status workflow is forward only; Closed from any open state', () {
      expect(BankLeadStatus.newLead.nextStatuses, [
        BankLeadStatus.contacted,
        BankLeadStatus.qualified,
        BankLeadStatus.converted,
        BankLeadStatus.closed,
      ]);
      expect(BankLeadStatus.qualified.nextStatuses, [
        BankLeadStatus.converted,
        BankLeadStatus.closed,
      ]);
      expect(BankLeadStatus.converted.nextStatuses, isEmpty);
      expect(BankLeadStatus.closed.nextStatuses, isEmpty);
    });

    test('call and WhatsApp addresses', () {
      expect(
        phoneCallUri('+977 9841-000000').toString(),
        'tel:+9779841000000',
      );
      expect(
        whatsAppUri('+977 9841-000000').toString(),
        'https://wa.me/9779841000000',
      );
      expect(
        whatsAppUri('9841111111').toString(),
        'https://wa.me/9779841111111',
      );
      expect(isCallablePhone('12345'), isFalse);
    });

    test('a 404 without a feature code is "being set up"; a not_found is not',
        () {
      expect(serviceUnavailable(const ServiceLoadException(notDeployed)), isTrue);
      expect(
        serviceUnavailable(
          const ServiceLoadException(
            ServiceFailure(
              ServiceFailureKind.notFound,
              code: 'service_lead.not_found',
            ),
          ),
        ),
        isFalse,
      );
    });
  });

  group('leads inbox', () {
    testWidgets('lists enquiries and appointment requests, newest first', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubLeads(repo);
      await pumpServiceScreen(
        tester,
        const BankLeadsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );

      expect(find.text('Sita Sharma'), findsOneWidget);
      expect(find.text('Enquiry · Home Loan'), findsOneWidget);
      expect(find.text('Hari Gurung'), findsOneWidget);
      expect(find.text('Appointment · Savings Plus'), findsOneWidget);
      expect(
        find.text('Visit Today at 10:00 · New Road Branch'),
        findsOneWidget,
      );
      expect(find.text('New'), findsWidgets);
      // The inbox shows names only; contact details stay on the lead.
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('filters by status and kind on the server', (tester) async {
      final repo = MockBankLeadsRepository();
      _stubLeads(repo);
      await pumpServiceScreen(
        tester,
        const BankLeadsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );

      await tapAndSettle(
        tester,
        find.byKey(BankLeadsScreen.statusChipKey(BankLeadStatus.contacted)),
      );
      verify(
        () => repo.listLeads(
          status: BankLeadStatus.contacted,
          kind: null,
          search: '',
          cursor: null,
        ),
      ).called(1);

      await tapAndSettle(
        tester,
        find.byKey(BankLeadsScreen.kindChipKey(BankLeadKind.appointment)),
      );
      verify(
        () => repo.listLeads(
          status: BankLeadStatus.contacted,
          kind: BankLeadKind.appointment,
          search: '',
          cursor: null,
        ),
      ).called(1);
    });

    testWidgets('searches by reference or name', (tester) async {
      final repo = MockBankLeadsRepository();
      _stubLeads(repo);
      await pumpServiceScreen(
        tester,
        const BankLeadsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );
      await tester.enterText(find.byKey(BankLeadsScreen.searchKey), 'ENQ-7F');
      await tester.pump(const Duration(milliseconds: 450));
      await settle(tester);
      verify(
        () => repo.listLeads(
          status: null,
          kind: null,
          search: 'ENQ-7F',
          cursor: null,
        ),
      ).called(1);
    });

    testWidgets('a tile opens the lead', (tester) async {
      final repo = MockBankLeadsRepository();
      _stubLeads(repo);
      await pumpServiceScreen(
        tester,
        const BankLeadsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );
      await tapAndSettle(tester, find.byKey(BankLeadsScreen.tileKey(leadId)));
      expect(find.text('lead page $leadId'), findsOneWidget);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubLeads(repo, failure: notDeployed);
      await pumpServiceScreen(
        tester,
        const BankLeadsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(find.text('Your leads inbox is being set up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('lead detail', () {
    testWidgets('shows the consented contact with Call and WhatsApp', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      final launcher = FakeContactLauncher();
      _stubLead(repo, lead());
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
        launcher: launcher,
      );

      expect(find.text('Home Loan'), findsOneWidget);
      expect(find.text('Sita Sharma'), findsOneWidget);
      expect(find.text('+977 9841-000000'), findsOneWidget);
      expect(find.text('sita@example.com'), findsOneWidget);
      expect(find.text('Prefers: Phone'), findsOneWidget);
      expect(find.text('Loan amount (NPR)'), findsOneWidget);
      expect(find.text('2500000'), findsOneWidget);
      expect(find.text('Can I apply jointly?'), findsOneWidget);
      expect(
        find.textContaining('with their consent on 20 Oct 2026'),
        findsOneWidget,
      );

      await tapAndSettle(tester, find.byKey(BankConsentedContactCard.callKey));
      await tapAndSettle(
        tester,
        find.byKey(BankConsentedContactCard.whatsAppKey),
      );
      expect(launcher.opened.map((u) => u.toString()), [
        'tel:+9779841000000',
        'https://wa.me/9779841000000',
      ]);
    });

    testWidgets('a withdrawn lead offers no way to contact the buyer', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubLead(repo, lead(withdrawn: true));
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.byKey(BankConsentedContactCard.withdrawnKey), findsOneWidget);
      expect(find.byKey(BankConsentedContactCard.callKey), findsNothing);
      expect(find.byKey(BankConsentedContactCard.whatsAppKey), findsNothing);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('no consented phone number, no call buttons', (tester) async {
      final repo = MockBankLeadsRepository();
      _stubLead(repo, lead(contact: contactWire(phone: null)));
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.text('sita@example.com'), findsOneWidget);
      expect(find.byKey(BankConsentedContactCard.callKey), findsNothing);
      expect(find.byKey(BankConsentedContactCard.whatsAppKey), findsNothing);
    });

    testWidgets('moves the status forward, and closes with a reason', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubLead(repo, lead());
      when(
        () => repo.setLeadStatus(any(), any(), reason: any(named: 'reason')),
      ).thenAnswer((_) async => ok(lead(status: 2)));
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );

      expect(
        find.byKey(BankLeadDetailScreen.statusButtonKey(BankLeadStatus.newLead)),
        findsNothing,
      );
      await tapAndSettle(
        tester,
        find.byKey(
          BankLeadDetailScreen.statusButtonKey(BankLeadStatus.contacted),
        ),
      );
      verify(
        () => repo.setLeadStatus(leadId, BankLeadStatus.contacted),
      ).called(1);

      await tapAndSettle(
        tester,
        find.byKey(BankLeadDetailScreen.statusButtonKey(BankLeadStatus.closed)),
      );
      expect(find.text('Close this lead?'), findsOneWidget);
      await tester.enterText(
        find.byKey(ServiceReasonDialogKeys.field),
        'Not eligible',
      );
      await tester.pump();
      await tapAndSettle(tester, find.byKey(ServiceReasonDialogKeys.confirm));
      verify(
        () => repo.setLeadStatus(
          leadId,
          BankLeadStatus.closed,
          reason: 'Not eligible',
        ),
      ).called(1);
    });

    testWidgets('a converted lead has no status buttons', (tester) async {
      final repo = MockBankLeadsRepository();
      _stubLead(repo, lead(status: 4));
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(
        find.text('Converted — this lead became a customer.'),
        findsOneWidget,
      );
      for (final s in BankLeadStatus.values) {
        expect(
          find.byKey(BankLeadDetailScreen.statusButtonKey(s)),
          findsNothing,
        );
      }
    });

    testWidgets('lists the team\'s notes and adds one', (tester) async {
      final repo = MockBankLeadsRepository();
      _stubLead(
        repo,
        lead(),
        notes: [
          BankLeadNote(
            id: 'n1',
            text: 'Called, will visit Sunday',
            createdUtc: DateTime.utc(2026, 10, 20, 9),
          ),
        ],
      );
      when(() => repo.addNote(any(), any())).thenAnswer(
        (_) async => ok(const BankLeadNote(id: 'n2', text: 'Sent the form')),
      );
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.text('Called, will visit Sunday'), findsOneWidget);

      await tester.enterText(
        find.byKey(BankLeadDetailScreen.noteFieldKey),
        'Sent the form',
      );
      await tapAndSettle(tester, find.byKey(BankLeadDetailScreen.addNoteKey));
      verify(() => repo.addNote(leadId, 'Sent the form')).called(1);
    });

    testWidgets('an appointment request links to the appointment', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      _stubLead(repo, lead(kind: 2, appointment: appointmentWire()));
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.text('21 Oct 2026, 10:00–10:30'), findsOneWidget);
      await tapAndSettle(
        tester,
        find.byKey(BankLeadDetailScreen.appointmentLinkKey),
      );
      expect(find.text('appointment page $appointmentId'), findsOneWidget);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      when(() => repo.getLead(leadId)).thenAnswer((_) async => left(notDeployed));
      when(
        () => repo.listNotes(leadId),
      ).thenAnswer((_) async => left(notDeployed));
      await pumpServiceScreen(
        tester,
        const BankLeadDetailScreen(leadId: leadId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('branch appointments', () {
    void stubDay(MockBankLeadsRepository repo, List<BankAppointment> items) {
      when(
        () => repo.listAppointments(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => ok(items));
    }

    testWidgets('today\'s visits by start time, with a branch filter', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      stubDay(repo, [
        appointment(
          id: appointment2Id,
          startTime: '11:30',
          startUtc: '2026-10-21T05:45:00+00:00',
          branchName: 'Pokhara Branch',
          name: 'Gita Rai',
        ),
        appointment(),
      ]);
      await pumpServiceScreen(
        tester,
        const BankAppointmentsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );

      verify(
        () => repo.listAppointments(
          from: serviceTestToday,
          to: serviceTestToday,
        ),
      ).called(1);
      expect(find.text('2 booked · 2 in total'), findsOneWidget);
      final first = tester.getTopLeft(find.text('Ram Thapa')).dy;
      final second = tester.getTopLeft(find.text('Gita Rai')).dy;
      expect(first, lessThan(second), reason: '10:00 before 11:30');

      await tapAndSettle(
        tester,
        find.byKey(BankAppointmentsScreen.branchChipKey('Pokhara Branch')),
      );
      expect(find.text('Ram Thapa'), findsNothing);
      expect(find.text('Gita Rai'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byKey(BankAppointmentsScreen.tileKey(appointment2Id)),
      );
      expect(find.text('appointment page $appointment2Id'), findsOneWidget);
    });

    testWidgets('tomorrow asks for tomorrow', (tester) async {
      final repo = MockBankLeadsRepository();
      stubDay(repo, const []);
      await pumpServiceScreen(
        tester,
        const BankAppointmentsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.text('No branch appointments today.'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(BankAppointmentsScreen.dayChipKey(1)));
      verify(
        () => repo.listAppointments(
          from: DateTime(2026, 10, 22),
          to: DateTime(2026, 10, 22),
        ),
      ).called(1);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      when(
        () => repo.listAppointments(
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => left(notDeployed));
      await pumpServiceScreen(
        tester,
        const BankAppointmentsScreen(),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('appointment detail', () {
    void stubOne(MockBankLeadsRepository repo, BankAppointment a) {
      when(
        () => repo.findAppointment(a.id, around: any(named: 'around')),
      ).thenAnswer((_) async => ok(a));
    }

    testWidgets('once started: completed or no-show', (tester) async {
      final repo = MockBankLeadsRepository();
      stubOne(repo, appointment());
      when(
        () => repo.completeAppointment(appointmentId),
      ).thenAnswer((_) async => ok(appointment(status: 3)));
      await pumpServiceScreen(
        tester,
        const BankAppointmentDetailScreen(appointmentId: appointmentId),
        bank: repo,
        category: ServiceCategory.bank,
      );

      expect(find.text('Savings Plus'), findsOneWidget);
      expect(find.text('10:00–10:30'), findsOneWidget);
      expect(find.text('New Road Branch'), findsOneWidget);
      expect(find.text('Ram Thapa'), findsOneWidget);
      expect(find.byKey(BankConsentedContactCard.callKey), findsOneWidget);
      expect(find.byKey(BankAppointmentDetailScreen.noShowKey), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byKey(BankAppointmentDetailScreen.completeKey),
      );
      verify(() => repo.completeAppointment(appointmentId)).called(1);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.byKey(BankAppointmentDetailScreen.completeKey), findsNothing);
    });

    testWidgets('before the start: no completed / no-show, cancel with a '
        'reason', (tester) async {
      final repo = MockBankLeadsRepository();
      stubOne(
        repo,
        appointment(startTime: '15:00', startUtc: '2026-10-21T09:15:00+00:00'),
      );
      when(
        () => repo.cancelAppointment(any(), any()),
      ).thenAnswer((_) async => ok(appointment(status: 2)));
      await pumpServiceScreen(
        tester,
        const BankAppointmentDetailScreen(appointmentId: appointmentId),
        bank: repo,
        category: ServiceCategory.bank,
      );

      expect(find.byKey(BankAppointmentDetailScreen.completeKey), findsNothing);
      expect(find.byKey(BankAppointmentDetailScreen.noShowKey), findsNothing);
      await tapAndSettle(tester, find.byKey(BankAppointmentDetailScreen.cancelKey));
      await tester.enterText(
        find.byKey(ServiceReasonDialogKeys.field),
        'Branch closed early',
      );
      await tester.pump();
      await tapAndSettle(tester, find.byKey(ServiceReasonDialogKeys.confirm));
      verify(
        () => repo.cancelAppointment(appointmentId, 'Branch closed early'),
      ).called(1);
    });

    testWidgets('links to the lead for status and notes', (tester) async {
      final repo = MockBankLeadsRepository();
      stubOne(repo, appointment());
      await pumpServiceScreen(
        tester,
        const BankAppointmentDetailScreen(appointmentId: appointmentId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      await tapAndSettle(
        tester,
        find.byKey(BankAppointmentDetailScreen.leadLinkKey),
      );
      expect(find.text('lead page $leadId'), findsOneWidget);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockBankLeadsRepository();
      when(
        () => repo.findAppointment(any(), around: any(named: 'around')),
      ).thenAnswer((_) async => left(notDeployed));
      await pumpServiceScreen(
        tester,
        const BankAppointmentDetailScreen(appointmentId: appointmentId),
        bank: repo,
        category: ServiceCategory.bank,
      );
      expect(find.byKey(ServiceSettingUpView.viewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
