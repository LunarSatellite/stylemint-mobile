/// Why an EMI, KYC or vendor-terms call failed.
///
/// A dedicated type rather than the shared `NetworkExceptions` because these
/// screens need two things that one drops: the `errorCode` of a 404
/// (`emi_quote.not_available` is a 404 with a code), and the `missing` list
/// that `kyc.documents_missing` carries. Each screen maps a failure to its own
/// sentence — see `emi_messages.dart`, `kyc_messages.dart` and
/// `vendor_emi_messages.dart`.
enum EmiFailureKind {
  /// No connection, or the request timed out before reaching the server.
  offline,

  /// 404 — the endpoint is not deployed yet, or the thing is not there.
  /// EMI screens hide themselves on this.
  notFound,

  /// 401/403 — the session has gone.
  auth,

  /// A 4xx the server explained with an `errorCode`.
  rejected,

  /// 413 — a photo was too large for the server or the gateway.
  tooLarge,

  /// 5xx — the server or the gateway in front of it is down.
  server,

  /// Anything else, including a payload this build could not read.
  unknown,
}

class EmiFailure {
  const EmiFailure(
    this.kind, {
    this.code,
    this.message,
    this.missing = const <String>[],
    this.statusCode,
  });

  /// A rule the app checked itself before sending anything, carrying the same
  /// code the server would have answered with.
  const EmiFailure.local(String this.code, {this.missing = const <String>[]})
    : kind = EmiFailureKind.rejected,
      message = null,
      statusCode = null;

  final EmiFailureKind kind;

  /// The RFC 7807 `errorCode`, e.g. `kyc.underage`.
  final String? code;

  /// The server's own sentence (`detail`, else `title`), when it sent one.
  final String? message;

  /// `kyc.documents_missing` only: the kinds still to upload, as wire names.
  final List<String> missing;
  final int? statusCode;

  bool get isNotFound => kind == EmiFailureKind.notFound;

  @override
  String toString() => 'EmiFailure($kind, $code, $statusCode)';
}
