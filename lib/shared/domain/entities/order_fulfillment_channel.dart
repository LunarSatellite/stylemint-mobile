/// How a sub-order reaches the buyer. Mirrors the backend
/// `OrderFulfillmentChannel`, which travels as a **string** on the wire
/// (`"Delivery"` / `"StorePickup"`) because the enum carries a
/// `JsonStringEnumConverter`.
///
/// This is not a label on an otherwise identical order. A collection
/// sub-order never ships, so the courier vocabulary — shipped, in transit,
/// out for delivery — describes nothing that happened to it. Every screen
/// that reads this enum reads it to decide what it is allowed to *say*.
library;

enum OrderFulfillmentChannel {
  /// A courier carries the parcel to the buyer's address. The default, and
  /// what every order placed before the channel existed actually was.
  delivery,

  /// The buyer collects at one of the seller's recorded counters.
  storePickup;

  /// Tolerant of the string form, the persisted int (1/2), and of case and
  /// separator style, so a future serializer change cannot silently flip
  /// every order onto the wrong path.
  ///
  /// An unrecognised value reads as [delivery]. That is the conservative
  /// answer in both directions: the counter handover is refused rather than
  /// offered on an order nobody confirmed is a collection, and no screen
  /// starts calling a delivery a collection on a typo.
  static OrderFulfillmentChannel fromWire(Object? raw) {
    if (raw is num) return raw.toInt() == 2 ? storePickup : delivery;
    if (raw is! String) return delivery;
    final normalised = raw.trim().toLowerCase().replaceAll(
      RegExp(r'[_\s-]'),
      '',
    );
    return normalised == 'storepickup' || normalised == 'pickup'
        ? storePickup
        : delivery;
  }

  bool get isCollection => this == storePickup;
}
