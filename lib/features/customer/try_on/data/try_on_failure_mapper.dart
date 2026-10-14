import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/try_on/domain/entities/try_on_failure.dart';

/// Turns whatever a try-on datasource threw into a [TryOnFailure].
///
/// Reads the RFC 7807 body itself so a 403 keeps its `field`: `tryOnAccess`
/// opens the paywall, `tryOnDisabled` hides the feature.
TryOnFailure mapTryOnFailure(Object error) {
  if (error is TryOnFailure) return error;
  if (error is SocketException)
    return const TryOnFailure(TryOnFailureKind.offline);
  if (error is FormatException || error is TypeError) {
    return const TryOnFailure(TryOnFailureKind.unknown);
  }
  if (error is! DioException)
    return const TryOnFailure(TryOnFailureKind.unknown);

  final response = error.response;
  if (response == null) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => const TryOnFailure(
        TryOnFailureKind.offline,
      ),
      _ =>
        error.error is SocketException
            ? const TryOnFailure(TryOnFailureKind.offline)
            : const TryOnFailure(TryOnFailureKind.unknown),
    };
  }

  final status = response.statusCode ?? 0;
  final body = response.data;
  final code = _string(body, 'errorCode');
  final field = _string(body, 'field') ?? _firstErrorField(body);
  final message =
      _string(body, 'detail') ??
      _firstErrorMessage(body) ??
      _string(body, 'title');

  final kind = switch (status) {
    401 => TryOnFailureKind.auth,
    403 => switch (field?.toLowerCase()) {
      'tryondisabled' => TryOnFailureKind.disabled,
      'tryonaccess' => TryOnFailureKind.noAccess,
      _ => TryOnFailureKind.auth,
    },
    404 => TryOnFailureKind.notFound,
    409 => TryOnFailureKind.conflict,
    >= 500 => TryOnFailureKind.server,
    >= 400 => TryOnFailureKind.rejected,
    _ => TryOnFailureKind.unknown,
  };
  return TryOnFailure(
    kind,
    code: code,
    field: field,
    message: message,
    statusCode: status,
  );
}

/// Offline check, then [call], mapping anything thrown.
Future<Either<TryOnFailure, T>> guardedTryOnCall<T>(
  NetworkInfoConnectivity networkInfo,
  Future<T> Function() call,
) async {
  try {
    if (!await networkInfo.isConnected) {
      return left(const TryOnFailure(TryOnFailureKind.offline));
    }
    return right(await call());
  } on Object catch (error) {
    return left(mapTryOnFailure(error));
  }
}

String? _string(Object? body, String key) {
  if (body is! Map) return null;
  final value = body[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<Object?, Object?>? _firstError(Object? body) {
  if (body is! Map) return null;
  final errors = body['errors'];
  if (errors is List && errors.isNotEmpty && errors.first is Map) {
    return errors.first as Map<Object?, Object?>;
  }
  return null;
}

String? _firstErrorField(Object? body) => _string(_firstError(body), 'field');

String? _firstErrorMessage(Object? body) =>
    _string(_firstError(body), 'message');
