import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

/// Why a service-vendor call (bookings, availability, bank leads,
/// appointments, onboarding) failed.
///
/// Keeps what the shared `NetworkExceptions` drops: the RFC 7807
/// `errorCode` and `field`, which the screens turn into their own sentences,
/// and whether a 404 means "not deployed yet" (no `errorCode`) or "this
/// booking is not there" (a `*.not_found` code).
enum ServiceFailureKind { offline, notFound, auth, rejected, conflict, server, unknown }

class ServiceFailure {
  const ServiceFailure(
    this.kind, {
    this.code,
    this.message,
    this.field,
    this.statusCode,
  });

  final ServiceFailureKind kind;

  /// The RFC 7807 `errorCode`, e.g. `service_lead.invalid_transition`.
  final String? code;

  /// The server's own sentence (`detail`, else `title`).
  final String? message;

  /// The offending field, when the server named one.
  final String? field;
  final int? statusCode;

  bool get isNotFound => kind == ServiceFailureKind.notFound;

  /// A 404 that is not a feature's own `*.not_found` — the route itself is
  /// missing because the backend is not deployed yet. Screens say "being set
  /// up" for it.
  bool get isNotDeployed =>
      isNotFound && !(code?.endsWith('.not_found') ?? false);

  /// 403 `service_vendor.not_a_bank` and its booking-side siblings: the
  /// operating vendor is not (or not yet) an approved vendor of this kind.
  bool get isWrongVendorKind =>
      kind == ServiceFailureKind.auth &&
      (code?.startsWith('service_vendor.') ?? false);

  @override
  String toString() => 'ServiceFailure($kind, $code, $statusCode)';
}

/// Thrown out of a FutureProvider so the screen can read the failure back.
class ServiceLoadException implements Exception {
  const ServiceLoadException(this.failure);

  final ServiceFailure failure;

  @override
  String toString() => 'ServiceLoadException($failure)';
}

/// The failure behind a provider error, when it is one of ours.
ServiceFailure? serviceFailureOf(Object? error) {
  if (error is ServiceLoadException) return error.failure;
  if (error is ServiceFailure) return error;
  return null;
}

/// True when [error] means the feature is not deployed yet (a bare 404), or
/// the vendor's category is not set up on the server side yet.
bool serviceUnavailable(Object? error) {
  final failure = serviceFailureOf(error);
  if (failure == null) return false;
  return failure.isNotDeployed;
}

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
    field: _string(body, 'field'),
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

/// Runs [call] and turns whatever it throws into a [ServiceFailure].
///
/// No connectivity pre-check: a screen that says "offline" while the request
/// would have worked is worse than letting Dio report a real connection
/// error.
Future<Either<ServiceFailure, T>> guardedServiceCall<T>(
  Future<T> Function() call,
) async {
  try {
    return right(await call());
  } on Object catch (error) {
    return left(mapServiceFailure(error));
  }
}

/// A plain sentence for a failure, for a snackbar or an error view.
/// [specific] maps the feature's own error codes first.
String serviceFailureMessage(
  ServiceFailure failure, {
  String? Function(String code)? specific,
  String fallback = 'Something went wrong. Please try again.',
}) {
  final code = failure.code;
  if (code != null && specific != null) {
    final mapped = specific(code);
    if (mapped != null) return mapped;
  }
  return switch (failure.kind) {
    ServiceFailureKind.offline =>
      'You appear to be offline. Check your connection and try again.',
    ServiceFailureKind.auth when failure.isWrongVendorKind =>
      'This is only for approved service businesses of this kind.',
    ServiceFailureKind.auth => 'Please sign in again to continue.',
    ServiceFailureKind.server =>
      'StyleMint is having trouble right now. Try again in a moment.',
    ServiceFailureKind.notFound when failure.isNotDeployed =>
      'This is still being set up. Check back shortly.',
    ServiceFailureKind.notFound => 'We could not find that any more.',
    ServiceFailureKind.rejected ||
    ServiceFailureKind.conflict => failure.message ?? fallback,
    ServiceFailureKind.unknown => fallback,
  };
}
