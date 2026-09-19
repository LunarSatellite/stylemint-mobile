/// Lifecycle of a per-unit marker — backend `UnitMarkerStatus`, serialised by
/// name.
///
/// There is deliberately no `bound` value. Whether a marker identifies a sold
/// physical item is a fact about the bindings table, not a flag on the tag,
/// and the app must not invent one.
enum UnitMarkerStatus {
  active('Active', 'Active'),
  revoked('Revoked', 'Revoked'),

  /// A status from a newer server. Never treated as [active]: an unknown
  /// value quietly reading as "this tag is good" is the one failure mode that
  /// could endorse a counterfeit.
  unrecognised('', 'Status not recognised');

  const UnitMarkerStatus(this.wire, this.label);

  final String wire;

  /// Plain wording for a screen. Never a raw enum name.
  final String label;

  static UnitMarkerStatus fromJson(Object? raw) {
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

/// A marker as its own seller sees it afterwards — backend `UnitMarkerVm`.
///
/// It never carries the secret. There is no field for one on the wire and
/// none here, so there is nothing for a list screen to leak.
class UnitMarker {
  const UnitMarker({
    required this.id,
    required this.reference,
    required this.productId,
    required this.productVariantId,
    required this.status,
    required this.provisionedAt,
    this.revokedAt,
  });

  final String id;

  /// `UMxxxxxxxxxx` — the non-secret handle a seller quotes.
  final String reference;
  final String productId;
  final String productVariantId;
  final UnitMarkerStatus status;
  final DateTime? provisionedAt;

  /// Null means the marker was never revoked. It is never a placeholder date.
  final DateTime? revokedAt;
}

/// A freshly minted marker, **including its cleartext secret**.
///
/// This is the only type in the app that ever holds one. The platform stored
/// nothing but a SHA-256 digest, so the value in [secret] exists in exactly
/// two places: the tag the seller is about to print, and this object. When
/// this object is dropped the value is gone for good — there is no endpoint
/// that can return it again.
///
/// Rules that hold wherever this type travels:
/// * it lives in notifier state only, for as long as one reveal screen is on
///   screen;
/// * it is never written to secure storage, shared preferences, a database,
///   a log line, an analytics event or a crash report;
/// * it is never placed in a route, a query string or a deep link;
/// * it is never rendered outside the one-time reveal.
class ProvisionedUnitMarker {
  const ProvisionedUnitMarker({
    required this.id,
    required this.reference,
    required this.secret,
    required this.productId,
    required this.productVariantId,
    required this.provisionedAt,
  });

  final String id;
  final String reference;

  /// 26 Crockford characters. Unrecoverable once lost.
  final String secret;

  final String productId;
  final String productVariantId;
  final DateTime? provisionedAt;

  /// The same row with the secret gone. Used the moment the seller confirms
  /// they have the tags out of the app, so the value stops existing in memory
  /// while the screen is still up.
  UnitMarker get withoutSecret => UnitMarker(
    id: id,
    reference: reference,
    productId: productId,
    productVariantId: productVariantId,
    status: UnitMarkerStatus.active,
    provisionedAt: provisionedAt,
  );

  /// Deliberately does not include [secret].
  ///
  /// `toString` is what a logger, a crash reporter and a debug `print` all
  /// reach for. The default implementation of a Dart class does not print
  /// fields, but this override makes the guarantee explicit rather than
  /// incidental, so adding `@override String toString()` later cannot quietly
  /// start logging the credential.
  @override
  String toString() => 'ProvisionedUnitMarker($reference)';
}
