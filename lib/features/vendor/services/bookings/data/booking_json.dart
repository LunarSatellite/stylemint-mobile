import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// JSON → booking entities (service-bookings contract v1, §2). Tolerant: an
/// odd field reads as empty; a row without an id is unreadable.

int _enumInt(Object? raw) {
  final value = normalizeWireEnum(raw);
  return value is int ? value : 0;
}

String _requireId(Map<String, dynamic> json, String key) {
  final id = readOptionalString(json[key]);
  if (id == null) throw FormatException('No $key');
  return id;
}

ServiceBooking readServiceBooking(Map<String, dynamic> json) {
  final currency = readOptionalString(json['currency']) ?? 'NPR';
  Money money(double amount) => Money(amount: amount, currency: currency);
  Money? optionalMoney(Object? raw) {
    final value = readOptionalDouble(raw);
    return value == null ? null : money(value);
  }

  final rawTravellers = json['travellers'];
  final rawLines = json['lines'];
  final policy = json['cancellationPolicy'];
  final cancelledBy = _enumInt(json['cancelledBy']);
  final total = readOptionalDouble(json['totalPrice']) ?? 0;
  final paidOnline = readOptionalDouble(json['paidOnline']) ?? 0;
  final received = readOptionalDouble(json['balanceReceivedAmount']);
  final balanceDue =
      readOptionalDouble(json['balanceDue']) ??
      (total - paidOnline - (received ?? 0)).clamp(0, double.infinity)
          .toDouble();
  final percent = readOptionalDouble(json['commissionPercent']);

  return ServiceBooking(
    id: _requireId(json, 'id'),
    number: readString(json['number']),
    kind: ServiceListingKind.fromWire(_enumInt(json['kind'])),
    state: BookingState.fromWire(_enumInt(json['state'])),
    listingId: readOptionalString(json['listingId']),
    listingTitle: readString(json['listingTitle']),
    roomTypeId: readOptionalString(json['roomTypeId']),
    roomTypeName: readOptionalString(json['roomTypeName']),
    departureId: readOptionalString(json['departureId']),
    startDate: readWireDate(json['startDate']),
    endDate: readWireDate(json['endDate']),
    nights: readInt(json['nights']),
    rooms: readInt(json['rooms']),
    adults: readInt(json['adults']),
    children: readInt(json['children']),
    guestName: readOptionalString(json['guestName']) ?? 'Guest',
    travellers: List.unmodifiable(<BookingTraveller>[
      if (rawTravellers is List)
        for (final t in rawTravellers)
          if (t is Map && readOptionalString(t['fullName']) != null)
            BookingTraveller(
              fullName: readString(t['fullName']),
              isChild: _enumInt(t['type']) == 2,
              age: t['age'] is num ? (t['age'] as num).toInt() : null,
            ),
    ]),
    specialRequests: readOptionalString(json['specialRequests']),
    checkInTime: readOptionalString(json['checkInTime']),
    checkOutTime: readOptionalString(json['checkOutTime']),
    meetingPoint: readOptionalString(json['meetingPoint']),
    lines: List.unmodifiable(<BookingPriceLine>[
      if (rawLines is List)
        for (final l in rawLines)
          if (l is Map)
            BookingPriceLine(
              label: readString(l['label']),
              quantity: readInt(l['quantity']),
              amount: money(readOptionalDouble(l['amount']) ?? 0),
            ),
    ]),
    total: money(total),
    paymentMode: BookingPaymentMode.fromWire(_enumInt(json['paymentMode'])),
    depositPercent: json['depositPercent'] is num
        ? (json['depositPercent'] as num).toInt()
        : null,
    paidOnline: money(paidOnline),
    balanceDue: money(balanceDue),
    balanceReceivedUtc: readDate(json['balanceReceivedUtc']),
    balanceReceivedAmount: received == null ? null : money(received),
    holdExpiresUtc: readDate(json['holdExpiresUtc']),
    cancellationSummary: policy is Map
        ? readOptionalString(policy['summary'])
        : null,
    cancelledByBuyer: cancelledBy == 1,
    cancelledByVendor: cancelledBy == 2,
    cancelReason: readOptionalString(json['cancelReason']),
    cancellationFee: optionalMoney(json['cancellationFee']),
    refundAmount: optionalMoney(json['refundAmount']),
    refundState: BookingRefundState.fromWire(_enumInt(json['refundState'])),
    commissionPercent: percent,
    commissionAmount: optionalMoney(json['commissionAmount']),
    vendorNetAmount: optionalMoney(json['vendorNetAmount']),
    settledUtc: readDate(json['settledUtc']),
    createdUtc: readDate(json['createdUtc']),
    canCancel: readBool(json['canCancel']),
    canCheckIn: readBool(json['canCheckIn']),
    canComplete: readBool(json['canComplete']),
    canMarkNoShow: readBool(json['canMarkNoShow']),
    canMarkBalanceReceived: readBool(json['canMarkBalanceReceived']),
  );
}

BookingsSummary readBookingsSummary(Map<String, dynamic> json) =>
    BookingsSummary(
      upcoming: readInt(json['upcoming']),
      inHouse: readInt(json['inHouse']),
      pendingPayment: readInt(json['pendingPayment']),
      balanceToCollect: Money(
        amount: readOptionalDouble(json['balanceToCollect']) ?? 0,
        currency: readOptionalString(json['currency']) ?? 'NPR',
      ),
    );

VendorListing readVendorListing(Map<String, dynamic> json) {
  final rawRooms = json['roomTypes'];
  return VendorListing(
    id: _requireId(json, json.containsKey('listingId') ? 'listingId' : 'id'),
    kind: ServiceListingKind.fromWire(_enumInt(json['kind'])),
    title: readString(json['title']),
    status: ServiceListingStatus.fromWire(_enumInt(json['status'])),
    roomTypes: List.unmodifiable(<VendorRoomType>[
      if (rawRooms is List)
        for (final r in rawRooms)
          if (r is Map &&
              readOptionalString(r['roomTypeId'] ?? r['id']) != null)
            VendorRoomType(
              id: readString(r['roomTypeId'] ?? r['id']),
              name: readString(r['name']),
              totalUnits: readInt(r['totalUnits']),
              archived: _enumInt(r['status']) == 2,
            ),
    ]),
  );
}

RoomNight readRoomNight(Map<String, dynamic> json) {
  final date = readWireDate(json['date']);
  if (date == null) throw const FormatException('No date');
  return RoomNight(
    date: date,
    totalUnits: readInt(json['totalUnits']),
    booked: readInt(json['booked']),
    held: readInt(json['held']),
    available: readInt(json['available']),
    closed: readBool(json['closed']),
    price: readOptionalDouble(json['price']),
  );
}

VendorDeparture readVendorDeparture(Map<String, dynamic> json) =>
    VendorDeparture(
      id: _requireId(
        json,
        json.containsKey('departureId') ? 'departureId' : 'id',
      ),
      date: readWireDate(json['date']),
      endDate: readWireDate(json['endDate']),
      status: DepartureStatus.fromWire(_enumInt(json['status'])),
      seatsTotal: readInt(json['seatsTotal']),
      seatsAvailable: readInt(json['seatsAvailable']),
      seatsBooked: readInt(json['seatsBooked']),
      bookings: readInt(json['bookings']),
    );
