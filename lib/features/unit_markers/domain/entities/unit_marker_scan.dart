import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';

/// Where a unit marker was read — backend `UnitScanPlaceKind`.
///
/// Two values, because the platform can only honestly tell two places apart:
/// one the scanner proved by presenting a registered store's own StyleMint
/// code alongside the item, and "not stated". There is no GPS, no IP-derived
/// city and no inferred location anywhere in this flow.
enum UnitScanPlaceKind {
  vendorStore('VendorStore'),

  /// No place was established. Renders as **absent** — never as "unknown
  /// location" and never as a blank row with a label in front of it.
  notStated('NotStated'),

  unrecognised('');

  const UnitScanPlaceKind(this.wire);

  final String wire;

  static UnitScanPlaceKind fromJson(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      final needle = raw.toLowerCase();
      for (final value in values) {
        if (value != unrecognised && value.wire.toLowerCase() == needle) {
          return value;
        }
      }
    }
    return unrecognised;
  }
}

/// What a stranger holding the item is told — backend
/// `UnitMarkerScanResultVm`.
///
/// **This is the whole public surface, and the list is the point.** A scanner
/// learns: whether the tag is one the platform issued, whether it is still
/// active, which listing it belongs to, whether it is bound to a completed
/// sale, and the date that binding happened. Optionally the registered store
/// where the scan took place, and only because the scanner presented that
/// store's own code.
///
/// They learn **no** order id, sub-order id, order line, buyer account, buyer
/// name, address, price or tracking number. None of those fields exist on
/// this type, none exist on the wire shape it maps, and the ports behind the
/// endpoint cannot fetch them. Reaching for a second endpoint to fill that
/// gap would undo the whole design — so there is nothing here to reach with.
class UnitMarkerScanResult {
  const UnitMarkerScanResult({
    required this.unitMarkerId,
    required this.reference,
    required this.status,
    required this.productId,
    required this.isBoundToSale,
    required this.scannedAt,
    required this.placeKind,
    this.productName,
    this.inServiceSince,
    this.vendorStoreId,
    this.vendorStoreName,
    this.vendorStoreCity,
  });

  /// The opaque id the unit passport is fetched with. Safe in a URL: it is
  /// not a credential, and a guessed one is simply unbound.
  final String unitMarkerId;

  /// `UMxxxxxxxxxx`. Non-secret, and what support asks for.
  final String reference;

  final UnitMarkerStatus status;
  final String productId;

  /// Null means the listing has no name recorded, which renders as nothing at
  /// all rather than as an empty label.
  final String? productName;

  /// True only when a live binding exists. When false the tag is genuine but
  /// has not been attached to a sale — which is a fact about the tag, not an
  /// error and not a missing passport.
  final bool isBoundToSale;

  /// When the tag was bound to the item that was sold — the start of any
  /// warranty clock. Null means *not bound*, never a placeholder date.
  final DateTime? inServiceSince;

  final DateTime? scannedAt;

  final UnitScanPlaceKind placeKind;
  final String? vendorStoreId;
  final String? vendorStoreName;
  final String? vendorStoreCity;

  /// True only when the scanner proved a place by presenting that store's own
  /// code and the store actually came back named.
  bool get hasProvenPlace =>
      placeKind == UnitScanPlaceKind.vendorStore &&
      (vendorStoreName?.isNotEmpty ?? false);

  /// Genuine means "the platform issued this tag and has not retired it".
  /// It says nothing about the goods themselves and the UI must not imply it
  /// does.
  bool get isActiveTag => status == UnitMarkerStatus.active;
}

/// One recorded reading, as the marker's own seller sees it — backend
/// `UnitMarkerScanVm`.
class UnitMarkerScan {
  const UnitMarkerScan({
    required this.id,
    required this.scannedAt,
    required this.via,
    required this.placeKind,
    this.vendorStoreId,
    this.vendorStoreName,
  });

  final String id;
  final DateTime? scannedAt;

  /// Reuses the Codes module's `ScanVia` wire names (`Qr`, `Nfc`, `Link`).
  final String via;
  final UnitScanPlaceKind placeKind;
  final String? vendorStoreId;
  final String? vendorStoreName;
}
