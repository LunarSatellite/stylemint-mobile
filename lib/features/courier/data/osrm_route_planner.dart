import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';

/// Road routes from the public OSRM demo server.
///
/// Best effort by design. The demo server has no SLA and rate-limits, so
/// every failure — timeout, non-200, a body that is not a route — is a null,
/// and the job map falls back to straight dashed lines between the stops.
/// The rider still has both pins and their own position; the route line is
/// a convenience, never the thing that makes the screen usable.
///
/// Its own [Dio], not the app's API client: that one carries the bearer token
/// and the refresh interceptor, and neither belongs on a request to a third
/// party.
class OsrmRoutePlanner implements CourierRoutePlanner {
  OsrmRoutePlanner({
    Dio? dio,
    this.baseUrl = 'https://router.project-osrm.org',
    this.timeout = const Duration(seconds: 4),
  }) : _dio = dio ?? Dio(BaseOptions(connectTimeout: timeout));

  final Dio _dio;
  final String baseUrl;
  final Duration timeout;

  @override
  Future<CourierRoute?> plan(List<GeoPoint> stops) async {
    if (stops.length < 2) return null;
    // OSRM wants longitude first.
    final coordinates = stops
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    try {
      final response = await _dio.get<dynamic>(
        '$baseUrl/route/v1/driving/$coordinates',
        queryParameters: const {'overview': 'full', 'geometries': 'geojson'},
        options: Options(
          sendTimeout: timeout,
          receiveTimeout: timeout,
          responseType: ResponseType.json,
        ),
      );
      return parse(response.data);
    } on Object catch (error) {
      if (kDebugMode) debugPrint('[courier-route] OSRM unavailable: $error');
      return null;
    }
  }

  /// The first route of an OSRM `route` response, or null when there is
  /// none. Public so the parsing is testable without a network.
  static CourierRoute? parse(Object? body) {
    if (body is! Map || body['code'] != 'Ok') return null;
    final routes = body['routes'];
    if (routes is! List || routes.isEmpty || routes.first is! Map) return null;
    final route = routes.first as Map;
    final geometry = route['geometry'];
    if (geometry is! Map || geometry['coordinates'] is! List) return null;

    final path = <GeoPoint>[];
    for (final pair in geometry['coordinates'] as List) {
      if (pair is! List || pair.length < 2) continue;
      final longitude = _number(pair[0]);
      final latitude = _number(pair[1]);
      if (latitude == null || longitude == null) continue;
      path.add(GeoPoint(latitude, longitude));
    }
    if (path.length < 2) return null;

    return CourierRoute(
      path: path,
      distanceMetres: _number(route['distance']),
      durationSeconds: _number(route['duration']),
    );
  }

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : null;
}
