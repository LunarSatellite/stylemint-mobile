import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_exceptions.freezed.dart';

/// One per-field error from the backend's RFC 7807 `errors[]` array.
/// Mirrors `StyleMint.Shared.Infrastructure.Core.Http.FieldError`.
@immutable
class FieldErrorVm {
  const FieldErrorVm({
    required this.field,
    required this.code,
    required this.message,
  });

  final String field;
  final String code;
  final String message;

  factory FieldErrorVm.fromJson(Map<String, dynamic> json) => FieldErrorVm(
        field: (json['field'] ?? '') as String,
        code: (json['code'] ?? '') as String,
        message: (json['message'] ?? '') as String,
      );

  /// Pretty "field: message" line. Falls back to code/field if message is empty.
  String toDisplayLine() {
    final msg = message.isNotEmpty ? message : code;
    if (field.isEmpty) return msg;
    return '$field: $msg';
  }

  @override
  bool operator ==(Object other) =>
      other is FieldErrorVm &&
      other.field == field &&
      other.code == code &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, code, message);
}

@freezed
abstract class NetworkExceptions with _$NetworkExceptions {
  const NetworkExceptions._();

  const factory NetworkExceptions.server(String message) = _Server;

  /// The backend (or a gateway in front of it) is unreachable / returned 5xx —
  /// e.g. nginx `502 Bad Gateway`, `503 Service Unavailable`, `504 Gateway
  /// Timeout`. Distinct from [server] so the UI can say "try again in a moment"
  /// instead of surfacing a raw error page body.
  const factory NetworkExceptions.serverUnavailable() = _ServerUnavailable;
  const factory NetworkExceptions.noInternetConnection() = _NoInternet;
  const factory NetworkExceptions.unexpectedError() = _Unexpected;
  const factory NetworkExceptions.formatException() = _Format;
  const factory NetworkExceptions.emptyData() = _EmptyData;

  /// 4xx with an RFC 7807 body. `code` is the machine errorCode
  /// (e.g. `validation.out_of_range`). `message` is the backend's `title`
  /// (human sentence). `field` is the top-level `field` from the body (the
  /// single offending field for single-field errors). `errors` is the full
  /// `errors[]` array for multi-field validation responses; when present it
  /// always wins over the top-level `message`/`field` for display purposes.
  const factory NetworkExceptions.validation({
    required String code,
    String? message,
    String? field,
    @Default(<FieldErrorVm>[]) List<FieldErrorVm> errors,
  }) = _Validation;

  const factory NetworkExceptions.auth() = _Auth;
  const factory NetworkExceptions.notFound() = _NotFound;
  const factory NetworkExceptions.conflict() = _Conflict;

  /// The error code when this is a `.validation(code:)`, else null.
  String? get validationCode => when(
        server: (_) => null,
        serverUnavailable: () => null,
        noInternetConnection: () => null,
        unexpectedError: () => null,
        formatException: () => null,
        emptyData: () => null,
        validation: (code, _, __, ___) => code,
        auth: () => null,
        notFound: () => null,
        conflict: () => null,
      );

  /// True for `.auth()` — used to treat a user-cancelled passkey ceremony as a
  /// no-op rather than an error.
  bool get isAuth => when(
        server: (_) => false,
        serverUnavailable: () => false,
        noInternetConnection: () => false,
        unexpectedError: () => false,
        formatException: () => false,
        emptyData: () => false,
        validation: (_, __, ___, ____) => false,
        auth: () => true,
        notFound: () => false,
        conflict: () => false,
      );

  /// True for `.noInternetConnection()`.
  bool get isNoInternet => when(
        server: (_) => false,
        serverUnavailable: () => false,
        noInternetConnection: () => true,
        unexpectedError: () => false,
        formatException: () => false,
        emptyData: () => false,
        validation: (_, __, ___, ____) => false,
        auth: () => false,
        notFound: () => false,
        conflict: () => false,
      );

  /// True for `.notFound()` — e.g. no application/role record exists yet, which
  /// callers treat as "show the empty/apply form" rather than an error.
  bool get isNotFound => when(
        server: (_) => false,
        serverUnavailable: () => false,
        noInternetConnection: () => false,
        unexpectedError: () => false,
        formatException: () => false,
        emptyData: () => false,
        validation: (_, __, ___, ____) => false,
        auth: () => false,
        notFound: () => true,
        conflict: () => false,
      );

  /// True for `.conflict()` — e.g. a duplicate-account (409) on registration.
  bool get isConflict => when(
        server: (_) => false,
        serverUnavailable: () => false,
        noInternetConnection: () => false,
        unexpectedError: () => false,
        formatException: () => false,
        emptyData: () => false,
        validation: (_, __, ___, ____) => false,
        auth: () => false,
        notFound: () => false,
        conflict: () => true,
      );

  /// True for `.serverUnavailable()` — backend/gateway is down or returned 5xx.
  /// Callers use this to show a "temporarily unavailable, try again" message.
  bool get isServerUnavailable => when(
        server: (_) => false,
        serverUnavailable: () => true,
        noInternetConnection: () => false,
        unexpectedError: () => false,
        formatException: () => false,
        emptyData: () => false,
        validation: (_, __, ___, ____) => false,
        auth: () => false,
        notFound: () => false,
        conflict: () => false,
      );

  /// Human-friendly message describing exactly which field is wrong and why.
  /// Used by snackbars/dialogs so vendors see "images: Images must be between
  /// 5 and 10." instead of a generic "Validation error: code".
  static String getMessage(NetworkExceptions exception) {
    return exception.when(
      server: (msg) => msg,
      serverUnavailable: () =>
          'StyleMint is temporarily unavailable. Please try again in a moment.',
      noInternetConnection: () => 'No internet connection.',
      unexpectedError: () => 'An unexpected error occurred.',
      formatException: () => 'Invalid response format.',
      emptyData: () => 'No data available.',
      validation: (code, message, field, errors) =>
          _formatValidation(code, message, field, errors),
      auth: () => 'Authentication required.',
      notFound: () => 'Resource not found.',
      conflict: () => 'Conflict detected.',
    );
  }

  static String _formatValidation(
    String code,
    String? message,
    String? field,
    List<FieldErrorVm> errors,
  ) {
    // Multi-field response (RFC 7807 `errors[]` populated). Render each as
    // "field: message" on its own line so the vendor can fix every problem
    // in one pass.
    if (errors.isNotEmpty) {
      return errors.map((e) => e.toDisplayLine()).join('\n');
    }
    // Single-field response: prefer the backend's `title` (the most readable
    // sentence) and prefix the field name when present so the vendor knows
    // exactly which input to fix.
    final human = (message ?? '').trim();
    final fieldName = (field ?? '').trim();
    if (human.isNotEmpty && fieldName.isNotEmpty) {
      return '$fieldName: $human';
    }
    if (human.isNotEmpty) return human;
    if (fieldName.isNotEmpty) {
      return 'Field "$fieldName" is invalid (${_humanizeCode(code)}).';
    }
    return 'Validation error: ${_humanizeCode(code)}';
  }

  /// Turn `validation.out_of_range` / `validation.required` / `system.rate_limited`
  /// into something a non-engineer can read.
  static String _humanizeCode(String code) {
    if (code.isEmpty) return 'invalid request';
    final parts = code.split('.');
    final tail = parts.length > 1 ? parts.last : code;
    switch (tail) {
      case 'required':
        return 'this field is required';
      case 'invalid_format':
      case 'invalidformat':
        return 'this field has an invalid format';
      case 'too_long':
        return 'this field is too long';
      case 'too_short':
        return 'this field is too short';
      case 'out_of_range':
      case 'outofrange':
        return 'this field is out of the allowed range';
      case 'duplicate_entity':
      case 'duplicate':
        return 'this value is already taken';
      case 'not_found':
        return 'not found';
      case 'forbidden':
        return 'you do not have permission';
      case 'unauthorized':
        return 'authentication required';
      case 'rate_limited':
      case 'ratelimited':
        return 'too many attempts, please retry later';
      case 'business_rule':
        return 'this violates a business rule';
      case 'invalid_state_transition':
        return 'this action is not allowed in the current state';
      case 'multiple_errors':
        return 'one or more fields are invalid';
      default:
        return tail.replaceAll('_', ' ');
    }
  }
}

/// Convenience typedef used by all repositories.
typedef NetworkEither<T> = Either<NetworkExceptions, T>;

/// Convenience constructors for [Either] left values.
NetworkEither<T> networkLeft<T>(NetworkExceptions exception) =>
    Left<NetworkExceptions, T>(exception);
NetworkEither<T> networkRight<T>(T value) =>
    Right<NetworkExceptions, T>(value);
