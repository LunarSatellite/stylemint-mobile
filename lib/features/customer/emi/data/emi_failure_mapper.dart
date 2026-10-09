import 'dart:io';

import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';

/// Turns whatever a datasource threw into an [EmiFailure].
///
/// Reads the RFC 7807 body itself, unlike the shared mapper: a 404 keeps its
/// `errorCode`, and `kyc.documents_missing` keeps its `missing` list.
EmiFailure mapEmiFailure(Object error) {
  if (error is EmiFailure) return error;
  if (error is SocketException) {
    return const EmiFailure(EmiFailureKind.offline);
  }
  if (error is FormatException || error is TypeError) {
    return const EmiFailure(EmiFailureKind.unknown);
  }
  if (error is! DioException) return const EmiFailure(EmiFailureKind.unknown);

  final response = error.response;
  if (response == null) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError => const EmiFailure(
        EmiFailureKind.offline,
      ),
      _ =>
        error.error is SocketException
            ? const EmiFailure(EmiFailureKind.offline)
            : const EmiFailure(EmiFailureKind.unknown),
    };
  }

  final status = response.statusCode ?? 0;
  final body = response.data;
  final code = _string(body, 'errorCode');
  final message = _string(body, 'detail') ?? _string(body, 'title');
  final missing = body is Map && body['missing'] is List
      ? (body['missing'] as List).whereType<String>().toList(growable: false)
      : const <String>[];

  final kind = switch (status) {
    401 || 403 => EmiFailureKind.auth,
    404 => EmiFailureKind.notFound,
    413 => EmiFailureKind.tooLarge,
    >= 500 => EmiFailureKind.server,
    >= 400 => EmiFailureKind.rejected,
    _ => EmiFailureKind.unknown,
  };
  return EmiFailure(
    kind,
    code: code,
    message: message,
    missing: missing,
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
