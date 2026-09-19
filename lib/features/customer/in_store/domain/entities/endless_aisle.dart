import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Whether this platform can say anything about stock held at a physical
/// location.
///
/// It cannot. The backend's `PickupStockAvailability` has exactly one member
/// (`Unknown`) so that no code path can quietly turn the absence of a
/// measurement into "0 left" or "in stock here", and this mirror keeps that
/// property: neither member may ever be drawn as a quantity.
enum PickupStockAvailability {
  /// The backend said `Unknown` — the only value it can send today.
  unknown,

  /// The wire carried something this build has no name for. Treated exactly
  /// like [unknown]: an unreadable answer is still not an answer.
  unrecognised,
}

/// How much weight a reader should give a location's recorded details.
///
/// Derived by the backend from `lastConfirmedUtc` alone — an edit is not a
/// confirmation.
enum LocationConfirmationState {
  /// Nobody has ever confirmed this record.
  neverConfirmed,

  /// Confirmed inside the backend's freshness window.
  confirmed,

  /// Confirmed once, longer ago than that window.
  stale,

  /// A state this build has no name for.
  unrecognised,
}

/// One collection point the seller has recorded, exactly as the backend can
/// honestly describe it.
///
/// There is no stock field and there is not going to be one:
/// [stockAvailability] is a constant, and [stockAvailabilityNote] is the
/// backend's own sentence explaining why.
class PickupLocation {
  const PickupLocation({
    required this.locationId,
    required this.name,
    required this.addressLine,
    required this.city,
    required this.confirmationState,
    required this.confirmationNote,
    required this.stockAvailability,
    required this.stockAvailabilityNote,
    this.latitude,
    this.longitude,
    this.openingHours,
    this.lastConfirmedUtc,
  });

  final String locationId;
  final String name;
  final String addressLine;
  final String city;
  final double? latitude;
  final double? longitude;

  /// Free text, exactly as the seller typed it. Null when none was given —
  /// and null is drawn as nothing, never as "open 24/7".
  final String? openingHours;

  /// When a human last confirmed this record. Null means never, not
  /// "confirmed at creation".
  final DateTime? lastConfirmedUtc;

  final LocationConfirmationState confirmationState;

  /// The backend's confirmation verdict as a sentence, so a stale record
  /// reads stale.
  final String confirmationNote;

  final PickupStockAvailability stockAvailability;

  /// The backend's own words for why [stockAvailability] says nothing.
  final String stockAvailabilityNote;

  /// `Bagbazar, Kathmandu` — the parts that are present, in order. Never a
  /// stand-in for a part that is missing.
  String get addressSummary => <String>[
    addressLine.trim(),
    city.trim(),
  ].where((part) => part.isNotEmpty).join(', ');
}

/// What a shopper standing in front of a scanned code can do next: order the
/// item wherever they are, and see the seller's recorded collection points.
///
/// The two things it deliberately never says are "this shop has one" and
/// "this shop has none". Stock in this platform is one pool per item, not one
/// per place, so both would be invented.
class EndlessAisle {
  const EndlessAisle({
    required this.code,
    required this.kind,
    required this.vendorAccountId,
    required this.canOrderFromAnywhere,
    required this.reachNote,
    required this.inStoreAvailability,
    required this.inStoreAvailabilityNote,
    required this.pickupOffered,
    required this.pickupNote,
    required this.pickupLocations,
    this.productId,
    this.productName,
    this.productImageUrl,
    this.productPrice,
    this.scannedAtLocationId,
    this.scannedAtLocationName,
    this.vendorDisplayName,
  });

  final String code;
  final CodeKind kind;

  /// The scanned product, when the code is a product tag; null for a store
  /// code.
  final String? productId;
  final String? productName;
  final String? productImageUrl;

  /// Null unless the backend sent both an amount and a currency. A price
  /// nobody quoted stays absent rather than becoming zero.
  final Money? productPrice;

  final String? scannedAtLocationId;
  final String? scannedAtLocationName;

  final String vendorAccountId;
  final String? vendorDisplayName;

  /// True when the shopper can buy this without it being in front of them —
  /// the endless aisle proper. It reflects that the item is listed and
  /// orderable, never that any particular place holds one.
  final bool canOrderFromAnywhere;

  /// The backend's sentence for [canOrderFromAnywhere].
  final String reachNote;

  /// Always [PickupStockAvailability.unknown] today.
  final PickupStockAvailability inStoreAvailability;

  /// The backend's sentence for why [inStoreAvailability] says nothing.
  final String inStoreAvailabilityNote;

  /// Whether this seller has opted into collection at all. Not a claim about
  /// any item.
  final bool pickupOffered;

  /// The backend's sentence for [pickupOffered] and the number of recorded
  /// locations.
  final String pickupNote;

  /// The seller's own recorded locations; empty when they have recorded none
  /// or have not opted into collection.
  final List<PickupLocation> pickupLocations;

  /// True when this platform holds nothing it could show a shopper here —
  /// no reach claim, no pickup note, no locations. The section draws nothing
  /// at all rather than an empty shell.
  bool get isEmpty =>
      reachNote.isEmpty && pickupNote.isEmpty && pickupLocations.isEmpty;
}
