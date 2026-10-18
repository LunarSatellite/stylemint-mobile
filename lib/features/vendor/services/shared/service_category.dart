import 'package:stylemint_mobile_frontend/core/network/json_read.dart';

/// What kind of business a vendor is (service-banks contract v1, §1).
///
/// A vendor is either a product seller ([none], everyone who existed before
/// service vendors) or a service vendor: a hotel, a travel agency or a bank.
/// The category is chosen on the vendor application and copied to the vendor
/// profile on approval; it is read-only afterwards.
enum ServiceCategory {
  none(0, 'Products'),
  hotel(1, 'Hotel'),
  travelAgency(2, 'Travel agency'),
  bank(3, 'Bank');

  const ServiceCategory(this.wire, this.label);

  final int wire;
  final String label;

  bool get isService => this != none;

  /// Hotels and travel agencies take bookings; banks take enquiries.
  bool get takesBookings => this == hotel || this == travelAgency;

  /// Numeric on the wire; a name is accepted too. Anything unknown reads as
  /// a product seller, so a vendor never loses the screens they had.
  static ServiceCategory fromWire(Object? raw) {
    final value = normalizeWireEnum(raw);
    for (final c in values) {
      if (value == c.wire) return c;
      if (value is String && value == c.name.toLowerCase()) return c;
    }
    return none;
  }
}
