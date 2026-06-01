import 'package:fpdart/fpdart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_exceptions.freezed.dart';

@freezed
abstract class NetworkExceptions with _$NetworkExceptions {
  const factory NetworkExceptions.server(String message) = _Server;
  const factory NetworkExceptions.noInternetConnection() = _NoInternet;
  const factory NetworkExceptions.unexpectedError() = _Unexpected;
  const factory NetworkExceptions.formatException() = _Format;
  const factory NetworkExceptions.emptyData() = _EmptyData;
  const factory NetworkExceptions.validation({required String code}) =
      _Validation;
  const factory NetworkExceptions.auth() = _Auth;
  const factory NetworkExceptions.notFound() = _NotFound;
  const factory NetworkExceptions.conflict() = _Conflict;

  static String getMessage(NetworkExceptions exception) {
    return exception.when(
      server: (msg) => msg,
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
