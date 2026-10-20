/// Stays (hotel properties), travel packages and the bookings made on them
/// (bookings contract v1).
library;

import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

int? _wireInt(Object? raw) =>
    raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());

enum ListingKind {
  stay(1),
  package(2);

  const ListingKind(this.wire);
  final int wire;

  static ListingKind? fromWire(Object? raw) {
    final n = _wireInt(raw);
    for (final k in values) {
      if (k.wire == n) return k;
    }
    return null;
  }
}

/// How much the buyer pays online; the listing says which it allows.
enum PaymentMode {
  fullPrepay(1, 'Pay in full now'),
  deposit(2, 'Pay a deposit now'),
  payAtVenue(3, 'Pay at the venue');

  const PaymentMode(this.wire, this.label);
  final int wire;
  final String label;

  bool get paysOnline => this != payAtVenue;

  static PaymentMode? fromWire(Object? raw) {
    final n = _wireInt(raw);
    for (final m in values) {
      if (m.wire == n) return m;
    }
    return null;
  }
}

enum BookingState {
  pendingPayment(1, 'Awaiting payment'),
  confirmed(2, 'Confirmed'),
  checkedIn(3, 'In progress'),
  completed(4, 'Completed'),
  cancelled(5, 'Cancelled'),
  noShow(6, 'No-show'),
  expired(7, 'Expired');

  const BookingState(this.wire, this.label);
  final int wire;
  final String label;

  /// Still ahead of the buyer or under way.
  bool get isLive =>
      this == pendingPayment || this == confirmed || this == checkedIn;

  static BookingState? fromWire(Object? raw) {
    final n = _wireInt(raw);
    for (final s in values) {
      if (s.wire == n) return s;
    }
    return null;
  }
}

enum RefundState {
  none(0),
  pending(1),
  completed(2),
  failed(3);

  const RefundState(this.wire);
  final int wire;

  static RefundState fromWire(Object? raw) {
    final n = _wireInt(raw);
    for (final s in values) {
      if (s.wire == n) return s;
    }
    return none;
  }
}

enum TravellerType {
  adult(1, 'Adult'),
  child(2, 'Child');

  const TravellerType(this.wire, this.label);
  final int wire;
  final String label;

  static TravellerType fromWire(Object? raw) =>
      _wireInt(raw) == 2 ? child : adult;
}

/// The online rails a booking can be paid on. Cash on delivery is never
/// one: paying at the venue is a [PaymentMode], not a rail.
enum BookingPaymentRail {
  eSewa(3, 'eSewa'),
  card(1, 'Visa / Mastercard'),
  payPal(2, 'PayPal');

  const BookingPaymentRail(this.wire, this.label);
  final int wire;
  final String label;
}

class CancellationPolicy {
  const CancellationPolicy({
    required this.freeCancellationDays,
    required this.lateCancellationFeePercent,
    this.freeUntilDate,
    this.summary,
  });

  final int freeCancellationDays;
  final double lateCancellationFeePercent;

  /// Quotes and bookings only: the last Kathmandu date to cancel for free.
  final DateTime? freeUntilDate;

  /// The server's own sentence; preferred over [describe].
  final String? summary;

  /// The server's sentence, or one built from the numbers.
  String describe() {
    final s = summary;
    if (s != null && s.isNotEmpty) return s;
    final fee = lateCancellationFeePercent;
    final feeText = fee == fee.roundToDouble() ? '${fee.toInt()}' : '$fee';
    if (freeCancellationDays <= 0) {
      return fee <= 0
          ? 'Free cancellation until the start date.'
          : 'Cancelling costs $feeText% of the total.';
    }
    final days = freeCancellationDays == 1
        ? '1 day'
        : '$freeCancellationDays days';
    return fee <= 0
        ? 'Free cancellation until $days before the start date.'
        : 'Free cancellation until $days before the start date. After that '
              '$feeText% of the total is charged.';
  }
}

class PriceLine {
  const PriceLine({
    required this.label,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.date,
  });

  final String label;
  final DateTime? date;
  final int quantity;
  final Money unitPrice;
  final Money amount;
}

class PaymentOption {
  const PaymentOption({
    required this.mode,
    required this.payNow,
    required this.payAtVenue,
  });

  final PaymentMode mode;
  final Money payNow;
  final Money payAtVenue;
}

class ServiceVendor {
  const ServiceVendor({required this.id, required this.name, this.logoUrl});

  final String id;
  final String name;
  final String? logoUrl;
}

// ── Stays ────────────────────────────────────────────────────────────────────

class StaySearchItem {
  const StaySearchItem({
    required this.listingId,
    required this.title,
    required this.vendor,
    this.city,
    this.area,
    this.coverPhotoUrl,
    this.starRating,
    this.amenities = const [],
    this.fromPricePerNight,
    this.nights,
    this.totalPrice,
    this.cheapestRoomTypeId,
    this.available = true,
    this.paymentModes = const [],
    this.depositPercent = 0,
    this.latitude,
    this.longitude,
  });

  final String listingId;
  final String title;
  final ServiceVendor? vendor;
  final String? city;
  final String? area;
  final String? coverPhotoUrl;
  final int? starRating;
  final List<String> amenities;
  final Money? fromPricePerNight;
  final int? nights;
  final Money? totalPrice;
  final String? cheapestRoomTypeId;
  final bool available;
  final List<PaymentMode> paymentModes;
  final double depositPercent;

  /// Not in the v1 search item; read when a later version sends them, so
  /// the results map can pin each stay.
  final double? latitude;
  final double? longitude;

  String get place => [?area, ?city].join(', ');
}

class NightlyRate {
  const NightlyRate({
    required this.date,
    required this.price,
    required this.available,
  });

  final DateTime date;
  final Money price;
  final int available;
}

class RoomType {
  const RoomType({
    required this.id,
    required this.name,
    required this.baseRate,
    this.description,
    this.maxAdults = 1,
    this.maxGuests = 1,
    this.beds,
    this.sizeSqm,
    this.photoUrls = const [],
    this.amenities = const [],
    this.availableUnits,
    this.totalPrice,
    this.nightly = const [],
  });

  final String id;
  final String name;
  final String? description;
  final int maxAdults;
  final int maxGuests;
  final String? beds;
  final double? sizeSqm;
  final List<String> photoUrls;
  final List<String> amenities;
  final Money baseRate;

  /// With dates only: the fewest rooms free over the nights, and the price
  /// for the rooms asked for.
  final int? availableUnits;
  final Money? totalPrice;
  final List<NightlyRate> nightly;

  /// Sold out for the dates searched (unknown without dates).
  bool get soldOut => availableUnits != null && availableUnits! <= 0;

  /// Fits [guests] across [rooms] rooms of this type.
  bool fits({required int guests, required int rooms}) =>
      guests <= maxGuests * rooms && rooms >= 1;
}

class StayDetail {
  const StayDetail({
    required this.listingId,
    required this.title,
    required this.cancellationPolicy,
    this.description,
    this.vendor,
    this.city,
    this.area,
    this.addressLine,
    this.latitude,
    this.longitude,
    this.photoUrls = const [],
    this.amenities = const [],
    this.starRating,
    this.checkInTime,
    this.checkOutTime,
    this.minNights = 1,
    this.maxNights,
    this.houseRules,
    this.paymentModes = const [],
    this.depositPercent = 0,
    this.fromPricePerNight,
    this.roomTypes = const [],
  });

  final String listingId;
  final String title;
  final String? description;
  final ServiceVendor? vendor;
  final String? city;
  final String? area;
  final String? addressLine;
  final double? latitude;
  final double? longitude;
  final List<String> photoUrls;
  final List<String> amenities;
  final int? starRating;
  final String? checkInTime;
  final String? checkOutTime;
  final int minNights;
  final int? maxNights;
  final String? houseRules;
  final CancellationPolicy cancellationPolicy;
  final List<PaymentMode> paymentModes;
  final double depositPercent;
  final Money? fromPricePerNight;
  final List<RoomType> roomTypes;

  String get place => [?area, ?city].join(', ');
}

// ── Travel packages ─────────────────────────────────────────────────────────

class PackageSearchItem {
  const PackageSearchItem({
    required this.listingId,
    required this.title,
    this.vendor,
    this.destination,
    this.city,
    this.durationDays,
    this.durationNights,
    this.coverPhotoUrl,
    this.fromPrice,
    this.nextDepartureDate,
    this.departuresInMonth,
    this.paymentModes = const [],
    this.depositPercent = 0,
  });

  final String listingId;
  final String title;
  final ServiceVendor? vendor;
  final String? destination;
  final String? city;
  final int? durationDays;
  final int? durationNights;
  final String? coverPhotoUrl;
  final Money? fromPrice;
  final DateTime? nextDepartureDate;
  final int? departuresInMonth;
  final List<PaymentMode> paymentModes;
  final double depositPercent;
}

class ItineraryDay {
  const ItineraryDay({required this.day, required this.title, this.description});

  final int day;
  final String title;
  final String? description;
}

class Departure {
  const Departure({
    required this.id,
    required this.date,
    required this.seatsAvailable,
    required this.adultPrice,
    this.endDate,
    this.seatsTotal,
    this.childPrice,
    this.open = true,
  });

  final String id;
  final DateTime date;
  final DateTime? endDate;
  final int? seatsTotal;
  final int seatsAvailable;
  final Money adultPrice;

  /// Null: children pay the adult price.
  final Money? childPrice;
  final bool open;

  bool get bookable => open && seatsAvailable > 0;
}

class PackageDetail {
  const PackageDetail({
    required this.listingId,
    required this.title,
    required this.cancellationPolicy,
    this.description,
    this.vendor,
    this.destination,
    this.city,
    this.durationDays,
    this.durationNights,
    this.meetingPoint,
    this.latitude,
    this.longitude,
    this.photoUrls = const [],
    this.itinerary = const [],
    this.inclusions = const [],
    this.exclusions = const [],
    this.maxGroupSize,
    this.paymentModes = const [],
    this.depositPercent = 0,
    this.fromPrice,
    this.departures = const [],
  });

  final String listingId;
  final String title;
  final String? description;
  final ServiceVendor? vendor;
  final String? destination;
  final String? city;
  final int? durationDays;
  final int? durationNights;
  final String? meetingPoint;
  final double? latitude;
  final double? longitude;
  final List<String> photoUrls;
  final List<ItineraryDay> itinerary;
  final List<String> inclusions;
  final List<String> exclusions;
  final int? maxGroupSize;
  final CancellationPolicy cancellationPolicy;
  final List<PaymentMode> paymentModes;
  final double depositPercent;
  final Money? fromPrice;
  final List<Departure> departures;

  String? get durationLabel {
    final d = durationDays;
    if (d == null) return null;
    final n = durationNights;
    return n == null ? '$d days' : '$d days · $n nights';
  }
}

// ── Quotes and bookings ─────────────────────────────────────────────────────

class BookingQuote {
  const BookingQuote({
    required this.listingId,
    required this.kind,
    required this.startDate,
    required this.totalPrice,
    required this.available,
    required this.paymentOptions,
    required this.cancellationPolicy,
    this.roomTypeId,
    this.departureId,
    this.endDate,
    this.nights,
    this.rooms,
    this.adults = 1,
    this.children = 0,
    this.lines = const [],
    this.unavailableReason,
    this.holdMinutes,
  });

  final String listingId;
  final ListingKind kind;
  final String? roomTypeId;
  final String? departureId;
  final DateTime startDate;
  final DateTime? endDate;
  final int? nights;
  final int? rooms;
  final int adults;
  final int children;
  final List<PriceLine> lines;
  final Money totalPrice;
  final bool available;

  /// `sold_out`, `closed`, `capacity`, `min_nights`, `max_nights`,
  /// `departure_closed` — the quote's own "no" when [available] is false.
  final String? unavailableReason;
  final List<PaymentOption> paymentOptions;
  final CancellationPolicy cancellationPolicy;
  final int? holdMinutes;

  int get travellers => adults + children;

  PaymentOption? optionFor(PaymentMode mode) {
    for (final o in paymentOptions) {
      if (o.mode == mode) return o;
    }
    return null;
  }
}

class Traveller {
  const Traveller({required this.fullName, required this.type, this.age});

  final String fullName;
  final TravellerType type;
  final int? age;
}

class Booking {
  const Booking({
    required this.id,
    required this.number,
    required this.kind,
    required this.state,
    required this.listingId,
    required this.listingTitle,
    required this.startDate,
    required this.totalPrice,
    required this.paymentMode,
    required this.payNowAmount,
    required this.paidOnline,
    required this.balanceDue,
    required this.cancellationPolicy,
    this.roomTypeName,
    this.vendor,
    this.endDate,
    this.nights,
    this.rooms,
    this.adults = 1,
    this.children = 0,
    this.guestName,
    this.travellers = const [],
    this.specialRequests,
    this.checkInTime,
    this.checkOutTime,
    this.addressLine,
    this.city,
    this.meetingPoint,
    this.lines = const [],
    this.depositPercent = 0,
    this.holdExpiresAt,
    this.cancelledByBuyer = false,
    this.cancelReason,
    this.cancellationFee,
    this.refundAmount,
    this.refundState = RefundState.none,
    this.createdAt,
    this.canPay = false,
    this.canCancel = false,
    this.orderId,
    this.orderNumber,
  });

  final String id;
  final String number;

  /// The order this booking was bought in (service cart contract v1 §5);
  /// null for a booking made directly. Its pay-now part is paid, and
  /// refunded, through that order's payment.
  final String? orderId;
  final String? orderNumber;
  final ListingKind kind;
  final BookingState state;
  final String listingId;
  final String listingTitle;
  final String? roomTypeName;
  final ServiceVendor? vendor;
  final DateTime startDate;
  final DateTime? endDate;
  final int? nights;
  final int? rooms;
  final int adults;
  final int children;
  final String? guestName;
  final List<Traveller> travellers;
  final String? specialRequests;
  final String? checkInTime;
  final String? checkOutTime;
  final String? addressLine;
  final String? city;
  final String? meetingPoint;
  final List<PriceLine> lines;
  final Money totalPrice;
  final PaymentMode paymentMode;
  final double depositPercent;
  final Money payNowAmount;
  final Money paidOnline;

  /// Still to pay at the venue.
  final Money balanceDue;
  final DateTime? holdExpiresAt;
  final CancellationPolicy cancellationPolicy;
  final bool cancelledByBuyer;
  final String? cancelReason;
  final Money? cancellationFee;
  final Money? refundAmount;
  final RefundState refundState;
  final DateTime? createdAt;
  final bool canPay;
  final bool canCancel;

  int get guests => adults + children;

  /// Upcoming: live and not yet over (by the Kathmandu calendar [today]).
  bool isUpcoming(DateTime today) {
    if (!state.isLive) return false;
    final end = endDate ?? startDate;
    final day = DateTime(today.year, today.month, today.day);
    return !end.isBefore(day);
  }
}

/// What starting a payment handed back: the provider's page to open, or
/// null when the provider needs no hand-off.
class BookingPaymentStart {
  const BookingPaymentStart({
    required this.bookingId,
    required this.amount,
    this.redirectUrl,
  });

  final String bookingId;
  final Money amount;
  final String? redirectUrl;
}

class CancellationQuote {
  const CancellationQuote({
    required this.bookingId,
    required this.cancellable,
    required this.fee,
    required this.refundAmount,
    this.reason,
    this.freeUntilDate,
  });

  final String bookingId;
  final bool cancellable;

  /// `started` or `state` when [cancellable] is false.
  final String? reason;
  final Money fee;
  final Money refundAmount;
  final DateTime? freeUntilDate;
}
