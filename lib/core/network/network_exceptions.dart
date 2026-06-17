import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_exceptions.freezed.dart';

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
  const factory NetworkExceptions.validation({required String code}) =
      _Validation;
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
        validation: (code) => code,
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
        validation: (_) => false,
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
        validation: (_) => false,
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
        validation: (_) => false,
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
        validation: (_) => false,
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
        validation: (_) => false,
        auth: () => false,
        notFound: () => false,
        conflict: () => false,
      );

  static String getMessage(NetworkExceptions exception) {
    return exception.when(
      server: (msg) => msg,
      serverUnavailable: () =>
          'StyleMint is temporarily unavailable. Please try again in a moment.',
      noInternetConnection: () => 'No internet connection.',
      unexpectedError: () => 'An unexpected error occurred.',
      formatException: () => 'Invalid response format.',
      emptyData: () => 'No data available.',
      validation: (code) => 'Validation error: $code',
      auth: () => 'Authentication required.',
      notFound: () => 'Resource not found.',
      conflict: () => 'Conflict detected.',
    );
  }
}

/// Convenience typedef used by all repositories.
typedef NetworkEither<T> = Either<NetworkExceptions, T>;

/// Convenience constructors for [Either] left values.
NetworkEither<T> networkLeft<T>(NetworkExceptions exception) =>
    Left<NetworkExceptions, T>(exception);
NetworkEither<T> networkRight<T>(T value) =>
    Right<NetworkExceptions, T>(value);
