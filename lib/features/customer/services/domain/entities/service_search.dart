/// What a buyer searches stays and travel packages with. Plain values, so a
/// search travels in a route's query string and back.
library;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _parseDay(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final parsed = DateTime.tryParse(raw.trim());
  return parsed == null ? null : _day(parsed);
}

String _wire(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

int _int(String? raw, int fallback, {int min = 0}) {
  final value = int.tryParse(raw?.trim() ?? '');
  return value == null || value < min ? fallback : value;
}

class StaySearch {
  StaySearch({
    required this.location,
    required DateTime checkIn,
    required DateTime checkOut,
    this.guests = 2,
    this.rooms = 1,
  }) : checkIn = _day(checkIn),
       checkOut = _day(checkOut);

  /// Tomorrow for one night, two guests, one room.
  factory StaySearch.initial(DateTime today) {
    final start = _day(today).add(const Duration(days: 1));
    return StaySearch(
      location: '',
      checkIn: start,
      checkOut: start.add(const Duration(days: 1)),
    );
  }

  /// From a results route's query; null when the dates are missing.
  static StaySearch? fromQuery(Map<String, String> q) {
    final checkIn = _parseDay(q['checkIn']);
    final checkOut = _parseDay(q['checkOut']);
    if (checkIn == null || checkOut == null) return null;
    return StaySearch(
      location: q['q']?.trim() ?? '',
      checkIn: checkIn,
      checkOut: checkOut,
      guests: _int(q['guests'], 2, min: 1),
      rooms: _int(q['rooms'], 1, min: 1),
    );
  }

  /// City or area typed by the buyer; may be empty (anywhere).
  final String location;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int rooms;

  int get nights => checkOut.difference(checkIn).inDays;

  /// Check-out after check-in, and at least one guest per room.
  bool get isValid => nights >= 1 && rooms >= 1 && guests >= rooms;

  Map<String, String> toQuery() => {
    if (location.trim().isNotEmpty) 'q': location.trim(),
    'checkIn': _wire(checkIn),
    'checkOut': _wire(checkOut),
    'guests': '$guests',
    'rooms': '$rooms',
  };

  StaySearch copyWith({
    String? location,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guests,
    int? rooms,
  }) => StaySearch(
    location: location ?? this.location,
    checkIn: checkIn ?? this.checkIn,
    checkOut: checkOut ?? this.checkOut,
    guests: guests ?? this.guests,
    rooms: rooms ?? this.rooms,
  );

  @override
  bool operator ==(Object other) =>
      other is StaySearch &&
      other.location == location &&
      other.checkIn == checkIn &&
      other.checkOut == checkOut &&
      other.guests == guests &&
      other.rooms == rooms;

  @override
  int get hashCode => Object.hash(location, checkIn, checkOut, guests, rooms);
}

class TravelSearch {
  const TravelSearch({
    this.destination = '',
    this.month,
    this.travellers = 2,
  });

  static TravelSearch fromQuery(Map<String, String> q) {
    final rawMonth = q['month']?.trim() ?? '';
    DateTime? month;
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(rawMonth);
    if (match != null) {
      final m = int.parse(match.group(2)!);
      if (m >= 1 && m <= 12) month = DateTime(int.parse(match.group(1)!), m);
    }
    return TravelSearch(
      destination: q['q']?.trim() ?? '',
      month: month,
      travellers: _int(q['travellers'], 2, min: 1),
    );
  }

  final String destination;

  /// The first of the month the buyer wants to travel in; null for any.
  final DateTime? month;
  final int travellers;

  /// `yyyy-MM`, the wire form of [month].
  String? get monthWire => month == null
      ? null
      : '${month!.year.toString().padLeft(4, '0')}-'
            '${month!.month.toString().padLeft(2, '0')}';

  Map<String, String> toQuery() => {
    if (destination.trim().isNotEmpty) 'q': destination.trim(),
    if (monthWire != null) 'month': monthWire!,
    'travellers': '$travellers',
  };

  TravelSearch copyWith({
    String? destination,
    DateTime? month,
    bool clearMonth = false,
    int? travellers,
  }) => TravelSearch(
    destination: destination ?? this.destination,
    month: clearMonth ? null : (month ?? this.month),
    travellers: travellers ?? this.travellers,
  );

  @override
  bool operator ==(Object other) =>
      other is TravelSearch &&
      other.destination == destination &&
      other.month == month &&
      other.travellers == travellers;

  @override
  int get hashCode => Object.hash(destination, month, travellers);
}

/// [StaySearch] wire date helper, shared with the datasource.
String searchWireDate(DateTime d) => _wire(d);

/// Today's date in Kathmandu (UTC+05:45, no daylight saving) — the calendar
/// every Services date is in, whatever the device's zone.
DateTime kathmanduDay(DateTime now) {
  final k = now.toUtc().add(const Duration(hours: 5, minutes: 45));
  return DateTime(k.year, k.month, k.day);
}
