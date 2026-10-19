import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/data/vendor_bookings_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/domain/service_booking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_page.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_time.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:uuid/uuid.dart';

/// What the front desk needs today.
class BookingsTodayBoard {
  const BookingsTodayBoard({
    required this.arrivals,
    required this.leaving,
    required this.inHouse,
  });

  /// Starting today and not yet checked in (or already checked in today).
  final List<ServiceBooking> arrivals;

  /// Checked in and ending today: checking out / finishing the trip.
  final List<ServiceBooking> leaving;

  /// Checked in, ending after today.
  final List<ServiceBooking> inHouse;

  bool get isEmpty => arrivals.isEmpty && leaving.isEmpty && inHouse.isEmpty;
}

abstract class VendorBookingsRepository {
  Future<Either<ServiceFailure, BookingsSummary>> getSummary();

  Future<Either<ServiceFailure, BookingsTodayBoard>> getToday(DateTime today);

  /// Live bookings starting after today, within [days], by start date.
  Future<Either<ServiceFailure, List<ServiceBooking>>> getUpcoming(
    DateTime today, {
    int days = 30,
  });

  /// Every booking, newest first, by state and search.
  Future<Either<ServiceFailure, ServicePage<ServiceBooking>>> listBookings({
    BookingState? state,
    String? query,
    String? cursor,
  });

  Future<Either<ServiceFailure, ServiceBooking>> getBooking(String bookingId);

  Future<Either<ServiceFailure, ServiceBooking>> checkIn(String bookingId);

  Future<Either<ServiceFailure, ServiceBooking>> complete(String bookingId);

  Future<Either<ServiceFailure, ServiceBooking>> markNoShow(String bookingId);

  /// [amount] null = the whole balance due.
  Future<Either<ServiceFailure, ServiceBooking>> markBalanceReceived(
    String bookingId, {
    double? amount,
    String? note,
  });

  Future<Either<ServiceFailure, ServiceBooking>> cancel(
    String bookingId,
    String reason,
  );

  Future<Either<ServiceFailure, List<VendorListing>>> listListings(
    ServiceListingKind kind,
  );

  Future<Either<ServiceFailure, List<RoomNight>>> getCalendar(
    String roomTypeId, {
    required DateTime from,
    required DateTime to,
  });

  /// Stop-sell (or reopen) one night of one room type.
  Future<Either<ServiceFailure, List<RoomNight>>> setNightClosed(
    String roomTypeId,
    DateTime date, {
    required bool closed,
  });

  Future<Either<ServiceFailure, List<VendorDeparture>>> listDepartures(
    String listingId, {
    required DateTime from,
  });

  /// Close a departure to new bookings, or reopen it.
  Future<Either<ServiceFailure, VendorDeparture>> setDepartureClosed(
    String departureId, {
    required bool closed,
  });
}

class VendorBookingsRepositoryImpl implements VendorBookingsRepository {
  VendorBookingsRepositoryImpl(this._remote);

  final VendorBookingsRemoteDataSource _remote;

  static const _uuid = Uuid();
  static const _maxPages = 6;

  Future<List<ServiceBooking>> _all({
    int? state,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = <ServiceBooking>[];
    String? cursor;
    for (var page = 0; page < _maxPages; page++) {
      final result = await _remote.listBookings(
        state: state,
        from: from,
        to: to,
        cursor: cursor,
      );
      all.addAll(result.items);
      cursor = result.nextCursor;
      if (cursor == null) break;
    }
    return all;
  }

  static int _byStart(ServiceBooking a, ServiceBooking b) {
    final x = a.startDate, y = b.startDate;
    if (x == null || y == null) return a.number.compareTo(b.number);
    final c = x.compareTo(y);
    return c != 0 ? c : a.guestName.compareTo(b.guestName);
  }

  @override
  Future<Either<ServiceFailure, BookingsSummary>> getSummary() =>
      guardedServiceCall(_remote.getSummary);

  @override
  Future<Either<ServiceFailure, BookingsTodayBoard>> getToday(
    DateTime today,
  ) => guardedServiceCall(() async {
    final starting = await _all(from: today, to: today);
    final checkedIn = await _all(state: BookingState.checkedIn.wire);
    final arrivals = <ServiceBooking>[
      for (final b in starting)
        if (b.state == BookingState.pendingPayment ||
            b.state == BookingState.confirmed ||
            (b.state == BookingState.checkedIn &&
                !_endsOn(b, today)))
          b,
    ]..sort(_byStart);
    final leaving = <ServiceBooking>[
      for (final b in checkedIn)
        if (_endsOn(b, today) || _endedBefore(b, today)) b,
    ]..sort(_byStart);
    final arrivalIds = {for (final b in arrivals) b.id};
    final inHouse = <ServiceBooking>[
      for (final b in checkedIn)
        if (!_endsOn(b, today) &&
            !_endedBefore(b, today) &&
            !arrivalIds.contains(b.id))
          b,
    ]..sort(_byStart);
    return BookingsTodayBoard(
      arrivals: List.unmodifiable(arrivals),
      leaving: List.unmodifiable(leaving),
      inHouse: List.unmodifiable(inHouse),
    );
  });

  static bool _endsOn(ServiceBooking b, DateTime day) {
    final end = b.endDate;
    return end != null && daysBetween(day, end) == 0;
  }

  /// Checked in but past the end date: still to check out (auto-complete
  /// runs a day later).
  static bool _endedBefore(ServiceBooking b, DateTime day) {
    final end = b.endDate;
    return end != null && daysBetween(day, end) < 0;
  }

  @override
  Future<Either<ServiceFailure, List<ServiceBooking>>> getUpcoming(
    DateTime today, {
    int days = 30,
  }) => guardedServiceCall(() async {
    final items = await _all(
      from: today.add(const Duration(days: 1)),
      to: today.add(Duration(days: days)),
    );
    return List<ServiceBooking>.unmodifiable(
      <ServiceBooking>[
        for (final b in items)
          if (b.state.isLive) b,
      ]..sort(_byStart),
    );
  });

  @override
  Future<Either<ServiceFailure, ServicePage<ServiceBooking>>> listBookings({
    BookingState? state,
    String? query,
    String? cursor,
  }) => guardedServiceCall(
    () => _remote.listBookings(
      state: state?.wire,
      query: query?.trim(),
      cursor: cursor,
      pageSize: 20,
    ),
  );

  @override
  Future<Either<ServiceFailure, ServiceBooking>> getBooking(
    String bookingId,
  ) => guardedServiceCall(() => _remote.getBooking(bookingId));

  Future<Either<ServiceFailure, ServiceBooking>> _action(
    String bookingId,
    String action, [
    Map<String, dynamic>? data,
  ]) => guardedServiceCall(
    () => _remote.bookingAction(
      bookingId,
      action,
      idempotencyKey: _uuid.v4(),
      data: data,
    ),
  );

  @override
  Future<Either<ServiceFailure, ServiceBooking>> checkIn(String bookingId) =>
      _action(bookingId, 'check-in');

  @override
  Future<Either<ServiceFailure, ServiceBooking>> complete(String bookingId) =>
      _action(bookingId, 'complete');

  @override
  Future<Either<ServiceFailure, ServiceBooking>> markNoShow(
    String bookingId,
  ) => _action(bookingId, 'no-show');

  @override
  Future<Either<ServiceFailure, ServiceBooking>> markBalanceReceived(
    String bookingId, {
    double? amount,
    String? note,
  }) => _action(bookingId, 'balance-received', <String, dynamic>{
    'amount': ?amount,
    if (note != null && note.isNotEmpty) 'note': note,
  });

  @override
  Future<Either<ServiceFailure, ServiceBooking>> cancel(
    String bookingId,
    String reason,
  ) => _action(bookingId, 'cancel', <String, dynamic>{'reason': reason});

  @override
  Future<Either<ServiceFailure, List<VendorListing>>> listListings(
    ServiceListingKind kind,
  ) => guardedServiceCall(() async {
    final listings = await _remote.listListings(kind: kind.wire);
    return List<VendorListing>.unmodifiable([
      for (final l in listings)
        if (l.kind == kind && l.status != ServiceListingStatus.archived) l,
    ]);
  });

  @override
  Future<Either<ServiceFailure, List<RoomNight>>> getCalendar(
    String roomTypeId, {
    required DateTime from,
    required DateTime to,
  }) => guardedServiceCall(
    () => _remote.getCalendar(roomTypeId, from: from, to: to),
  );

  @override
  Future<Either<ServiceFailure, List<RoomNight>>> setNightClosed(
    String roomTypeId,
    DateTime date, {
    required bool closed,
  }) => guardedServiceCall(
    () => _remote.setNightsClosed(
      roomTypeId,
      from: date,
      to: date,
      closed: closed,
      idempotencyKey: _uuid.v4(),
    ),
  );

  @override
  Future<Either<ServiceFailure, List<VendorDeparture>>> listDepartures(
    String listingId, {
    required DateTime from,
  }) => guardedServiceCall(
    () => _remote.listDepartures(listingId, from: from),
  );

  @override
  Future<Either<ServiceFailure, VendorDeparture>> setDepartureClosed(
    String departureId, {
    required bool closed,
  }) => guardedServiceCall(
    () => _remote.departureAction(
      departureId,
      closed ? 'close' : 'reopen',
      idempotencyKey: _uuid.v4(),
    ),
  );
}

/// Sentences for the bookings error codes (contract §6).
String? bookingErrorMessage(String code) => switch (code) {
  'booking.not_found' => 'This booking is no longer available.',
  'booking.invalid_transition' =>
    'This booking has moved on. Pull to refresh.',
  'booking.too_early' => 'You can do this from the start date.',
  'booking.not_cancellable' => 'This booking can no longer be cancelled.',
  'booking.balance_not_due' =>
    'There is nothing left to collect, or the amount is more than the '
        'balance.',
  'booking.refund_failed' =>
    'The refund could not be sent. StyleMint will retry it.',
  'service_vendor.category_mismatch' =>
    'This is only for approved hotels and travel agencies.',
  'departure.invalid_transition' => 'This departure has changed. Refresh.',
  'room_type.invalid' => 'That date cannot be changed.',
  _ => null,
};

/// A money amount in the booking's currency.
Money bookingMoney(ServiceBooking b, double amount) =>
    Money(amount: amount, currency: b.total.currency);
