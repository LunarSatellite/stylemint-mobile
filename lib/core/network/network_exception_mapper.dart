import 'package:dio/dio.dart';

import 'network_exceptions.dart';

NetworkExceptions mapDioExceptionToNetworkException(dynamic exception) {
  if (exception is DioException) {
    if (exception.response != null) {
      final statusCode = exception.response!.statusCode ?? 0;
      final message = exception.message ?? 'Server error';
      // RFC 7807 Problem Details carry a machine-readable `errorCode`
      // (e.g. 'validation.invalid_format', 'system.rate_limited'). Surface it
      // so the UI can key on it; fall back to the status code when absent.
      final errorCode = _extractErrorCode(exception.response!.data);

      switch (statusCode) {
        case 400:
        case 422:
        case 429: // rate limited — body carries 'system.rate_limited'
          return NetworkExceptions.validation(
            code: errorCode ?? statusCode.toString(),
          );
        case 401:
        case 403:
          return const NetworkExceptions.auth();
        case 404:
          return const NetworkExceptions.notFound();
        case 409:
          return const NetworkExceptions.conflict();
        case >= 500:
          // 500/502/503/504 — backend or the gateway in front of it is down.
          // The body is often an HTML error page (e.g. nginx "502 Bad
          // Gateway"), so never surface it; map to a friendly, retryable error.
          return const NetworkExceptions.serverUnavailable();
        default:
          return NetworkExceptions.server(message);
      }
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return const NetworkExceptions.noInternetConnection();
      default:
        return const NetworkExceptions.unexpectedError();
    }
  }

  if (exception is FormatException) {
    return const NetworkExceptions.formatException();
  }

  return const NetworkExceptions.unexpectedError();
}

/// Reads the `errorCode` field from an RFC 7807 Problem Details body.
/// Returns null when the body isn't a map or has no string `errorCode`.
String? _extractErrorCode(dynamic data) {
  if (data is Map && data['errorCode'] is String) {
    return data['errorCode'] as String;
  }
  return null;
}
