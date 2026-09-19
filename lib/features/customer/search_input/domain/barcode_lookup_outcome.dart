import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/customer_search_result.dart';

/// What a scanned product barcode resolved to.
///
/// A scan that finds nothing is the most likely real outcome — the Mall does
/// not stock every GTIN on earth — so it is a first-class result here, not an
/// error path.
sealed class BarcodeLookupOutcome {
  const BarcodeLookupOutcome({required this.code});

  /// The normalised code that was looked up.
  final String code;
}

/// Exactly one product answered to the code: go straight to it.
class BarcodeMatched extends BarcodeLookupOutcome {
  const BarcodeMatched({
    required super.code,
    required this.productId,
    required this.productName,
  });

  final String productId;
  final String productName;
}

/// More than one product answered. A barcode identifies one item, so several
/// hits means the catalogue search fell back to fuzzy text matching and we
/// must not claim a match — the buyer picks from the results instead.
class BarcodeAmbiguous extends BarcodeLookupOutcome {
  const BarcodeAmbiguous({required super.code, required this.results});

  final CustomerSearchResults results;
}

/// Nothing in the catalogue carries this code.
class BarcodeUnmatched extends BarcodeLookupOutcome {
  const BarcodeUnmatched({required super.code});
}

/// The lookup itself could not run (offline, server error).
class BarcodeLookupFailed extends BarcodeLookupOutcome {
  const BarcodeLookupFailed({required super.code, this.detail});

  final String? detail;
}

/// Strips the noise a scanner adds and rejects values that cannot be a
/// product code. Returns null when the value is not worth a round-trip.
String? normalizeBarcode(String raw) {
  final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), '');
  if (trimmed.length < 6 || trimmed.length > 48) return null;
  // Product symbologies (EAN/UPC/ITF) are numeric; Code 128/39 carry
  // alphanumerics and a few separators. Anything else is a QR payload or a
  // URL, which the StyleMint QR scanner owns, not this one.
  if (!RegExp(r'^[A-Za-z0-9\-_.]+$').hasMatch(trimmed)) return null;
  return trimmed;
}
