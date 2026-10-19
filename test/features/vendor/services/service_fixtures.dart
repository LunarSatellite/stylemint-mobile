import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/data/bank_leads_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/domain/bank_lead.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/shared/bank_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/booking_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/shared/booking_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_category.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_contact.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_page.dart';

class MockBankLeadsRepository extends Mock implements BankLeadsRepository {}

class MockVendorBookingsRepository extends Mock
    implements VendorBookingsRepository {}

/// Records what would have been opened instead of leaving the app.
class FakeContactLauncher extends ServiceContactLauncher {
  final List<Uri> opened = [];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return true;
  }
}

/// Wednesday 21 Oct 2026 in Kathmandu; 11:45 there.
final serviceTestToday = DateTime(2026, 10, 21);
final serviceTestNow = DateTime.utc(2026, 10, 21, 6);

const notDeployed = ServiceFailure(ServiceFailureKind.notFound);

void registerServiceFallbacks() {
  registerFallbackValue(BankLeadStatus.newLead);
  registerFallbackValue(BankLeadKind.enquiry);
  registerFallbackValue(BookingState.confirmed);
  registerFallbackValue(ServiceListingKind.stay);
  registerFallbackValue(DateTime(2026));
}

// ── Bank wire fixtures (service-banks contract v1) ───────────────────────────

const leadId = '11111111-2222-4333-8444-555555555555';
const lead2Id = '11111111-2222-4333-8444-666666666666';
const appointmentId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
const appointment2Id = 'aaaaaaaa-bbbb-4ccc-8ddd-ffffffffffff';

Map<String, dynamic> contactWire({
  String name = 'Sita Sharma',
  String? phone = '+977 9841-000000',
  String? email = 'sita@example.com',
}) => {
  'name': name,
  'phone': phone,
  'email': email,
  'preferredMethod': 1,
};

Map<String, dynamic> leadWire({
  String id = leadId,
  int status = 1,
  int kind = 1,
  String reference = 'ENQ-7F3A2C',
  Map<String, dynamic>? contact,
  bool withdrawn = false,
  Map<String, dynamic>? appointment,
  String productName = 'Home Loan',
}) => {
  'id': id,
  'reference': reference,
  'kind': kind,
  'status': status,
  'statusChangedUtc': '2026-10-20T09:00:00+00:00',
  'productId': null,
  'productType': 4,
  'productName': productName,
  'branchId': null,
  'branchName': 'New Road Branch',
  'answers': [
    {'key': 'loanAmount', 'label': 'Loan amount (NPR)', 'value': '2500000'},
    {'key': 'loanPurpose', 'label': 'Purpose', 'value': 'Home'},
  ],
  'message': 'Can I apply jointly?',
  'contact': withdrawn ? null : (contact ?? contactWire()),
  'consent': {
    'version': 'bank-contact-v1',
    'text': 'I agree that StyleMint shares my name and phone number.',
    'acceptedUtc': '2026-10-20T08:00:00+00:00',
  },
  'appointment': appointment,
  'closedReason': null,
  'withdrawnUtc': withdrawn ? '2026-10-20T10:00:00+00:00' : null,
  'noteCount': 1,
  'createdUtc': '2026-10-20T08:00:00+00:00',
  'updatedUtc': '2026-10-20T09:00:00+00:00',
};

Map<String, dynamic> appointmentWire({
  String id = appointmentId,
  int status = 1,
  String startTime = '10:00',
  String endTime = '10:30',
  String startUtc = '2026-10-21T04:15:00+00:00',
  String branchName = 'New Road Branch',
  String name = 'Ram Thapa',
  String date = '2026-10-21',
}) => {
  'id': id,
  'leadId': leadId,
  'reference': 'APT-91B0C4',
  'bankId': 'b0000000-0000-4000-8000-000000000001',
  'bankName': 'Himalayan Bank',
  'branchId': 'c0000000-0000-4000-8000-000000000001',
  'branchName': branchName,
  'branchAddress': 'New Road, Ward 22, Kathmandu',
  'slotId': 'd0000000-0000-4000-8000-000000000001',
  'date': date,
  'startTime': startTime,
  'endTime': endTime,
  'startUtc': startUtc,
  'endUtc': '2026-10-21T04:45:00+00:00',
  'status': status,
  'cancelledBy': null,
  'cancelReason': null,
  'purpose': 'Open a savings account',
  'productId': null,
  'productType': 1,
  'productName': 'Savings Plus',
  'contact': contactWire(name: name, phone: '9841111111', email: null),
  'createdUtc': '2026-10-19T08:00:00+00:00',
};

BankLead lead({
  String id = leadId,
  int status = 1,
  int kind = 1,
  bool withdrawn = false,
  Map<String, dynamic>? contact,
  Map<String, dynamic>? appointment,
  String productName = 'Home Loan',
}) => readBankLead(
  leadWire(
    id: id,
    status: status,
    kind: kind,
    withdrawn: withdrawn,
    contact: contact,
    appointment: appointment,
    productName: productName,
  ),
);

BankAppointment appointment({
  String id = appointmentId,
  int status = 1,
  String startTime = '10:00',
  String startUtc = '2026-10-21T04:15:00+00:00',
  String branchName = 'New Road Branch',
  String name = 'Ram Thapa',
}) => readBankAppointment(
  appointmentWire(
    id: id,
    status: status,
    startTime: startTime,
    startUtc: startUtc,
    branchName: branchName,
    name: name,
  ),
);

// ── Booking wire fixtures (service-bookings contract v1) ─────────────────────

const bookingId = '99999999-8888-4777-8666-555555555555';
const booking2Id = '99999999-8888-4777-8666-444444444444';
const booking3Id = '99999999-8888-4777-8666-333333333333';

Map<String, dynamic> bookingWire({
  String id = bookingId,
  String number = 'BK-7F3A9C21',
  int kind = 1,
  int state = 2,
  String guestName = 'Sita Sharma',
  String startDate = '2026-10-21',
  String endDate = '2026-10-23',
  double total = 9000,
  double paidOnline = 2700,
  double balanceDue = 6300,
  bool canCheckIn = true,
  bool canComplete = true,
  bool canMarkNoShow = true,
  bool canMarkBalanceReceived = true,
  bool canCancel = true,
  List<Map<String, dynamic>>? travellers,
}) => {
  'id': id,
  'number': number,
  'kind': kind,
  'state': state,
  'listingId': 'e0000000-0000-4000-8000-000000000001',
  'listingTitle': kind == 1 ? 'Hotel Yak & Yeti' : 'Annapurna Base Camp 7D',
  'roomTypeId': kind == 1 ? 'f0000000-0000-4000-8000-000000000001' : null,
  'roomTypeName': kind == 1 ? 'Deluxe Double' : null,
  'departureId': kind == 2 ? 'f0000000-0000-4000-8000-000000000009' : null,
  'vendor': {'vendorAccountId': 'x', 'name': 'Hotel Yak & Yeti'},
  'startDate': startDate,
  'endDate': endDate,
  'nights': kind == 1 ? 2 : 0,
  'rooms': 1,
  'adults': 2,
  'children': 1,
  'guestName': guestName,
  'travellers':
      travellers ??
      [
        {'fullName': guestName, 'type': 1, 'age': null},
        {'fullName': 'Mina Sharma', 'type': 2, 'age': 9},
      ],
  'specialRequests': 'Late arrival',
  'checkInTime': '14:00',
  'checkOutTime': '12:00',
  'addressLine': 'Durbar Marg',
  'city': 'Kathmandu',
  'meetingPoint': kind == 2 ? 'Lakeside Chowk, Pokhara' : null,
  'currency': 'NPR',
  'lines': [
    {
      'label': 'Deluxe Double · 21 Oct',
      'date': '2026-10-21',
      'quantity': 1,
      'unitPrice': 4500,
      'amount': 4500,
    },
    {
      'label': 'Deluxe Double · 22 Oct',
      'date': '2026-10-22',
      'quantity': 1,
      'unitPrice': 4500,
      'amount': 4500,
    },
  ],
  'totalPrice': total,
  'paymentMode': 2,
  'depositPercent': 30,
  'payNowAmount': paidOnline,
  'paidOnline': paidOnline,
  'balanceDue': balanceDue,
  'balanceReceivedUtc': null,
  'balanceReceivedAmount': null,
  'holdExpiresUtc': null,
  'cancellationPolicy': {
    'freeCancellationDays': 3,
    'lateCancellationFeePercent': 50,
    'freeUntilDate': '2026-10-18',
    'summary': 'Free cancellation until 18 Oct 2026.',
  },
  'cancelledBy': null,
  'cancelReason': null,
  'cancellationFee': null,
  'refundAmount': null,
  'refundState': 0,
  'commissionPercent': 10,
  'commissionAmount': null,
  'vendorNetAmount': null,
  'settledUtc': null,
  'buyerAccountId': null,
  'createdUtc': '2026-10-10T08:00:00+00:00',
  'confirmedUtc': '2026-10-10T08:05:00+00:00',
  'canPay': false,
  'canCancel': canCancel,
  'canCheckIn': canCheckIn,
  'canComplete': canComplete,
  'canMarkNoShow': canMarkNoShow,
  'canMarkBalanceReceived': canMarkBalanceReceived,
};

ServiceBooking booking({
  String id = bookingId,
  String number = 'BK-7F3A9C21',
  int kind = 1,
  int state = 2,
  String guestName = 'Sita Sharma',
  String startDate = '2026-10-21',
  String endDate = '2026-10-23',
  double paidOnline = 2700,
  double balanceDue = 6300,
  bool canCheckIn = true,
  bool canComplete = true,
  bool canMarkNoShow = true,
  bool canMarkBalanceReceived = true,
  bool canCancel = true,
}) => readServiceBooking(
  bookingWire(
    id: id,
    number: number,
    kind: kind,
    state: state,
    guestName: guestName,
    startDate: startDate,
    endDate: endDate,
    paidOnline: paidOnline,
    balanceDue: balanceDue,
    canCheckIn: canCheckIn,
    canComplete: canComplete,
    canMarkNoShow: canMarkNoShow,
    canMarkBalanceReceived: canMarkBalanceReceived,
    canCancel: canCancel,
  ),
);

// ── Pumping ──────────────────────────────────────────────────────────────────

void tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

/// Pumps [screen] at `/` inside a router that answers every place the
/// service screens can go with a plain text page naming it.
Future<void> pumpServiceScreen(
  WidgetTester tester,
  Widget screen, {
  MockBankLeadsRepository? bank,
  MockVendorBookingsRepository? bookings,
  ServiceCategory category = ServiceCategory.hotel,
  FakeContactLauncher? launcher,
  List<Override> overrides = const [],
}) async {
  tallPhone(tester);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      for (final path in const [
        '/vendor/bookings',
        '/vendor/availability',
        '/vendor/bank/leads',
        '/vendor/bank/appointments',
        '/vendor/apply',
        '/vendor/apply/step2',
      ])
        GoRoute(path: path, builder: (_, _) => Text('page $path')),
      GoRoute(
        path: '/vendor/bookings/:id',
        builder: (_, s) => Text('booking page ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/vendor/bank/leads/:id',
        builder: (_, s) => Text('lead page ${s.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/vendor/bank/appointments/:id',
        builder: (_, s) => Text('appointment page ${s.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (bank != null) bankLeadsRepositoryProvider.overrideWithValue(bank),
        if (bookings != null)
          vendorBookingsRepositoryProvider.overrideWithValue(bookings),
        serviceTodayProvider.overrideWithValue(serviceTestToday),
        serviceNowProvider.overrideWithValue(serviceTestNow),
        vendorServiceCategoryNowProvider.overrideWithValue(category),
        serviceContactLauncherProvider.overrideWithValue(
          launcher ?? FakeContactLauncher(),
        ),
        ...overrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
}

// ── Stubs ────────────────────────────────────────────────────────────────────

Either<ServiceFailure, T> ok<T>(T value) => right(value);

ServicePage<T> page<T>(List<T> items, {String? next}) =>
    ServicePage<T>(items: items, nextCursor: next);
