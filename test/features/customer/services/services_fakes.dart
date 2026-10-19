import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/banks.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/banks_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/repositories/bookings_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_forms_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_pages_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_confirmed_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/my_bookings_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/package_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/services_home_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/stay_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/travel_results_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_map.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/banks_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/bookings_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/shared/services_providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

// ── Ids and money ────────────────────────────────────────────────────────────

const stayId = '1a2b3c4d-0000-4000-8000-000000000001';
const roomId = '1a2b3c4d-0000-4000-8000-000000000002';
const suiteId = '1a2b3c4d-0000-4000-8000-000000000003';
const packageId = '1a2b3c4d-0000-4000-8000-000000000004';
const departureId = '1a2b3c4d-0000-4000-8000-000000000005';
const fullDepartureId = '1a2b3c4d-0000-4000-8000-000000000006';
const bookingId = '1a2b3c4d-0000-4000-8000-000000000007';
const pastBookingId = '1a2b3c4d-0000-4000-8000-000000000008';
const bankId = '1a2b3c4d-0000-4000-8000-000000000009';
const loanId = '1a2b3c4d-0000-4000-8000-00000000000a';
const branchId = '1a2b3c4d-0000-4000-8000-00000000000b';
const slotId = '1a2b3c4d-0000-4000-8000-00000000000c';
const leadId = '1a2b3c4d-0000-4000-8000-00000000000d';
const appointmentId = '1a2b3c4d-0000-4000-8000-00000000000e';

Money npr(double amount) => Money(amount: amount, currency: 'NPR');

/// 2026-10-18 11:45 in Kathmandu.
final testNow = DateTime.utc(2026, 10, 18, 6);

const comingSoon = ServiceFailure(ServiceFailureKind.notFound, statusCode: 404);
const serverDown = ServiceFailure(ServiceFailureKind.server, statusCode: 500);

const policy = CancellationPolicy(
  freeCancellationDays: 3,
  lateCancellationFeePercent: 50,
  summary: 'Free cancellation until 3 days before. After that 50%.',
);

// ── Sample data ─────────────────────────────────────────────────────────────

StaySearchItem stayItem() => StaySearchItem(
  listingId: stayId,
  title: 'Hotel Barahi',
  vendor: const ServiceVendor(id: 'v1', name: 'Barahi Group'),
  city: 'Pokhara',
  area: 'Lakeside',
  starRating: 4,
  fromPricePerNight: npr(4500),
  nights: 2,
  totalPrice: npr(9000),
  paymentModes: const [PaymentMode.fullPrepay, PaymentMode.deposit],
  depositPercent: 30,
  latitude: 28.21,
  longitude: 83.95,
);

StayDetail stayDetail() => StayDetail(
  listingId: stayId,
  title: 'Hotel Barahi',
  cancellationPolicy: policy,
  city: 'Pokhara',
  area: 'Lakeside',
  addressLine: 'Lakeside, Ward 6',
  latitude: 28.21,
  longitude: 83.95,
  amenities: const ['wifi', 'pool'],
  starRating: 4,
  checkInTime: '14:00',
  checkOutTime: '12:00',
  houseRules: 'No smoking in rooms.',
  paymentModes: const [
    PaymentMode.fullPrepay,
    PaymentMode.deposit,
    PaymentMode.payAtVenue,
  ],
  depositPercent: 30,
  roomTypes: [
    RoomType(
      id: roomId,
      name: 'Deluxe Double',
      baseRate: npr(4500),
      maxAdults: 2,
      maxGuests: 3,
      beds: '1 King',
      availableUnits: 3,
      totalPrice: npr(9000),
    ),
    RoomType(
      id: suiteId,
      name: 'Lake Suite',
      baseRate: npr(9000),
      maxAdults: 2,
      maxGuests: 2,
      availableUnits: 0,
    ),
  ],
);

BookingQuote stayQuote({bool available = true, String? reason}) =>
    BookingQuote(
      listingId: stayId,
      kind: ListingKind.stay,
      roomTypeId: roomId,
      startDate: DateTime(2026, 10, 21),
      endDate: DateTime(2026, 10, 23),
      nights: 2,
      rooms: 1,
      adults: 2,
      totalPrice: npr(9000),
      available: available,
      unavailableReason: reason,
      lines: [
        PriceLine(
          label: 'Deluxe Double · 21 Oct',
          quantity: 1,
          unitPrice: npr(4500),
          amount: npr(4500),
        ),
        PriceLine(
          label: 'Deluxe Double · 22 Oct',
          quantity: 1,
          unitPrice: npr(4500),
          amount: npr(4500),
        ),
      ],
      paymentOptions: [
        PaymentOption(
          mode: PaymentMode.fullPrepay,
          payNow: npr(9000),
          payAtVenue: npr(0),
        ),
        PaymentOption(
          mode: PaymentMode.deposit,
          payNow: npr(2700),
          payAtVenue: npr(6300),
        ),
        PaymentOption(
          mode: PaymentMode.payAtVenue,
          payNow: npr(0),
          payAtVenue: npr(9000),
        ),
      ],
      cancellationPolicy: policy,
      holdMinutes: 15,
    );

PackageSearchItem packageItem() => PackageSearchItem(
  listingId: packageId,
  title: 'Annapurna Base Camp 7D',
  destination: 'Annapurna',
  durationDays: 7,
  fromPrice: npr(45000),
  nextDepartureDate: DateTime(2026, 11, 2),
  paymentModes: const [PaymentMode.fullPrepay, PaymentMode.deposit],
  depositPercent: 20,
);

PackageDetail packageDetail() => PackageDetail(
  listingId: packageId,
  title: 'Annapurna Base Camp 7D',
  cancellationPolicy: policy,
  destination: 'Annapurna',
  durationDays: 7,
  durationNights: 6,
  meetingPoint: 'Lakeside Chowk, Pokhara',
  itinerary: const [
    ItineraryDay(day: 1, title: 'Pokhara to Nayapul'),
    ItineraryDay(day: 2, title: 'Nayapul to Ghorepani'),
  ],
  inclusions: const ['Guide', 'Permits'],
  exclusions: const ['Flights'],
  paymentModes: const [PaymentMode.fullPrepay, PaymentMode.deposit],
  depositPercent: 20,
  departures: [
    Departure(
      id: departureId,
      date: DateTime(2026, 11, 2),
      endDate: DateTime(2026, 11, 8),
      seatsTotal: 12,
      seatsAvailable: 5,
      adultPrice: npr(45000),
      childPrice: npr(30000),
    ),
    Departure(
      id: fullDepartureId,
      date: DateTime(2026, 11, 16),
      seatsAvailable: 0,
      adultPrice: npr(45000),
    ),
  ],
);

BookingQuote packageQuote({int adults = 2, int children = 1}) => BookingQuote(
  listingId: packageId,
  kind: ListingKind.package,
  departureId: departureId,
  startDate: DateTime(2026, 11, 2),
  endDate: DateTime(2026, 11, 8),
  adults: adults,
  children: children,
  totalPrice: npr(120000),
  available: true,
  paymentOptions: [
    PaymentOption(
      mode: PaymentMode.fullPrepay,
      payNow: npr(120000),
      payAtVenue: npr(0),
    ),
    PaymentOption(
      mode: PaymentMode.deposit,
      payNow: npr(24000),
      payAtVenue: npr(96000),
    ),
  ],
  cancellationPolicy: policy,
);

Booking booking({
  String id = bookingId,
  BookingState state = BookingState.confirmed,
  PaymentMode mode = PaymentMode.deposit,
  DateTime? start,
  DateTime? end,
  bool canCancel = true,
  bool canPay = false,
  ListingKind kind = ListingKind.stay,
}) => Booking(
  id: id,
  number: 'BK-7F3A9C21',
  kind: kind,
  state: state,
  listingId: stayId,
  listingTitle: kind == ListingKind.stay
      ? 'Hotel Barahi'
      : 'Annapurna Base Camp 7D',
  roomTypeName: kind == ListingKind.stay ? 'Deluxe Double' : null,
  startDate: start ?? DateTime(2026, 10, 21),
  endDate: end ?? DateTime(2026, 10, 23),
  nights: 2,
  rooms: 1,
  adults: 2,
  guestName: 'Sita Sharma',
  totalPrice: npr(9000),
  paymentMode: mode,
  depositPercent: 30,
  payNowAmount: npr(2700),
  paidOnline: state == BookingState.pendingPayment ? npr(0) : npr(2700),
  balanceDue: npr(6300),
  cancellationPolicy: policy,
  canCancel: canCancel,
  canPay: canPay,
);

BankSummary bankSummary() => const BankSummary(
  id: bankId,
  name: 'Himalayan Bank',
  isVerified: true,
  productCount: 2,
  branchCount: 1,
  productTypes: [BankProductType.savings, BankProductType.loan],
  appointmentsAvailable: true,
);

BankProduct loanProduct() => BankProduct(
  id: loanId,
  bankId: bankId,
  bankName: 'Himalayan Bank',
  type: BankProductType.loan,
  name: 'Home Loan',
  summary: 'Up to 70% of property value',
  interestRateMinPercent: 9.5,
  interestRateMaxPercent: 11.25,
  rateNote: 'Base rate + 2.5% p.a.',
  feesText: 'Processing fee 0.75%',
  eligibilityText: 'Nepali citizen, 21–60 years',
  documentsRequired: const ['Citizenship', 'Salary certificate'],
  minAmount: npr(500000),
  maxAmount: npr(50000000),
  minTenureMonths: 12,
  maxTenureMonths: 300,
);

BankBranch branch() => const BankBranch(
  id: branchId,
  bankId: bankId,
  name: 'New Road Branch',
  addressLine: 'New Road, Ward 22',
  city: 'Kathmandu',
  phone: '01-4227540',
  appointmentsEnabled: true,
  openingHours: [OpeningHours(dayOfWeek: 0, opens: '10:00', closes: '17:00')],
);

BankDetail bankDetail() => BankDetail(
  summary: bankSummary(),
  licenceNumber: 'NRB-A-012',
  products: [loanProduct()],
  branches: [branch()],
);

const consentText =
    'I agree that StyleMint shares my name, phone number and email address '
    '(if I give one) with Himalayan Bank so that Himalayan Bank can contact '
    'me about this enquiry.';

EnquiryForm loanForm() => const EnquiryForm(
  bankId: bankId,
  bankName: 'Himalayan Bank',
  productType: BankProductType.loan,
  fields: [
    EnquiryFormField(
      key: 'loanAmount',
      label: 'Loan amount (NPR)',
      type: FormFieldType.amount,
      required: true,
      min: 10000,
    ),
  ],
  consent: BankConsent(version: 'bank-contact-v1', text: consentText),
);

BranchAvailability availability() => BranchAvailability(
  branchId: branchId,
  days: [
    AvailabilityDay(
      date: DateTime(2026, 10, 20),
      slots: [
        AvailabilitySlot(
          slotId: slotId,
          startTime: '10:00',
          endTime: '10:30',
          remaining: 2,
          status: SlotAvailability.available,
          startUtc: DateTime.utc(2026, 10, 20, 4, 15),
        ),
      ],
    ),
    AvailabilityDay(
      date: DateTime(2026, 10, 24),
      closed: true,
      closedReason: 'Holiday: Dashain',
    ),
  ],
);

BankLead lead({
  LeadStatus status = LeadStatus.newLead,
  DateTime? withdrawnAt,
}) => BankLead(
  id: leadId,
  reference: 'ENQ-7F3A2C',
  kind: LeadKind.enquiry,
  status: status,
  bankId: bankId,
  bankName: 'Himalayan Bank',
  productId: loanId,
  productType: BankProductType.loan,
  productName: 'Home Loan',
  answers: const [
    LeadAnswer(key: 'loanAmount', label: 'Loan amount (NPR)', value: '2500000'),
  ],
  contact: withdrawnAt == null
      ? const ContactDetails(name: 'Sita Sharma', phone: '+9779841000000')
      : null,
  consentText: consentText,
  withdrawnAt: withdrawnAt,
  createdAt: DateTime.utc(2026, 10, 18, 5),
);

BankAppointment appointment({
  AppointmentStatus status = AppointmentStatus.booked,
}) => BankAppointment(
  id: appointmentId,
  reference: 'APT-91B0C4',
  bankId: bankId,
  bankName: 'Himalayan Bank',
  branchName: 'New Road Branch',
  branchAddress: 'New Road, Ward 22, Kathmandu',
  date: DateTime(2026, 10, 20),
  startTime: '10:00',
  endTime: '10:30',
  startUtc: DateTime.utc(2026, 10, 20, 4, 15),
  endUtc: DateTime.utc(2026, 10, 20, 4, 45),
  status: status,
  createdAt: DateTime.utc(2026, 10, 18, 5, 30),
);

// ── Fakes ───────────────────────────────────────────────────────────────────

Either<ServiceFailure, T> _ok<T>(T v) => right(v);

class FakeBookingsRepository implements BookingsRepository {
  ServiceFailure? failAll;
  List<StaySearchItem> stays = [stayItem()];
  StayDetail stay = stayDetail();
  BookingQuote Function() nextStayQuote = stayQuote;
  List<PackageSearchItem> packages = [packageItem()];
  PackageDetail package = packageDetail();
  BookingQuote Function(int adults, int children) nextPackageQuote =
      (a, c) => packageQuote(adults: a, children: c);
  List<Booking> bookings = [booking()];
  Booking Function(PaymentMode mode)? createdBooking;
  ServiceFailure? payFailure;
  CancellationQuote? cancelPreview;
  ServiceFailure? bookingFailure;

  final searches = <StaySearch>[];
  final travelSearches = <TravelSearch>[];
  final stayQuotes = <Map<String, Object?>>[];
  final packageQuotes = <Map<String, Object?>>[];
  final created = <Map<String, Object?>>[];
  final payments = <Map<String, Object?>>[];
  final cancels = <String>[];
  int previews = 0;

  Future<Either<ServiceFailure, T>> _r<T>(T Function() v) async {
    final f = failAll;
    return f == null ? _ok(v()) : left(f);
  }

  @override
  Future<Either<ServiceFailure, List<StaySearchItem>>> searchStays(
    StaySearch search,
  ) {
    searches.add(search);
    return _r(() => stays);
  }

  @override
  Future<Either<ServiceFailure, StayDetail>> getStay(
    String listingId, {
    StaySearch? search,
  }) => _r(() => stay);

  @override
  Future<Either<ServiceFailure, BookingQuote>> quoteStay({
    required String listingId,
    required String roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int rooms,
    required int adults,
    int children = 0,
  }) {
    stayQuotes.add({
      'listingId': listingId,
      'roomTypeId': roomTypeId,
      'checkIn': checkIn,
      'checkOut': checkOut,
      'rooms': rooms,
      'adults': adults,
    });
    return _r(nextStayQuote);
  }

  @override
  Future<Either<ServiceFailure, List<PackageSearchItem>>> searchPackages(
    TravelSearch search,
  ) {
    travelSearches.add(search);
    return _r(() => packages);
  }

  @override
  Future<Either<ServiceFailure, PackageDetail>> getPackage(String listingId) =>
      _r(() => package);

  @override
  Future<Either<ServiceFailure, BookingQuote>> quotePackage({
    required String listingId,
    required String departureId,
    required int adults,
    required int children,
  }) {
    packageQuotes.add({
      'departureId': departureId,
      'adults': adults,
      'children': children,
    });
    return _r(() => nextPackageQuote(adults, children));
  }

  @override
  Future<Either<ServiceFailure, Booking>> createBooking({
    required BookingQuote quote,
    required PaymentMode paymentMode,
    required String guestName,
    required List<Traveller> travellers,
    required String idempotencyKey,
    String? specialRequests,
  }) async {
    created.add({
      'mode': paymentMode,
      'guestName': guestName,
      'travellers': travellers,
      'key': idempotencyKey,
      'kind': quote.kind,
    });
    final f = bookingFailure ?? failAll;
    if (f != null) return left(f);
    final make = createdBooking;
    final b =
        make?.call(paymentMode) ??
        booking(
          state: paymentMode == PaymentMode.payAtVenue
              ? BookingState.confirmed
              : BookingState.pendingPayment,
          mode: paymentMode,
          kind: quote.kind,
        );
    bookings = [b, ...bookings.where((x) => x.id != b.id)];
    return right(b);
  }

  @override
  Future<Either<ServiceFailure, BookingPaymentStart>> pay({
    required String bookingId,
    required BookingPaymentRail rail,
    required String idempotencyKey,
  }) async {
    payments.add({'bookingId': bookingId, 'rail': rail, 'key': idempotencyKey});
    final f = payFailure ?? failAll;
    if (f != null) return left(f);
    return right(
      BookingPaymentStart(
        bookingId: bookingId,
        amount: npr(2700),
        redirectUrl: 'https://pay.example/esewa/$bookingId',
      ),
    );
  }

  @override
  Future<Either<ServiceFailure, List<Booking>>> myBookings() =>
      _r(() => bookings);

  @override
  Future<Either<ServiceFailure, Booking>> myBooking(String id) async {
    final f = failAll ?? bookingFailure;
    if (f != null) return left(f);
    final b = bookings.where((x) => x.id == id).firstOrNull;
    return b == null
        ? left(
            const ServiceFailure(
              ServiceFailureKind.notFound,
              code: 'booking.not_found',
              statusCode: 404,
            ),
          )
        : right(b);
  }

  @override
  Future<Either<ServiceFailure, CancellationQuote>> cancellationQuote(
    String id,
  ) {
    previews++;
    return _r(
      () =>
          cancelPreview ??
          CancellationQuote(
            bookingId: id,
            cancellable: true,
            fee: npr(0),
            refundAmount: npr(2700),
            freeUntilDate: DateTime(2026, 10, 18),
          ),
    );
  }

  @override
  Future<Either<ServiceFailure, Booking>> cancel({
    required String bookingId,
    required String idempotencyKey,
    String? reason,
  }) async {
    cancels.add(bookingId);
    final f = failAll;
    if (f != null) return left(f);
    final b = bookings.firstWhere((x) => x.id == bookingId);
    final cancelled = Booking(
      id: b.id,
      number: b.number,
      kind: b.kind,
      state: BookingState.cancelled,
      listingId: b.listingId,
      listingTitle: b.listingTitle,
      startDate: b.startDate,
      endDate: b.endDate,
      totalPrice: b.totalPrice,
      paymentMode: b.paymentMode,
      payNowAmount: b.payNowAmount,
      paidOnline: b.paidOnline,
      balanceDue: npr(0),
      cancellationPolicy: b.cancellationPolicy,
      refundAmount: npr(2700),
      refundState: RefundState.pending,
      cancelledByBuyer: true,
    );
    bookings = [cancelled, ...bookings.where((x) => x.id != bookingId)];
    return right(cancelled);
  }
}

class FakeBanksRepository implements BanksRepository {
  ServiceFailure? failAll;
  List<BankSummary> banks = [bankSummary()];
  List<BankProduct> products = [loanProduct()];
  BankDetail bank = bankDetail();
  ServiceFailure? submitFailure;
  List<BankLead> leads = [lead()];
  List<BankAppointment> appointments = [appointment()];

  final productTypes = <BankProductType?>[];
  final enquiries = <Map<String, Object?>>[];
  final booked = <Map<String, Object?>>[];
  final withdrawn = <String>[];
  final cancelled = <String>[];

  Future<Either<ServiceFailure, T>> _r<T>(T Function() v) async {
    final f = failAll;
    return f == null ? right(v()) : left(f);
  }

  @override
  Future<Either<ServiceFailure, List<BankSummary>>> listBanks({
    String? search,
  }) => _r(() => banks);

  @override
  Future<Either<ServiceFailure, BankDetail>> getBank(String bankId) =>
      _r(() => bank);

  @override
  Future<Either<ServiceFailure, List<BankProduct>>> listProducts({
    BankProductType? type,
    String? search,
  }) {
    productTypes.add(type);
    return _r(
      () => [
        for (final p in products)
          if (type == null || p.type == type) p,
      ],
    );
  }

  @override
  Future<Either<ServiceFailure, BankProduct>> getProduct(String productId) =>
      _r(() => products.firstWhere((p) => p.id == productId));

  @override
  Future<Either<ServiceFailure, List<BankBranch>>> listBranches(
    String bankId,
  ) => _r(() => bank.branches);

  @override
  Future<Either<ServiceFailure, BranchAvailability>> getAvailability({
    required String branchId,
    DateTime? from,
    int days = 14,
  }) => _r(availability);

  @override
  Future<Either<ServiceFailure, EnquiryForm>> getEnquiryForm({
    required String bankId,
    required BankProductType productType,
    LeadKind kind = LeadKind.enquiry,
  }) => _r(loanForm);

  @override
  Future<Either<ServiceFailure, BankLead>> submitEnquiry({
    required String bankId,
    required BankProductType productType,
    required Map<String, String> answers,
    required ContactDetails contact,
    required String consentVersion,
    required String idempotencyKey,
    String? productId,
    String? branchId,
    String? message,
  }) async {
    enquiries.add({
      'bankId': bankId,
      'productId': productId,
      'answers': answers,
      'name': contact.name,
      'phone': contact.phone,
      'consentVersion': consentVersion,
    });
    final f = submitFailure ?? failAll;
    if (f != null) return left(f);
    return right(lead());
  }

  @override
  Future<Either<ServiceFailure, List<BankLead>>> myEnquiries() =>
      _r(() => leads);

  @override
  Future<Either<ServiceFailure, BankLead>> myEnquiry(String leadId) =>
      _r(() => leads.firstWhere((l) => l.id == leadId));

  @override
  Future<Either<ServiceFailure, BankLead>> withdrawEnquiry({
    required String leadId,
    required String idempotencyKey,
  }) async {
    withdrawn.add(leadId);
    leads = [lead(status: LeadStatus.closed, withdrawnAt: testNow)];
    return right(leads.single);
  }

  @override
  Future<Either<ServiceFailure, BankAppointment>> bookAppointment({
    required String branchId,
    required String slotId,
    required DateTime date,
    required ContactDetails contact,
    required String consentVersion,
    required String idempotencyKey,
    String? productId,
    BankProductType? productType,
    String? purpose,
  }) async {
    booked.add({
      'branchId': branchId,
      'slotId': slotId,
      'date': date,
      'consentVersion': consentVersion,
      'phone': contact.phone,
    });
    final f = submitFailure ?? failAll;
    if (f != null) return left(f);
    return right(appointment());
  }

  @override
  Future<Either<ServiceFailure, List<BankAppointment>>> myAppointments() =>
      _r(() => appointments);

  @override
  Future<Either<ServiceFailure, BankAppointment>> myAppointment(
    String appointmentId,
  ) => _r(() => appointments.firstWhere((a) => a.id == appointmentId));

  @override
  Future<Either<ServiceFailure, BankAppointment>> cancelAppointment({
    required String appointmentId,
    required String idempotencyKey,
    String? reason,
  }) async {
    cancelled.add(appointmentId);
    appointments = [appointment(status: AppointmentStatus.cancelled)];
    return right(appointments.single);
  }
}

// ── Pumping ─────────────────────────────────────────────────────────────────

void phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The app's Services routes, as the router registers them.
List<RouteBase> servicesRoutes() => [
  GoRoute(
    path: RouteNames.services,
    builder: (_, _) => const ServicesHomeScreen(),
  ),
  GoRoute(
    path: RouteNames.serviceStayResults,
    builder: (_, state) => StayResultsScreen(
      search: StaySearch.fromQuery(state.uri.queryParameters),
    ),
  ),
  GoRoute(
    path: RouteNames.serviceStayDetail,
    builder: (_, state) => StayDetailScreen(
      listingId: state.pathParameters['listingId']!,
      search: StaySearch.fromQuery(state.uri.queryParameters),
    ),
  ),
  GoRoute(
    path: RouteNames.serviceTravelResults,
    builder: (_, state) => TravelResultsScreen(
      search: TravelSearch.fromQuery(state.uri.queryParameters),
    ),
  ),
  GoRoute(
    path: RouteNames.serviceTravelDetail,
    builder: (_, state) => PackageDetailScreen(
      listingId: state.pathParameters['listingId']!,
      travellers: TravelSearch.fromQuery(state.uri.queryParameters).travellers,
    ),
  ),
  GoRoute(
    path: RouteNames.bankEnquiryDetail,
    builder: (_, state) => EnquiryDetailScreen(
      leadId: state.pathParameters['leadId']!,
      justSent: state.uri.queryParameters['sent'] == '1',
    ),
  ),
  GoRoute(
    path: RouteNames.bankAppointmentDetail,
    builder: (_, state) => AppointmentDetailScreen(
      appointmentId: state.pathParameters['appointmentId']!,
      justSent: state.uri.queryParameters['sent'] == '1',
    ),
  ),
  GoRoute(
    path: RouteNames.serviceBankDetail,
    builder: (_, state) =>
        BankDetailScreen(bankId: state.pathParameters['bankId']!),
  ),
  GoRoute(
    path: RouteNames.serviceBankProduct,
    builder: (_, state) =>
        BankProductScreen(productId: state.pathParameters['productId']!),
  ),
  GoRoute(
    path: RouteNames.bankEnquiryForm,
    builder: (_, state) =>
        BankEnquiryScreen(productId: state.pathParameters['productId']!),
  ),
  GoRoute(
    path: RouteNames.bankAppointmentForm,
    builder: (_, state) => BankAppointmentScreen(
      bankId: state.pathParameters['bankId']!,
      productId: state.uri.queryParameters['productId'],
    ),
  ),
  GoRoute(
    path: RouteNames.myBookings,
    builder: (_, _) => const MyBookingsScreen(),
  ),
  GoRoute(
    path: RouteNames.bookingCheckout,
    builder: (_, state) => BookingCheckoutScreen(
      args: state.extra is BookingCheckoutArgs
          ? state.extra! as BookingCheckoutArgs
          : null,
    ),
  ),
  GoRoute(
    path: RouteNames.bookingConfirmed,
    builder: (_, state) =>
        BookingConfirmedScreen(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
    path: RouteNames.bookingDetail,
    builder: (_, state) =>
        BookingDetailScreen(bookingId: state.pathParameters['bookingId']!),
  ),
];

/// Pumps the Services routes at [location] with fake repositories, a fixed
/// clock, a stand-in map and a recording payment launcher.
Future<GoRouter> pumpServices(
  WidgetTester tester, {
  required String location,
  FakeBookingsRepository? bookings,
  FakeBanksRepository? banks,
  List<Uri>? launched,
  bool signedIn = true,
}) async {
  phoneSize(tester);
  final router = GoRouter(initialLocation: location, routes: servicesRoutes());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookingsRepositoryProvider.overrideWithValue(
          bookings ?? FakeBookingsRepository(),
        ),
        banksRepositoryProvider.overrideWithValue(
          banks ?? FakeBanksRepository(),
        ),
        servicesSignedInProvider.overrideWithValue(signedIn),
        servicesBuyerNameProvider.overrideWithValue(
          signedIn ? 'Sita Sharma' : null,
        ),
        servicesClockProvider.overrideWithValue(() => testNow),
        serviceMapBuilderProvider.overrideWithValue(
          (context, pins, onTap) => Container(
            key: const Key('test-map'),
            color: Colors.blueGrey,
            child: Column(
              children: [
                for (final p in pins)
                  TextButton(
                    key: Key('test-pin-${p.id}'),
                    onPressed: onTap == null ? null : () => onTap(p.id),
                    child: Text(p.label ?? p.id),
                  ),
              ],
            ),
          ),
        ),
        servicePaymentLauncherProvider.overrideWithValue(
          (uri) async => launched?.add(uri),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await settle(tester);
  return router;
}

/// Pumps a few frames: loaders animate forever, so never pumpAndSettle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the page's list until [finder] is built and on screen. The
/// page's list is the first vertical scrollable: text fields and chip rows
/// have scrollables of their own further down the tree.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await settle(tester);
}
