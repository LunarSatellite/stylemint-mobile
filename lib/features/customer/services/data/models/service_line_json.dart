import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/data/models/banks_json.dart'
    show readCalendarDate;
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Readers for the service parts of cart, checkout and order payloads
/// (service cart contract v1).
///
/// A server before that contract sends none of them: [readServiceLine]
/// returns null for a missing or unreadable block and the line is then a
/// product line, as the contract asks ("treat a missing `lineKind` as 1").

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? Map<String, dynamic>.from(raw) : null;

int? _int(Object? raw) => raw is num
    ? raw.toInt()
    : raw is String
    ? int.tryParse(raw.trim())
    : null;

Money _money(Object? raw, String currency) =>
    Money(amount: readOptionalDouble(raw) ?? 0, currency: currency);

/// `lineKind` 2 is a service line (§1). Anything else, or nothing, is a
/// product.
bool isServiceLineKind(Object? raw) => _int(raw) == 2;

/// Reads one service block: a cart line's `service` (§2.2), a checkout
/// session's `serviceLines[]` entry (§3.2) or an order line's `booking`
/// (§4.1). [lineId] is the cart line the block belongs to, when the block
/// does not carry it itself.
///
/// Null when [raw] is not a map or has no recognisable kind, listing or
/// start date — money and dates are never guessed.
ServiceLine? readServiceLine(Object? raw, {String? lineId}) {
  final json = _map(raw);
  if (json == null) return null;
  final kind = ListingKind.fromWire(json['kind']);
  final start = readCalendarDate(json['startDate']);
  final listingId = readString(json['listingId']);
  if (kind == null || start == null) return null;
  final currency = readOptionalString(json['currency']) ?? 'NPR';
  final travellers = json['travellers'];
  return ServiceLine(
    lineId: readOptionalString(json['lineId']) ?? lineId,
    kind: kind,
    listingId: listingId,
    listingTitle: readString(json['listingTitle']),
    itemName: readOptionalString(json['itemName']),
    roomTypeId: readOptionalString(json['roomTypeId']),
    departureId: readOptionalString(json['departureId']),
    startDate: start,
    endDate: readCalendarDate(json['endDate']),
    nights: _int(json['nights']),
    rooms: _int(json['rooms']),
    adults: _int(json['adults']) ?? 1,
    children: _int(json['children']) ?? 0,
    paymentMode: PaymentMode.fromWire(json['paymentMode']),
    depositPercent: readOptionalDouble(json['depositPercent']) ?? 0,
    paymentModes: List.unmodifiable({
      for (final m in json['paymentModes'] is List
          ? json['paymentModes'] as List
          : const [])
        ?PaymentMode.fromWire(m),
    }),
    totalPrice: _money(json['totalPrice'], currency),
    // The cart and checkout say what will be paid now; an order says what
    // was paid.
    payNow: _money(json['payNowAmount'] ?? json['paidNowAmount'], currency),
    payAtVenue: _money(json['payAtVenueAmount'], currency),
    freeUntilDate: readCalendarDate(json['freeUntilDate']),
    cancellationPolicySummary: readOptionalString(
      json['cancellationPolicySummary'],
    ),
    bookingId: readOptionalString(json['bookingId']),
    bookingNumber: readOptionalString(json['bookingNumber']),
    bookingState: BookingState.fromWire(json['state']),
    holdExpiresAt: readDate(json['holdExpiresUtc']),
    guestName: readOptionalString(json['guestName']),
    travellers: List.unmodifiable([
      for (final t in travellers is List ? travellers : const [])
        if (_map(t) case final m?)
          Traveller(
            fullName: readString(m['fullName']),
            type: TravellerType.fromWire(m['type']),
            age: _int(m['age']),
          ),
    ]),
    specialRequests: readOptionalString(json['specialRequests']),
    guestsComplete: readBool(json['guestsComplete']),
    canCancel: readBool(json['canCancel']),
  );
}

/// A checkout session's `serviceLines[]` (§3.2); unreadable entries are
/// left out.
List<ServiceLine> readServiceLines(Object? raw) => List.unmodifiable([
  for (final entry in raw is List ? raw : const []) ?readServiceLine(entry),
]);
