/// A stay or trip bought like an item: one cart line, one checkout service
/// line, or one booking line of an order (service cart contract v1 §2.2,
/// §3.2, §4.1). The three payloads carry the same booking options; the
/// later ones add the booking itself (number, state, guests).
library;

import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class ServiceLine {
  const ServiceLine({
    required this.kind,
    required this.listingId,
    required this.listingTitle,
    required this.startDate,
    required this.totalPrice,
    required this.payNow,
    required this.payAtVenue,
    this.lineId,
    this.itemName,
    this.roomTypeId,
    this.departureId,
    this.endDate,
    this.nights,
    this.rooms,
    this.adults = 1,
    this.children = 0,
    this.paymentMode,
    this.depositPercent = 0,
    this.paymentModes = const [],
    this.freeUntilDate,
    this.cancellationPolicySummary,
    this.bookingId,
    this.bookingNumber,
    this.bookingState,
    this.holdExpiresAt,
    this.guestName,
    this.travellers = const [],
    this.specialRequests,
    this.guestsComplete = false,
    this.canCancel = false,
  });

  /// The cart line (and checkout `serviceLines[].lineId`); null on an order.
  final String? lineId;
  final ListingKind kind;
  final String listingId;
  final String listingTitle;

  /// The room type ("Deluxe Double") or the trip's name for the departure.
  final String? itemName;
  final String? roomTypeId;
  final String? departureId;

  /// Check-in, or the departure date (Kathmandu calendar).
  final DateTime startDate;

  /// Check-out, or the trip's last day.
  final DateTime? endDate;
  final int? nights;
  final int? rooms;
  final int adults;
  final int children;

  /// Null on a payload this build does not recognise; shown as unknown.
  final PaymentMode? paymentMode;
  final double depositPercent;

  /// The ways to pay the listing allows (cart lines only).
  final List<PaymentMode> paymentModes;

  /// The full booking price.
  final Money totalPrice;

  /// Paid online through StyleMint: the cart's and checkout's "pay now", the
  /// order's "paid now".
  final Money payNow;

  /// Paid to the hotel or agency, never through StyleMint.
  final Money payAtVenue;
  final DateTime? freeUntilDate;
  final String? cancellationPolicySummary;

  // ── The booking (checkout and orders) ──────────────────────────────────
  final String? bookingId;
  final String? bookingNumber;
  final BookingState? bookingState;

  /// Checkout only: when the held rooms or seats are released.
  final DateTime? holdExpiresAt;
  final String? guestName;
  final List<Traveller> travellers;
  final String? specialRequests;

  /// Checkout only: the guest (and every traveller) is named.
  final bool guestsComplete;

  /// Orders only: the buyer may cancel this booking now.
  final bool canCancel;

  bool get isStay => kind == ListingKind.stay;
  int get guests => adults + children;

  /// Whether this line already books what [options] asks for: the same
  /// listing, room and dates (or departure), rooms and guests, and the same
  /// way to pay when both name one. Buy now uses it so a booking already in
  /// the cart is not added a second time.
  bool sameChoiceAs(ServiceOptions options) {
    if (kind != options.kind || listingId != options.listingId) return false;
    if (adults != options.adults || children != options.children) {
      return false;
    }
    final mode = paymentMode;
    final wanted = options.paymentMode;
    if (mode != null && wanted != null && mode != wanted) return false;
    if (kind == ListingKind.package) {
      return departureId != null && departureId == options.departureId;
    }
    return roomTypeId != null &&
        roomTypeId == options.roomTypeId &&
        (rooms ?? 1) == (options.rooms ?? 1) &&
        _sameDay(startDate, options.checkIn) &&
        _sameDay(endDate, options.checkOut);
  }

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a != null &&
      b != null &&
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;
}

/// What the buyer chose on a service item's page, sent with Add to cart
/// (service cart contract v1 §2.1 `serviceOptions`). A stay names a room
/// type, dates and rooms; a trip names a departure.
class ServiceOptions {
  const ServiceOptions.stay({
    required this.listingId,
    required String this.roomTypeId,
    required DateTime this.checkIn,
    required DateTime this.checkOut,
    required int this.rooms,
    required this.adults,
    this.children = 0,
    this.paymentMode,
  }) : kind = ListingKind.stay,
       departureId = null;

  const ServiceOptions.package({
    required this.listingId,
    required String this.departureId,
    required this.adults,
    this.children = 0,
    this.paymentMode,
  }) : kind = ListingKind.package,
       roomTypeId = null,
       checkIn = null,
       checkOut = null,
       rooms = null;

  final ListingKind kind;
  final String listingId;
  final String? roomTypeId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? rooms;
  final String? departureId;
  final int adults;
  final int children;

  /// Null lets the server pick: full prepay if offered, else deposit, else
  /// pay at the venue.
  final PaymentMode? paymentMode;

  int get nights => checkIn == null || checkOut == null
      ? 0
      : checkOut!.difference(checkIn!).inDays;
}

/// The names checkout collects for one service line (service cart contract
/// v1 §3.3): who the stay is under, every traveller on a trip (adults then
/// children), and any request for the hotel or agency. The vendor sees these
/// names, never the buyer's phone or email.
class ServiceGuests {
  const ServiceGuests({
    required this.lineId,
    required this.guestName,
    this.travellers = const [],
    this.specialRequests,
  });

  final String lineId;
  final String guestName;
  final List<Traveller> travellers;
  final String? specialRequests;
}
