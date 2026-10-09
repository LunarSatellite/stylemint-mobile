import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/data/rider_rating_error_mapper.dart';
import 'package:stylemint_mobile_frontend/features/rider_ratings/domain/entities/rider_rating.dart';

/// The rider-rating endpoints (rider-rating contract).
///
/// Failures are thrown already mapped (see [mapRiderRatingDioException]) so
/// the contract's error codes survive the repository's guard. A 404 on a GET
/// is "nothing yet" — no rating given, or a backend without ratings — and
/// comes back as null rather than an error.
class RiderRatingRemoteDataSource {
  RiderRatingRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  String _path(RiderRaterRole role, String subOrderId) =>
      '/v1/${role.pathSegment}/sub-orders/'
      '${Uri.encodeComponent(subOrderId)}/rider-rating';

  /// `PUT …/rider-rating` — creates or replaces this rater's rating.
  Future<Map<String, dynamic>> putRating({
    required RiderRaterRole role,
    required String subOrderId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    try {
      final response = await apiClient.put(
        _path(role, subOrderId),
        data: body,
        options: Options(
          headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
        ),
      );
      return response is Map
          ? response.cast<String, dynamic>()
          : const <String, dynamic>{};
    } on DioException catch (e) {
      throw mapRiderRatingDioException(e);
    }
  }

  /// `GET …/rider-rating`, or null when none was given.
  Future<Map<String, dynamic>?> getRating({
    required RiderRaterRole role,
    required String subOrderId,
  }) => _getOrNull(_path(role, subOrderId));

  /// `GET /v1/courier/me/rating` — the signed-in rider's own summary.
  Future<Map<String, dynamic>?> getMyRating() =>
      _getOrNull('/v1/courier/me/rating');

  Future<Map<String, dynamic>?> _getOrNull(String path) async {
    try {
      final response = await apiClient.get(path);
      return response is Map ? response.cast<String, dynamic>() : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw mapRiderRatingDioException(e);
    }
  }
}
