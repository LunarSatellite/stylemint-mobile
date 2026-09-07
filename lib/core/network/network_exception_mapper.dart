import 'package:dio/dio.dart';

import 'network_exceptions.dart';

NetworkExceptions mapDioExceptionToNetworkException(dynamic exception) {
  if (exception is DioException) {
    if (exception.response != null) {
      final statusCode = exception.response!.statusCode ?? 0;
      final message = exception.message ?? 'Server error';
      final body = exception.response!.data;

      switch (statusCode) {
        case 400:
        case 422:
        case 429: // rate limited — body carries 'system.rate_limited'
          return _buildValidation(body, statusCode);
        case 401:
        case 403:
          return const NetworkExceptions.auth();
        case 404:
          return const NetworkExceptions.notFound();
        case 409:
          return _buildConflict(body);
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

/// Build a `.validation(...)` from the RFC 7807 body, pulling the machine
/// errorCode, the human `title`, the top-level `field`, and any `errors[]`
/// so the snackbar can say exactly which field is wrong.
NetworkExceptions _buildValidation(dynamic body, int statusCode) {
  final code = _extractErrorCode(body) ?? statusCode.toString();
  final title = _extractTitle(body);
  final field = _extractField(body);
  final errors = _extractErrors(body);
  return NetworkExceptions.validation(
    code: code,
    message: title,
    field: field,
    errors: errors,
  );
}

NetworkExceptions _buildConflict(dynamic body) {
  final code = _extractErrorCode(body) ?? 'validation.conflict';
  final title = _extractTitle(body);
  final field = _extractField(body);
  return NetworkExceptions.validation(
    code: code,
    message: title,
    field: field,
  );
}

/// Reads the `errorCode` field from an RFC 7807 Problem Details body.
/// Returns null when the body isn't a map or has no string `errorCode`.
String? _extractErrorCode(dynamic data) {
  if (data is Map && data['errorCode'] is String) {
    return data['errorCode'] as String;
  }
  return null;
}

/// Reads the human-readable `title` from the RFC 7807 body. The backend puts
/// the actual sentence here (e.g. "Images must be between 5 and 10.").
String? _extractTitle(dynamic data) {
  if (data is Map && data['title'] is String) {
    final t = (data['title'] as String).trim();
    return t.isEmpty ? null : t;
  }
  return null;
}

/// Reads the top-level `field` for single-field validation errors.
String? _extractField(dynamic data) {
  if (data is Map && data['field'] is String) {
    final f = (data['field'] as String).trim();
    return f.isEmpty ? null : f;
  }
  return null;
}

/// Reads the `errors[]` array (per-field entries) from the RFC 7807 body.
/// Each entry has `{field, code, message}` and is rendered as
/// "field: message" by [NetworkExceptions.getMessage].
List<FieldErrorVm> _extractErrors(dynamic data) {
  if (data is Map && data['errors'] is List) {
    final list = data['errors'] as List;
    return list
        .whereType<Map>()
        .map((m) => FieldErrorVm.fromJson(Map<String, dynamic>.from(m)))
        .toList(growable: false);
  }
  return const [];
}
