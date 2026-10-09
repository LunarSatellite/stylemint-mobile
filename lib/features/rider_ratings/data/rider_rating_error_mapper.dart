import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exception_mapper.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';

/// [mapDioExceptionToNetworkException], but keeping the contract's
/// `rider_rating.*` / `rider_profile.*` error codes whatever the status.
///
/// The shared mapper turns every 403 into "sign in again" and every 404 into
/// a bare not-found, which is wrong here: `rider_rating.not_eligible` (403)
/// means "this order cannot be rated", and `rider_profile.not_available`
/// (404) means "that rider is no longer on this request". Both need to reach
/// the screen as themselves.
NetworkExceptions mapRiderRatingDioException(DioException e) {
  final body = e.response?.data;
  final code = riderErrorCodeOf(body);
  if (code != null) {
    return NetworkExceptions.validation(
      code: code,
      message: _text(body, 'detail') ?? _text(body, 'title'),
    );
  }
  return mapDioExceptionToNetworkException(e);
}

/// The body's `rider_rating.*` or `rider_profile.*` error code, lower-cased;
/// null for any other body.
String? riderErrorCodeOf(Object? body) {
  if (body is! Map) return null;
  final code = body['errorCode']?.toString().trim().toLowerCase();
  if (code == null) return null;
  return code.startsWith('rider_rating.') || code.startsWith('rider_profile.')
      ? code
      : null;
}

String? _text(Object? body, String key) {
  if (body is! Map) return null;
  final value = body[key]?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
