/// Why a try-on call failed.
///
/// Its own type rather than the shared `NetworkExceptions` because the try-on
/// screens must tell two 403s apart — `field: tryOnAccess` (no premium access:
/// open the paywall) and `field: tryOnDisabled` (the service is switched off:
/// hide the feature) — and the shared mapper folds every 403 into `auth`.
enum TryOnFailureKind {
  offline,

  /// 401 — the session has gone.
  auth,

  /// 403 `tryOnAccess` — signed in, but no trial/subscription/grant.
  noAccess,

  /// 403 `tryOnDisabled` — the admin switched the service off.
  disabled,

  /// 404 — no try-on image / no size chart / no measurements yet.
  notFound,

  /// 409 — e.g. the free trial was already used.
  conflict,

  /// Any other 4xx the server explained with an `errorCode`.
  rejected,

  /// 5xx.
  server,

  unknown,
}

class TryOnFailure {
  const TryOnFailure(
    this.kind, {
    this.code,
    this.field,
    this.message,
    this.statusCode,
  });

  final TryOnFailureKind kind;

  /// RFC 7807 `errorCode`, e.g. `validation.invalid_format`.
  final String? code;

  /// RFC 7807 top-level `field`, e.g. `file` or `tryOnAccess`.
  final String? field;

  /// The server's own sentence (`detail`, else `title`).
  final String? message;
  final int? statusCode;

  bool get isNotFound => kind == TryOnFailureKind.notFound;
  bool get isNoAccess => kind == TryOnFailureKind.noAccess;
  bool get isDisabled => kind == TryOnFailureKind.disabled;

  /// A sentence for a snackbar or an inline error.
  String get displayMessage => switch (kind) {
    TryOnFailureKind.offline => 'No internet connection. Check it and retry.',
    TryOnFailureKind.auth => 'Please sign in again to continue.',
    TryOnFailureKind.noAccess =>
      'Virtual try-on is a premium feature. Start a trial or pick a plan.',
    TryOnFailureKind.disabled => 'Virtual try-on is not available right now.',
    TryOnFailureKind.notFound => message ?? 'Not available for this product.',
    TryOnFailureKind.conflict =>
      message ??
          (code == 'state.conflict'
              ? 'You have already used your free trial.'
              : 'That changed in the meantime. Please refresh.'),
    TryOnFailureKind.rejected => message ?? 'That was not accepted ($code).',
    TryOnFailureKind.server =>
      'StyleMint is temporarily unavailable. Please try again in a moment.',
    TryOnFailureKind.unknown => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'TryOnFailure($kind, $code, $field, $statusCode)';
}
