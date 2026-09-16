/// How the point on a saved address was obtained. Mirrors the backend's
/// `LocationCapturedFrom` enum on `/v1/addresses`.
///
/// [sharedMapsLink] is **server-stamped** — the app never sends `4`; the
/// backend applies it when it resolves a pasted link into a point itself.
enum LocationSource {
  deviceGps(1),
  manualPin(2),
  geocodedFromAddress(3),
  sharedMapsLink(4);

  const LocationSource(this.wireValue);

  final int wireValue;

  static LocationSource? fromWire(int? value) {
    if (value == null) return null;
    for (final source in LocationSource.values) {
      if (source.wireValue == value) return source;
    }
    return null;
  }
}

/// A saved shipping address.
///
/// StyleMint does not ask customers to type a street, city, state or postal
/// code. A customer pins where they are (GPS or a dragged map pin) or pastes
/// a Maps link, and writes one free-text [locationNote] explaining how to
/// find the door. The postal fields below exist only to keep **legacy**
/// addresses — saved before the location flow shipped — listable, viewable
/// and editable; they are never collected and every one of them is nullable.
class ShippingAddress {
  const ShippingAddress({
    required this.id,
    required this.label,
    required this.receiverName,
    required this.receiverPhone,
    required this.country,
    this.locationNote = '',
    this.mapsLink,
    this.latitude,
    this.longitude,
    this.locationAccuracyMetres,
    this.locationCapturedFrom,
    this.addressLine1,
    this.landmark,
    this.city,
    this.state,
    this.zipCode,
    this.isDefault = false,
    this.rowVersion = '',
  });

  final String id;
  final String label;
  final String receiverName;
  final String receiverPhone;
  final String country;

  /// "How do we find it?" — required on every write, max 500 characters.
  final String locationNote;

  /// The customer's pasted Maps link, stored verbatim (max 2048 chars).
  final String? mapsLink;

  final double? latitude;
  final double? longitude;

  /// Horizontal accuracy of [latitude]/[longitude] in metres, when known.
  final double? locationAccuracyMetres;

  final LocationSource? locationCapturedFrom;

  // ── Legacy postal fields — read-only, never collected. ────────────────────
  final String? addressLine1;
  final String? landmark;
  final String? city;
  final String? state;
  final String? zipCode;

  final bool isDefault;
  final String rowVersion;

  /// True when a coordinate pair is present.
  bool get hasPoint => latitude != null && longitude != null;

  /// True when a Maps link is present.
  bool get hasMapsLink => (mapsLink ?? '').trim().isNotEmpty;

  /// The backend requires **a point or a link** on every write. When this is
  /// false a save will be rejected, so the UI blocks it up front.
  bool get hasLocation => hasPoint || hasMapsLink;

  /// A pre-location-flow address: no point, no link, only postal text.
  /// Editing one requires adding a location before it can be saved again.
  bool get isLegacy => !hasLocation;

  /// The legacy postal text as one line, with every null/blank part dropped —
  /// a null city must never render as an empty line or the word "null".
  /// Empty when the address has no legacy text at all.
  String get legacyPostalLine => [
    addressLine1,
    landmark,
    city,
    state,
    zipCode,
  ].map((p) => p?.trim() ?? '').where((p) => p.isNotEmpty).join(', ');

  /// `27.7172, 85.3240` — empty when there is no point.
  String get pointLabel => hasPoint
      ? '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}'
      : '';

  /// The one line to show wherever this address is summarised (list rows,
  /// checkout card, order detail). Prefers the customer's own words, falls
  /// back to legacy postal text, then to the raw point, and finally to a
  /// neutral phrase — it is never blank and never contains "null".
  String get summaryLine {
    final note = locationNote.trim();
    if (note.isNotEmpty) return note;
    final postal = legacyPostalLine;
    if (postal.isNotEmpty) return postal;
    if (hasPoint) return pointLabel;
    if (hasMapsLink) return mapsLink!.trim();
    return 'Location saved';
  }

  ShippingAddress copyWith({
    String? id,
    String? label,
    String? receiverName,
    String? receiverPhone,
    String? country,
    String? locationNote,
    String? mapsLink,
    double? latitude,
    double? longitude,
    double? locationAccuracyMetres,
    LocationSource? locationCapturedFrom,
    String? addressLine1,
    String? landmark,
    String? city,
    String? state,
    String? zipCode,
    bool? isDefault,
    String? rowVersion,
  }) {
    return ShippingAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      country: country ?? this.country,
      locationNote: locationNote ?? this.locationNote,
      mapsLink: mapsLink ?? this.mapsLink,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAccuracyMetres:
          locationAccuracyMetres ?? this.locationAccuracyMetres,
      locationCapturedFrom: locationCapturedFrom ?? this.locationCapturedFrom,
      addressLine1: addressLine1 ?? this.addressLine1,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      isDefault: isDefault ?? this.isDefault,
      rowVersion: rowVersion ?? this.rowVersion,
    );
  }
}

/// A point resolved from a pasted Maps link by
/// `POST /v1/addresses/resolve-link`.
class ResolvedMapsLink {
  const ResolvedMapsLink({
    required this.latitude,
    required this.longitude,
    required this.sourceUrl,
    this.redirectsFollowed = 0,
  });

  final double latitude;
  final double longitude;

  /// The URL the backend actually resolved (after following redirects).
  final String sourceUrl;
  final int redirectsFollowed;
}
