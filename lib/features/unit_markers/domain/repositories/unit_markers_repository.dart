import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

/// What a unit-passport scan ended in.
///
/// [UnitPassportUnbound] is a first-class answer, not a failure. The passport
/// endpoint 404s for a marker with no live binding, and for a shopper that
/// means one specific, sayable thing — *this tag is not bound to a sale* —
/// which is neither an error nor an empty passport.
sealed class UnitPassportResult {
  const UnitPassportResult();
}

final class UnitPassportFound extends UnitPassportResult {
  const UnitPassportFound(this.passport);

  final ProductPassport passport;
}

final class UnitPassportUnbound extends UnitPassportResult {
  const UnitPassportUnbound();
}

/// The nine per-unit routes, as the app sees them.
///
/// Three of them are the seller's (provision, list, revoke), three are the
/// packer's (bind, correct, binding history), one is the seller's scan
/// history, and two are public (scan, unit passport).
abstract interface class UnitMarkersRepository {
  // ── Seller: provisioning ────────────────────────────────────────────────

  /// `POST v1/vendor/unit-markers` — mints [quantity] tags for one variant.
  ///
  /// The returned secrets are **the only copy that will ever exist**. The
  /// caller must show them once and then drop them; there is no route that
  /// can return them again.
  ///
  /// §5.9: this prices nothing, reserves nothing and moves no money.
  /// `quantity` is a print run, not a stock figure.
  Future<Either<NetworkExceptions, List<ProvisionedUnitMarker>>> provision({
    required String productVariantId,
    required int quantity,
  });

  /// `GET v1/vendor/unit-markers` — the caller's own markers. Never carries a
  /// secret.
  Future<Either<NetworkExceptions, PagedResult<UnitMarker>>> listMarkers({
    String? productId,
    String? productVariantId,
    String? cursor,
    int pageSize,
  });

  /// `POST v1/vendor/unit-markers/{reference}/revoke` — retires a lost or
  /// misprinted tag by its non-secret reference. Idempotent; never reversed.
  Future<Either<NetworkExceptions, UnitMarker>> revoke(String reference);

  // ── Packer: binding ────────────────────────────────────────────────────

  /// `POST v1/vendor/unit-markers/bind` — attaches the tag in the packer's
  /// hand to an order line.
  ///
  /// Returns a [UnitMarkerBindRefused] rather than a failure for the outcomes
  /// a packer has to act on: already bound (409), a rule that will not allow
  /// it (400), not found, not theirs. Transport problems still come back as a
  /// [NetworkExceptions] on the left.
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> bind({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
  });

  /// `POST v1/vendor/unit-markers/bindings/correct` — records that a binding
  /// was wrong and what it should have been.
  ///
  /// [reason] is required by the backend and is the seller's own words. The
  /// superseded row is kept with that reason attached and the new row points
  /// back at it.
  Future<Either<NetworkExceptions, UnitMarkerBindOutcome>> correct({
    required String marker,
    required String subOrderLineId,
    required UnitBindingStage stage,
    required String reason,
  });

  /// `GET v1/vendor/unit-markers/{reference}/bindings` — every binding this
  /// marker has ever had, corrections included, newest first.
  Future<Either<NetworkExceptions, List<UnitMarkerBinding>>> bindingHistory(
    String reference,
  );

  /// `GET v1/vendor/unit-markers/{reference}/scans` — where this item has
  /// been and when. The place is a store the scanner proved, or absent.
  Future<Either<NetworkExceptions, List<UnitMarkerScan>>> scanHistory(
    String reference, {
    int limit,
  });

  // ── Public: scan and passport ──────────────────────────────────────────

  /// `POST v1/public/unit-markers/scan` — reads a tag and records one scan.
  ///
  /// The marker travels in the **body**. It is never a path segment and never
  /// a query parameter: a credential in a URL lands in every access log
  /// between the phone and the database.
  ///
  /// A marker the platform never issued is `NetworkExceptions.notFound()`.
  /// A marker it issued but nobody bound comes back **successfully**, with
  /// `isBoundToSale` false.
  Future<Either<NetworkExceptions, UnitMarkerScanResult>> scan({
    required String marker,
    required CodeScanVia via,
    String? atStoreCode,
  });

  /// `GET v1/public/unit-passports/{unitMarkerId}` — the passport for one
  /// physical item.
  ///
  /// The opaque id is safe in the URL. The endpoint re-checks the binding, so
  /// a marker with none 404s — mapped here to [UnitPassportUnbound] rather
  /// than to a failure, because "not bound to a sale" is a fact worth saying
  /// and an error message is not.
  Future<Either<NetworkExceptions, UnitPassportResult>> unitPassport(
    String unitMarkerId,
  );
}
