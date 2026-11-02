/// Why a bundle call failed (shop bundles contract §B5–B9).
///
/// Its own type because the bundle screens need what the shared
/// `NetworkExceptions` drops: the `errorCode` of a 404 or 409
/// (`bundle_terms_changed`, `bundle_not_purchasable`, …), and whether a 404
/// is a bare one — the route is not deployed yet, so bundle UI hides — or a
/// bundle that is gone.
enum BundleFailureKind { offline, notFound, auth, conflict, rejected, server, unknown }

class BundleFailure {
  const BundleFailure(
    this.kind, {
    this.code,
    this.message,
    this.statusCode,
    this.body = const <String, dynamic>{},
  });

  final BundleFailureKind kind;

  /// The RFC 7807 `errorCode`, e.g. `bundle_terms_changed`.
  final String? code;

  /// The server's own sentence (`detail`, else `title`).
  final String? message;
  final int? statusCode;

  /// The whole error body, for the extras some codes carry (`groupId` on
  /// `bundle_unavailable`).
  final Map<String, dynamic> body;

  bool get isNotFound => kind == BundleFailureKind.notFound;

  /// A 404 without an `errorCode`: the bundle routes are not deployed yet.
  /// Every bundle surface hides itself for this.
  bool get isNotDeployed => isNotFound && (code == null || code!.isEmpty);

  bool get isTermsChanged => code == 'bundle_terms_changed';

  @override
  String toString() => 'BundleFailure($kind, $code, $statusCode)';
}

/// Carries a [BundleFailure] out of a FutureProvider.
class BundleLoadException implements Exception {
  const BundleLoadException(this.failure);

  final BundleFailure failure;

  @override
  String toString() => 'BundleLoadException($failure)';
}

/// The failure behind a provider error, when it is one of ours.
BundleFailure? bundleFailureOf(Object? error) => switch (error) {
  BundleLoadException(:final failure) => failure,
  BundleFailure() => error,
  _ => null,
};

/// True when [error] means the bundle routes are not deployed (bare 404).
bool bundlesNotDeployed(Object? error) =>
    bundleFailureOf(error)?.isNotDeployed ?? false;

/// A sentence for a bundle error code, or null for codes this build does
/// not know.
String? bundleErrorMessage(String code) => switch (code) {
  'bundle_terms_changed' =>
    'This bundle just changed. Check the new prices and try again.',
  'bundle_not_purchasable' =>
    'This bundle cannot be bought right now.',
  'bundle_unavailable' =>
    'A bundle in your cart is not available any more.',
  'bundle_line_quantity_locked' =>
    'Change the number of bundles on the bundle card, not on one item.',
  'bundle_not_editable' => 'This bundle cannot be changed any more.',
  'bundle_limits' => 'That goes over the bundle limits.',
  'bundle_item_not_partner' =>
    'You need an active partnership with every shop in this bundle.',
  'bundle_item_not_own' => 'You can only add your own products.',
  'bundle.not_found' || 'bundle_not_found' =>
    'This bundle is not available any more.',
  'tagged_bundle_limit' || 'reel.tagged_bundle_limit' =>
    'A reel can show up to 3 bundles.',
  _ => null,
};

/// A plain sentence for [failure].
String bundleFailureMessage(
  BundleFailure failure, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final code = failure.code;
  if (code != null) {
    final mapped = bundleErrorMessage(code);
    if (mapped != null) return mapped;
  }
  return switch (failure.kind) {
    BundleFailureKind.offline =>
      'You appear to be offline. Check your connection and try again.',
    BundleFailureKind.auth => 'Please sign in again to continue.',
    BundleFailureKind.server =>
      'StyleMint is having trouble right now. Try again in a moment.',
    BundleFailureKind.notFound when failure.isNotDeployed =>
      'Bundles are being set up. Check back shortly.',
    BundleFailureKind.notFound => 'This bundle is not available any more.',
    BundleFailureKind.rejected ||
    BundleFailureKind.conflict => failure.message ?? fallback,
    BundleFailureKind.unknown => fallback,
  };
}
