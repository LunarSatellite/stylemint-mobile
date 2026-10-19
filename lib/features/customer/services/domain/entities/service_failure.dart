/// Why a Services call (stays, travel, banks, bookings) failed.
///
/// Its own type, like the EMI feature's, because these screens need what the
/// shared `NetworkExceptions` drops: the `errorCode` of a 404 or a 409
/// (`booking.sold_out`, `quote.expired`, …) and the server's own sentence.
/// Each screen maps a failure to words with `serviceFailureMessage`.
enum ServiceFailureKind {
  /// No connection, or the request timed out before reaching the server.
  offline,

  /// 404 — the endpoint is not deployed yet, or the thing is not there.
  /// With no `errorCode` this reads as "Services are coming soon".
  notFound,

  /// 401/403 — the session has gone.
  auth,

  /// 409 — the room, seats or slot were taken, or a hold expired.
  conflict,

  /// Any other 4xx the server explained with an `errorCode`.
  rejected,

  /// 5xx — the server or the gateway in front of it is down.
  server,

  /// Anything else, including a payload this build could not read.
  unknown,
}

class ServiceFailure {
  const ServiceFailure(
    this.kind, {
    this.code,
    this.message,
    this.statusCode,
  });

  /// A rule the app checked itself before sending anything.
  const ServiceFailure.local(String this.code, {this.message})
    : kind = ServiceFailureKind.rejected,
      statusCode = null;

  final ServiceFailureKind kind;

  /// The RFC 7807 `errorCode`, e.g. `booking.sold_out`.
  final String? code;

  /// The server's own sentence (`detail`, else `title`), when it sent one.
  final String? message;
  final int? statusCode;

  bool get isNotFound => kind == ServiceFailureKind.notFound;

  /// A 404 without an `errorCode`: the route itself is missing, so the
  /// backend for Services is not deployed yet. A 404 with a code
  /// (`stay.not_found`) is a real "that thing is gone".
  bool get isComingSoon => isNotFound && (code == null || code!.isEmpty);

  @override
  String toString() => 'ServiceFailure($kind, $code, $statusCode)';
}

/// Carries a [ServiceFailure] out of a FutureProvider, which must throw to
/// report failure.
class ServiceLoadException implements Exception {
  const ServiceLoadException(this.failure);

  final ServiceFailure failure;

  @override
  String toString() => 'ServiceLoadException($failure)';
}

/// The [ServiceFailure] inside a provider error, else an unknown one.
ServiceFailure serviceFailureOf(Object error) => error is ServiceLoadException
    ? error.failure
    : error is ServiceFailure
    ? error
    : const ServiceFailure(ServiceFailureKind.unknown);
