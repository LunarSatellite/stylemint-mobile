import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/banks_json.dart'
    show readCalendarDate;
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Readers for the bookings contract v1 payloads (`/v1/services/stays/*`,
/// `/v1/services/packages/*`, `/v1/bookings/me/*`).
///
/// Tolerant in the usual way, except where a guess would change what the
/// buyer is told about money or dates: a booking or quote without a
/// recognisable kind, state, payment mode or start date is refused with a
/// [FormatException] rather than shown wrong.

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

List<Map<String, dynamic>> _maps(Object? raw) => [
  for (final e in raw is List ? raw : const []) ?_map(e),
];

List<String> _strings(Object? raw) => raw is List
    ? List.unmodifiable(
        raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty),
      )
    : const <String>[];

String _currency(Map<String, dynamic> json) =>
    readOptionalString(json['currency']) ?? 'NPR';

Money _money(Object? raw, String currency) =>
    Money(amount: readOptionalDouble(raw) ?? 0, currency: currency);

Money? _optionalMoney(Object? raw, String currency) {
  final amount = readOptionalDouble(raw);
  return amount == null ? null : Money(amount: amount, currency: currency);
}

int? _optionalInt(Object? raw) => raw is num
    ? raw.toInt()
    : raw is String
    ? int.tryParse(raw.trim())
    : null;

T _required<T>(T? value, String what) {
  if (value == null) throw FormatException('Bookings payload: no $what');
  return value;
}

String _id(Map<String, dynamic> json, String key, String what) {
  final id = readString(json[key]);
  if (id.isEmpty) throw FormatException('$what: no $key');
  return id;
}

T? _tryRead<T>(T Function() read) {
  try {
    return read();
  } on FormatException {
    return null;
  }
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) read) => [
  for (final item in raw is List ? _maps(raw) : readPagedItems(raw))
    ?_tryRead(() => read(item)),
];

List<PaymentMode> _modes(Object? raw) => List.unmodifiable({
  for (final m in raw is List ? raw : const []) ?PaymentMode.fromWire(m),
});

ServiceVendor? _vendor(Object? raw) {
  final json = _map(raw);
  if (json == null) return null;
  return ServiceVendor(
    id: readString(json['vendorAccountId']),
    name: readString(json['name']),
    logoUrl: readOptionalString(json['logoUrl']),
  );
}

CancellationPolicy readCancellationPolicy(Object? raw) {
  final json = _map(raw) ?? const <String, dynamic>{};
  return CancellationPolicy(
    freeCancellationDays: readInt(json['freeCancellationDays']),
    lateCancellationFeePercent:
        readOptionalDouble(json['lateCancellationFeePercent']) ?? 0,
    freeUntilDate: readCalendarDate(json['freeUntilDate']),
    summary: readOptionalString(json['summary']),
  );
}

List<PriceLine> _lines(Object? raw, String currency) => [
  for (final l in _maps(raw))
    PriceLine(
      label: readString(l['label']),
      date: readCalendarDate(l['date']),
      quantity: readInt(l['quantity']),
      unitPrice: _money(l['unitPrice'], currency),
      amount: _money(l['amount'], currency),
    ),
];

// ── Stays ────────────────────────────────────────────────────────────────────

StaySearchItem readStaySearchItem(Map<String, dynamic> json) {
  final currency = _currency(json);
  return StaySearchItem(
    listingId: _id(json, 'listingId', 'Stay'),
    title: readString(json['title']),
    vendor: _vendor(json['vendor']),
    city: readOptionalString(json['city']),
    area: readOptionalString(json['area']),
    coverPhotoUrl: readOptionalString(json['coverPhotoUrl']),
    starRating: _optionalInt(json['starRating']),
    amenities: _strings(json['amenities']),
    fromPricePerNight: _optionalMoney(json['fromPricePerNight'], currency),
    nights: _optionalInt(json['nights']),
    totalPrice: _optionalMoney(json['totalPrice'], currency),
    cheapestRoomTypeId: readOptionalString(json['cheapestRoomTypeId']),
    available: json['available'] == null || readBool(json['available']),
    paymentModes: _modes(json['paymentModes']),
    depositPercent: readOptionalDouble(json['depositPercent']) ?? 0,
    latitude: readOptionalDouble(json['latitude']),
    longitude: readOptionalDouble(json['longitude']),
  );
}

List<StaySearchItem> readStaySearchItems(Object? raw) =>
    _list(raw, readStaySearchItem);

RoomType _roomType(Map<String, dynamic> json, String currency) => RoomType(
  id: _id(json, 'roomTypeId', 'Room type'),
  name: readString(json['name']),
  description: readOptionalString(json['description']),
  maxAdults: readInt(json['maxAdults']).clamp(1, 1000),
  maxGuests: readInt(json['maxGuests']).clamp(1, 1000),
  beds: readOptionalString(json['beds']),
  sizeSqm: readOptionalDouble(json['sizeSqm']),
  photoUrls: _strings(json['photoUrls']),
  amenities: _strings(json['amenities']),
  baseRate: _money(json['baseRate'], currency),
  availableUnits: _optionalInt(json['availableUnits']),
  totalPrice: _optionalMoney(json['totalPrice'], currency),
  nightly: List.unmodifiable([
    for (final n in _maps(json['nightly']))
      if (readCalendarDate(n['date']) case final date?)
        NightlyRate(
          date: date,
          price: _money(n['price'], currency),
          available: readInt(n['available']),
        ),
  ]),
);

StayDetail readStayDetail(Map<String, dynamic> json) {
  final currency = _currency(json);
  return StayDetail(
    listingId: _id(json, 'listingId', 'Stay'),
    title: readString(json['title']),
    description: readOptionalString(json['description']),
    vendor: _vendor(json['vendor']),
    city: readOptionalString(json['city']),
    area: readOptionalString(json['area']),
    addressLine: readOptionalString(json['addressLine']),
    latitude: readOptionalDouble(json['latitude']),
    longitude: readOptionalDouble(json['longitude']),
    photoUrls: _strings(json['photoUrls']),
    amenities: _strings(json['amenities']),
    starRating: _optionalInt(json['starRating']),
    checkInTime: readOptionalString(json['checkInTime']),
    checkOutTime: readOptionalString(json['checkOutTime']),
    minNights: (_optionalInt(json['minNights']) ?? 1).clamp(1, 365),
    maxNights: _optionalInt(json['maxNights']),
    houseRules: readOptionalString(json['houseRules']),
    cancellationPolicy: readCancellationPolicy(json['cancellationPolicy']),
    paymentModes: _modes(json['paymentModes']),
    depositPercent: readOptionalDouble(json['depositPercent']) ?? 0,
    fromPricePerNight: _optionalMoney(json['fromPricePerNight'], currency),
    roomTypes: List.unmodifiable([
      for (final r in _maps(json['roomTypes']))
        ?_tryRead(() => _roomType(r, currency)),
    ]),
  );
}

// ── Packages ────────────────────────────────────────────────────────────────

PackageSearchItem readPackageSearchItem(Map<String, dynamic> json) {
  final currency = _currency(json);
  return PackageSearchItem(
    listingId: _id(json, 'listingId', 'Package'),
    title: readString(json['title']),
    vendor: _vendor(json['vendor']),
    destination: readOptionalString(json['destination']),
    city: readOptionalString(json['city']),
    durationDays: _optionalInt(json['durationDays']),
    durationNights: _optionalInt(json['durationNights']),
    coverPhotoUrl: readOptionalString(json['coverPhotoUrl']),
    fromPrice: _optionalMoney(json['fromPrice'], currency),
    nextDepartureDate: readCalendarDate(json['nextDepartureDate']),
    departuresInMonth: _optionalInt(json['departuresInMonth']),
    paymentModes: _modes(json['paymentModes']),
    depositPercent: readOptionalDouble(json['depositPercent']) ?? 0,
  );
}

List<PackageSearchItem> readPackageSearchItems(Object? raw) =>
    _list(raw, readPackageSearchItem);

Departure _departure(Map<String, dynamic> json, String currency) => Departure(
  id: _id(json, 'departureId', 'Departure'),
  date: _required(readCalendarDate(json['date']), 'departure date'),
  endDate: readCalendarDate(json['endDate']),
  seatsTotal: _optionalInt(json['seatsTotal']),
  seatsAvailable: readInt(json['seatsAvailable']),
  adultPrice: _money(json['adultPrice'], currency),
  childPrice: _optionalMoney(json['childPrice'], currency),
  // 1 Open; a missing status reads as open, any other as not bookable.
  open: json['status'] == null || readInt(json['status']) == 1,
);

PackageDetail readPackageDetail(Map<String, dynamic> json) {
  final currency = _currency(json);
  final departures = [
    for (final d in _maps(json['departures']))
      ?_tryRead(() => _departure(d, currency)),
  ]..sort((a, b) => a.date.compareTo(b.date));
  return PackageDetail(
    listingId: _id(json, 'listingId', 'Package'),
    title: readString(json['title']),
    description: readOptionalString(json['description']),
    vendor: _vendor(json['vendor']),
    destination: readOptionalString(json['destination']),
    city: readOptionalString(json['city']),
    durationDays: _optionalInt(json['durationDays']),
    durationNights: _optionalInt(json['durationNights']),
    meetingPoint: readOptionalString(json['meetingPoint']),
    latitude: readOptionalDouble(json['latitude']),
    longitude: readOptionalDouble(json['longitude']),
    photoUrls: _strings(json['photoUrls']),
    itinerary: List.unmodifiable(
      <ItineraryDay>[
        for (final d in _maps(json['itinerary']))
          ItineraryDay(
            day: readInt(d['day']),
            title: readString(d['title']),
            description: readOptionalString(d['description']),
          ),
      ]..sort((a, b) => a.day.compareTo(b.day)),
    ),
    inclusions: _strings(json['inclusions']),
    exclusions: _strings(json['exclusions']),
    maxGroupSize: _optionalInt(json['maxGroupSize']),
    cancellationPolicy: readCancellationPolicy(json['cancellationPolicy']),
    paymentModes: _modes(json['paymentModes']),
    depositPercent: readOptionalDouble(json['depositPercent']) ?? 0,
    fromPrice: _optionalMoney(json['fromPrice'], currency),
    departures: List.unmodifiable(departures),
  );
}

// ── Quotes and bookings ─────────────────────────────────────────────────────

BookingQuote readBookingQuote(Map<String, dynamic> json) {
  final currency = _currency(json);
  return BookingQuote(
    listingId: readString(json['listingId']),
    kind: _required(ListingKind.fromWire(json['kind']), 'kind'),
    roomTypeId: readOptionalString(json['roomTypeId']),
    departureId: readOptionalString(json['departureId']),
    startDate: _required(readCalendarDate(json['startDate']), 'startDate'),
    endDate: readCalendarDate(json['endDate']),
    nights: _optionalInt(json['nights']),
    rooms: _optionalInt(json['rooms']),
    adults: readInt(json['adults']),
    children: readInt(json['children']),
    lines: List.unmodifiable(_lines(json['lines'], currency)),
    totalPrice: _money(json['totalPrice'], currency),
    available: readBool(json['available']),
    unavailableReason: readOptionalString(json['unavailableReason']),
    paymentOptions: List.unmodifiable([
      for (final o in _maps(json['paymentOptions']))
        if (PaymentMode.fromWire(o['mode']) case final mode?)
          PaymentOption(
            mode: mode,
            payNow: _money(o['payNow'], currency),
            payAtVenue: _money(o['payAtVenue'], currency),
          ),
    ]),
    cancellationPolicy: readCancellationPolicy(json['cancellationPolicy']),
    holdMinutes: _optionalInt(json['holdMinutes']),
  );
}

Booking readBooking(Map<String, dynamic> json) {
  final currency = _currency(json);
  return Booking(
    id: _id(json, 'id', 'Booking'),
    number: readString(json['number']),
    kind: _required(ListingKind.fromWire(json['kind']), 'kind'),
    state: _required(BookingState.fromWire(json['state']), 'state'),
    listingId: readString(json['listingId']),
    listingTitle: readString(json['listingTitle']),
    roomTypeName: readOptionalString(json['roomTypeName']),
    vendor: _vendor(json['vendor']),
    startDate: _required(readCalendarDate(json['startDate']), 'startDate'),
    endDate: readCalendarDate(json['endDate']),
    nights: _optionalInt(json['nights']),
    rooms: _optionalInt(json['rooms']),
    adults: readInt(json['adults']),
    children: readInt(json['children']),
    guestName: readOptionalString(json['guestName']),
    travellers: List.unmodifiable([
      for (final t in _maps(json['travellers']))
        Traveller(
          fullName: readString(t['fullName']),
          type: TravellerType.fromWire(t['type']),
          age: _optionalInt(t['age']),
        ),
    ]),
    specialRequests: readOptionalString(json['specialRequests']),
    checkInTime: readOptionalString(json['checkInTime']),
    checkOutTime: readOptionalString(json['checkOutTime']),
    addressLine: readOptionalString(json['addressLine']),
    city: readOptionalString(json['city']),
    meetingPoint: readOptionalString(json['meetingPoint']),
    lines: List.unmodifiable(_lines(json['lines'], currency)),
    totalPrice: _money(json['totalPrice'], currency),
    paymentMode: _required(
      PaymentMode.fromWire(json['paymentMode']),
      'paymentMode',
    ),
    depositPercent: readOptionalDouble(json['depositPercent']) ?? 0,
    payNowAmount: _money(json['payNowAmount'], currency),
    paidOnline: _money(json['paidOnline'], currency),
    balanceDue: _money(json['balanceDue'], currency),
    holdExpiresAt: readDate(json['holdExpiresUtc']),
    cancellationPolicy: readCancellationPolicy(json['cancellationPolicy']),
    cancelledByBuyer: readInt(json['cancelledBy']) == 1,
    cancelReason: readOptionalString(json['cancelReason']),
    cancellationFee: _optionalMoney(json['cancellationFee'], currency),
    refundAmount: _optionalMoney(json['refundAmount'], currency),
    refundState: RefundState.fromWire(json['refundState']),
    createdAt: readDate(json['createdUtc']),
    canPay: readBool(json['canPay']),
    canCancel: readBool(json['canCancel']),
  );
}

List<Booking> readBookings(Object? raw) => _list(raw, readBooking);

BookingPaymentStart readBookingPaymentStart(Map<String, dynamic> json) {
  final payment = _map(json['payment']) ?? const <String, dynamic>{};
  return BookingPaymentStart(
    bookingId: readString(json['bookingId']),
    amount: _money(json['amount'], _currency(json)),
    redirectUrl: readOptionalString(payment['redirectUrl']),
  );
}

CancellationQuote readCancellationQuote(Map<String, dynamic> json) {
  final currency = _currency(json);
  return CancellationQuote(
    bookingId: readString(json['bookingId']),
    cancellable: readBool(json['cancellable']),
    reason: readOptionalString(json['reason']),
    fee: _money(json['fee'], currency),
    refundAmount: _money(json['refundAmount'], currency),
    freeUntilDate: readCalendarDate(json['freeUntilDate']),
  );
}
