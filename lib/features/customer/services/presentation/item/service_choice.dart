import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_search.dart';

/// What the buyer is choosing on a stay or trip's item page — in place of
/// size and colour: dates, a room type and how many rooms and guests for a
/// stay; a departure and how many adults and children for a trip; and,
/// once priced, how to pay.
///
/// Shared by the page's options section and its Add to cart bar, the way
/// the product page shares a `ProductOptionChooser`. The price the bar shows
/// is the server's [quote] for exactly this choice; nothing is priced here.
class ServiceChoice extends ChangeNotifier {
  ServiceChoice({
    required this.item,
    required DateTime today,
    ServiceLine? from,
  }) : _today = DateTime(today.year, today.month, today.day) {
    final start = _today.add(const Duration(days: 1));
    _checkIn = start;
    _checkOut = start.add(Duration(days: item.stay?.minNights ?? 1));
    if (from != null) _prefill(from);
  }

  final ServiceItem item;
  final DateTime _today;

  late DateTime _checkIn;
  late DateTime _checkOut;
  int _rooms = 1;
  int _adults = 2;
  int _children = 0;
  String? _roomTypeId;
  String? _departureId;
  PaymentMode? _paymentMode;

  BookingQuote? _quote;
  bool _quoting = false;
  String? _error;

  bool get isStay => item.type == ServiceItemType.stay;
  DateTime get today => _today;
  DateTime get checkIn => _checkIn;
  DateTime get checkOut => _checkOut;
  int get nights => _checkOut.difference(_checkIn).inDays;
  int get rooms => _rooms;
  int get adults => _adults;
  int get children => _children;
  int get guests => _adults + _children;
  String? get roomTypeId => _roomTypeId;
  String? get departureId => _departureId;

  /// The way to pay the buyer picked, else the quote's first (the server's
  /// own order: full prepay, deposit, pay at the venue).
  PaymentMode? get paymentMode =>
      _paymentMode ?? _quote?.paymentOptions.firstOrNull?.mode;
  BookingQuote? get quote => _quote;
  bool get quoting => _quoting;

  /// Why the choice cannot be added: the quote's "no", or a failed call.
  String? get error => _error;

  /// The quote's figures for [paymentMode].
  PaymentOption? get paymentOption {
    final mode = paymentMode;
    return mode == null ? null : _quote?.optionFor(mode);
  }

  /// The stay search these dates and guests make, for the per-room prices
  /// and availability of the stay's detail (service items contract v1 §4
  /// links.detail).
  StaySearch get staySearch => StaySearch(
    location: '',
    checkIn: _checkIn,
    checkOut: _checkOut,
    guests: guests,
    rooms: _rooms,
  );

  /// The stay's night rules, when its detail says them.
  String? get nightsProblem {
    final stay = item.stay;
    if (!isStay || stay == null) return null;
    if (nights < stay.minNights ||
        (stay.maxNights != null && nights > stay.maxNights!)) {
      return stay.maxNights == null
          ? 'Stays here are at least ${stay.minNights} nights.'
          : 'Stays here are ${stay.minNights}–${stay.maxNights} nights.';
    }
    return null;
  }

  /// Something to price: a room or a departure, and at least one adult.
  bool get isComplete =>
      _adults >= 1 &&
      (isStay
          ? _roomTypeId != null && nights >= 1 && nightsProblem == null
          : _departureId != null);

  /// Ready for Add to cart: complete, and the server priced it as available.
  bool get canAdd =>
      isComplete && !_quoting && _quote != null && _quote!.available;

  /// The cart's `serviceOptions` for this choice (null until complete).
  ServiceOptions? toOptions() {
    if (!isComplete) return null;
    return isStay
        ? ServiceOptions.stay(
            listingId: item.listingId,
            roomTypeId: _roomTypeId!,
            checkIn: _checkIn,
            checkOut: _checkOut,
            rooms: _rooms,
            adults: _adults,
            children: _children,
            paymentMode: paymentMode,
          )
        : ServiceOptions.package(
            listingId: item.listingId,
            departureId: _departureId!,
            adults: _adults,
            children: _children,
            paymentMode: paymentMode,
          );
  }

  // ── Changes ──────────────────────────────────────────────────────────

  void setDates(DateTime checkIn, DateTime checkOut) {
    final start = DateTime(checkIn.year, checkIn.month, checkIn.day);
    var end = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (!end.isAfter(start)) end = start.add(const Duration(days: 1));
    _checkIn = start;
    _checkOut = end;
    _changed();
  }

  void setRooms(int value) => _set(() => _rooms = value.clamp(1, 10));
  void setAdults(int value) => _set(() => _adults = value.clamp(1, 50));
  void setChildren(int value) => _set(() => _children = value.clamp(0, 50));
  void selectRoom(String? id) => _set(() => _roomTypeId = id);
  void selectDeparture(String? id) => _set(() => _departureId = id);

  /// Changing how to pay keeps the quote: it priced every allowed mode.
  void selectPaymentMode(PaymentMode mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void _set(VoidCallback change) {
    change();
    _changed();
  }

  /// Any change to what is booked makes the old price stale.
  void _changed() {
    _quote = null;
    _error = null;
    _quoting = false;
    _quoteGeneration++;
    notifyListeners();
  }

  // ── Pricing ──────────────────────────────────────────────────────────

  int _quoteGeneration = 0;

  /// Prices the current choice with [fetch] (the Bookings quote). A reply to
  /// an older choice is dropped: the buyer has moved on.
  Future<void> price(
    Future<({BookingQuote? quote, String? error})> Function(ServiceChoice)
    fetch,
  ) async {
    if (!isComplete) return;
    final generation = ++_quoteGeneration;
    _quoting = true;
    _error = null;
    notifyListeners();
    final result = await fetch(this);
    if (generation != _quoteGeneration) return;
    _quoting = false;
    _quote = result.quote;
    _error = result.error;
    final allowed = result.quote?.paymentOptions.map((o) => o.mode);
    if (_paymentMode != null && !(allowed?.contains(_paymentMode) ?? true)) {
      _paymentMode = null;
    }
    notifyListeners();
  }

  void _prefill(ServiceLine line) {
    _adults = line.adults < 1 ? 1 : line.adults;
    _children = line.children;
    _paymentMode = line.paymentMode;
    if (line.isStay) {
      _roomTypeId = line.roomTypeId;
      _rooms = line.rooms ?? 1;
      if (!line.startDate.isBefore(_today)) _checkIn = line.startDate;
      final end = line.endDate;
      _checkOut = end != null && end.isAfter(_checkIn)
          ? end
          : _checkIn.add(const Duration(days: 1));
    } else {
      _departureId = line.departureId;
    }
  }
}
