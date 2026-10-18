/// Hotel stays and travel-package bookings as the vendor sees them
/// (service-bookings contract v1). The vendor sees guest and traveller
/// names and special requests only — never the buyer's phone, email or
/// account.
library;

import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `ListingKind`.
enum ServiceListingKind {
  stay(1, 'Stay'),
  package(2, 'Package');

  const ServiceListingKind(this.wire, this.label);
  final int wire;
  final String label;

  static ServiceListingKind fromWire(int value) =>
      value == 2 ? package : stay;
}

/// `BookingState`.
enum BookingState {
  pendingPayment(1, 'Awaiting payment'),
  confirmed(2, 'Confirmed'),
  checkedIn(3, 'Checked in'),
  completed(4, 'Completed'),
  cancelled(5, 'Cancelled'),
  noShow(6, 'No-show'),
  expired(7, 'Expired');

  const BookingState(this.wire, this.label);
  final int wire;
  final String label;

  /// Still to happen or happening: what the day's lists show.
  bool get isLive => this == pendingPayment || this == confirmed || this == checkedIn;

  static BookingState fromWire(int value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return confirmed;
  }

  /// The label for this state on a package ("In progress", not "Checked in").
  String labelFor(ServiceListingKind kind) =>
      kind == ServiceListingKind.package && this == checkedIn
      ? 'In progress'
      : label;
}

/// `PaymentMode`.
enum BookingPaymentMode {
  fullPrepay(1, 'Paid in full online'),
  deposit(2, 'Deposit online, rest at venue'),
  payAtVenue(3, 'Pay at venue');

  const BookingPaymentMode(this.wire, this.label);
  final int wire;
  final String label;

  static BookingPaymentMode? fromWire(int value) {
    for (final m in values) {
      if (m.wire == value) return m;
    }
    return null;
  }
}

/// `RefundState`.
enum BookingRefundState {
  none(0, ''),
  pending(1, 'Refund pending'),
  completed(2, 'Refunded'),
  failed(3, 'Refund failed');

  const BookingRefundState(this.wire, this.label);
  final int wire;
  final String label;

  static BookingRefundState fromWire(int value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return none;
  }
}

class BookingTraveller {
  const BookingTraveller({
    required this.fullName,
    this.isChild = false,
    this.age,
  });

  final String fullName;
  final bool isChild;
  final int? age;
}

class BookingPriceLine {
  const BookingPriceLine({
    required this.label,
    required this.amount,
    this.quantity = 1,
  });

  final String label;
  final int quantity;
  final Money amount;
}

class ServiceBooking {
  const ServiceBooking({
    required this.id,
    required this.number,
    required this.kind,
    required this.state,
    required this.listingTitle,
    required this.guestName,
    required this.total,
    required this.paidOnline,
    required this.balanceDue,
    this.listingId,
    this.roomTypeId,
    this.roomTypeName,
    this.departureId,
    this.startDate,
    this.endDate,
    this.nights = 0,
    this.rooms = 0,
    this.adults = 0,
    this.children = 0,
    this.travellers = const [],
    this.specialRequests,
    this.checkInTime,
    this.checkOutTime,
    this.meetingPoint,
    this.lines = const [],
    this.paymentMode,
    this.depositPercent,
    this.balanceReceivedUtc,
    this.balanceReceivedAmount,
    this.holdExpiresUtc,
    this.cancellationSummary,
    this.cancelledByVendor = false,
    this.cancelledByBuyer = false,
    this.cancelReason,
    this.cancellationFee,
    this.refundAmount,
    this.refundState = BookingRefundState.none,
    this.commissionPercent,
    this.commissionAmount,
    this.vendorNetAmount,
    this.settledUtc,
    this.createdUtc,
    this.canCancel = false,
    this.canCheckIn = false,
    this.canComplete = false,
    this.canMarkNoShow = false,
    this.canMarkBalanceReceived = false,
  });

  final String id;
  final String number;
  final ServiceListingKind kind;
  final BookingState state;
  final String? listingId;
  final String listingTitle;
  final String? roomTypeId;
  final String? roomTypeName;
  final String? departureId;

  /// Kathmandu calendar dates: check-in / check-out, or departure / return.
  final DateTime? startDate;
  final DateTime? endDate;
  final int nights;
  final int rooms;
  final int adults;
  final int children;
  final String guestName;
  final List<BookingTraveller> travellers;
  final String? specialRequests;
  final String? checkInTime;
  final String? checkOutTime;
  final String? meetingPoint;
  final List<BookingPriceLine> lines;
  final Money total;
  final BookingPaymentMode? paymentMode;
  final int? depositPercent;
  final Money paidOnline;

  /// Still to collect at the venue.
  final Money balanceDue;
  final DateTime? balanceReceivedUtc;
  final Money? balanceReceivedAmount;
  final DateTime? holdExpiresUtc;
  final String? cancellationSummary;
  final bool cancelledByVendor;
  final bool cancelledByBuyer;
  final String? cancelReason;
  final Money? cancellationFee;
  final Money? refundAmount;
  final BookingRefundState refundState;
  final double? commissionPercent;
  final Money? commissionAmount;
  final Money? vendorNetAmount;
  final DateTime? settledUtc;
  final DateTime? createdUtc;
  final bool canCancel;
  final bool canCheckIn;
  final bool canComplete;
  final bool canMarkNoShow;
  final bool canMarkBalanceReceived;

  bool get isStay => kind == ServiceListingKind.stay;
  int get guests => adults + children;

  /// "Deluxe Double" for a stay, "Package" for a package.
  String get itemName => roomTypeName ?? (isStay ? 'Room' : 'Package');

  /// "2 adults, 1 child".
  String get guestsText {
    final parts = <String>[
      if (adults > 0) '$adults ${adults == 1 ? 'adult' : 'adults'}',
      if (children > 0) '$children ${children == 1 ? 'child' : 'children'}',
    ];
    return parts.isEmpty ? '' : parts.join(', ');
  }

  /// What the vendor refunds on cancelling: everything paid online (a
  /// vendor cancellation never charges the fee — contract §2).
  Money get vendorCancelRefund => paidOnline;

  bool get hasBalanceToCollect => balanceDue.amount > 0;
}

/// `GET v1/vendor/bookings/summary`.
class BookingsSummary {
  const BookingsSummary({
    required this.upcoming,
    required this.inHouse,
    required this.pendingPayment,
    required this.balanceToCollect,
  });

  final int upcoming;
  final int inHouse;
  final int pendingPayment;
  final Money balanceToCollect;
}

/// One room type of a stay listing, for the availability view.
class VendorRoomType {
  const VendorRoomType({
    required this.id,
    required this.name,
    required this.totalUnits,
    this.archived = false,
  });

  final String id;
  final String name;
  final int totalUnits;
  final bool archived;
}

/// `ListingStatus`.
enum ServiceListingStatus {
  draft(1, 'Draft'),
  published(2, 'Published'),
  paused(3, 'Paused'),
  archived(4, 'Archived');

  const ServiceListingStatus(this.wire, this.label);
  final int wire;
  final String label;

  static ServiceListingStatus fromWire(int value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return draft;
  }
}

/// A vendor listing, reduced to what the availability view needs.
class VendorListing {
  const VendorListing({
    required this.id,
    required this.kind,
    required this.title,
    required this.status,
    this.roomTypes = const [],
  });

  final String id;
  final ServiceListingKind kind;
  final String title;
  final ServiceListingStatus status;
  final List<VendorRoomType> roomTypes;
}

/// `CalendarDay` (vendor): one night of one room type.
class RoomNight {
  const RoomNight({
    required this.date,
    required this.totalUnits,
    required this.booked,
    required this.held,
    required this.available,
    required this.closed,
    this.price,
  });

  final DateTime date;
  final int totalUnits;
  final int booked;
  final int held;
  final int available;
  final bool closed;
  final double? price;
}

/// `DepartureStatus`.
enum DepartureStatus {
  open(1, 'Open'),
  closed(2, 'Closed'),
  cancelled(3, 'Cancelled');

  const DepartureStatus(this.wire, this.label);
  final int wire;
  final String label;

  static DepartureStatus fromWire(int value) {
    for (final s in values) {
      if (s.wire == value) return s;
    }
    return open;
  }
}

/// `DepartureVendor`.
class VendorDeparture {
  const VendorDeparture({
    required this.id,
    required this.status,
    required this.seatsTotal,
    required this.seatsAvailable,
    this.date,
    this.endDate,
    this.seatsBooked = 0,
    this.bookings = 0,
  });

  final String id;
  final DateTime? date;
  final DateTime? endDate;
  final DepartureStatus status;
  final int seatsTotal;
  final int seatsAvailable;
  final int seatsBooked;
  final int bookings;
}
