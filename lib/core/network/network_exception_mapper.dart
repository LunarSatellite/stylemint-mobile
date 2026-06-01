import 'package:dio/dio.dart';

import 'network_exceptions.dart';

NetworkExceptions mapDioExceptionToNetworkException(dynamic exception) {
  if (exception is DioException) {
    if (exception.response != null) {
      final statusCode = exception.response!.statusCode ?? 0;
      final message = exception.message ?? 'Server error';

      switch (statusCode) {
        case 400:
        case 422:
          return NetworkExceptions.validation(code: statusCode.toString());
        case 401:
        case 403:
          return const NetworkExceptions.auth();
        case 404:
          return const NetworkExceptions.notFound();
        case 409:
          return const NetworkExceptions.conflict();
        case >= 500:
          return NetworkExceptions.server(message);
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
