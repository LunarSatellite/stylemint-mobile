import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';

/// Maps any thrown exception (typically a [DioException]) to a domain
/// [Failure]. Repositories wrap datasource calls in `try { … } catch (e)`
/// and pass the error here so the mapping logic lives in one place.
///
/// Keys on the RFC 7807 `errorCode` when present, otherwise the HTTP status.
Failure mapExceptionToFailure(Object exception) {
  if (exception is! DioException) return const Failure.unknown();

  final response = exception.response;
  if (response == null) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => const Failure.network(),
      _ => const Failure.unknown(),
    };
  }

  final status = response.statusCode ?? 0;
  final data = response.data;
  final code =
      data is Map<String, dynamic> ? data['errorCode'] as String? : null;

  return switch (status) {
    400 => Failure.validation(code: code ?? 'INVALID_REQUEST'),
    401 || 403 => const Failure.auth(),
    404 => const Failure.notFound(),
    409 => const Failure.conflict(),
    422 => Failure.validation(code: code ?? 'UNPROCESSABLE_ENTITY'),
    >= 500 => const Failure.server(),
    _ => const Failure.unknown(),
  };
}
