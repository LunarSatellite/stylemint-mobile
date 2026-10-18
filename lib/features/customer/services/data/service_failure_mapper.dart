import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';

/// Turns whatever a datasource threw into a [ServiceFailure], reading the
/// RFC 7807 body itself so a 404 or 409 keeps its `errorCode`.
ServiceFailure mapServiceFailure(Object error) {
  if (error is ServiceFailure) return error;
  if (error is ServiceLoadException) return error.failure;
  if (error is SocketException) {
    return const ServiceFailure(ServiceFailureKind.offline);
  }
  if (error is FormatException || error is TypeError) {
    return const ServiceFailure(ServiceFailureKind.unknown);
  }
  if (error is! DioException) {
    return const ServiceFailure(ServiceFailureKind.unknown);
  }

  final response = error.response;
  if (response == null) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => const ServiceFailure(
        ServiceFailureKind.offline,
      ),
      _ =>
        error.error is SocketException
            ? const ServiceFailure(ServiceFailureKind.offline)
            : const ServiceFailure(ServiceFailureKind.unknown),
    };
  }

  final status = response.statusCode ?? 0;
  final body = response.data;
  final kind = switch (status) {
    401 || 403 => ServiceFailureKind.auth,
    404 => ServiceFailureKind.notFound,
    409 => ServiceFailureKind.conflict,
    >= 500 => ServiceFailureKind.server,
    >= 400 => ServiceFailureKind.rejected,
    _ => ServiceFailureKind.unknown,
  };
  return ServiceFailure(
    kind,
    code: _string(body, 'errorCode'),
    message: _string(body, 'detail') ?? _string(body, 'title'),
    statusCode: status,
  );
}

String? _string(Object? body, String key) {
  if (body is! Map) return null;
  final value = body[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// One call, with the offline check first and every error mapped.
Future<Either<ServiceFailure, T>> guardedServiceCall<T>(
  NetworkInfoConnectivity networkInfo,
  Future<T> Function() call,
) async {
  try {
    if (!await networkInfo.isConnected) {
      return left(const ServiceFailure(ServiceFailureKind.offline));
    }
    return right(await call());
  } on Object catch (error) {
    return left(mapServiceFailure(error));
  }
}
