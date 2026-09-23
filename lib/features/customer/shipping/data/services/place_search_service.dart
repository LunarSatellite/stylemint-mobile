import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// One match from a place search: somewhere the shopper can drop the pin.
@immutable
class PlaceResult {
  const PlaceResult({
    required this.label,
    required this.detail,
    required this.latitude,
    required this.longitude,
  });

  /// The primary line — a building, street or place name.
  final String label;

  /// The quieter second line: city, region, country. Empty when nothing
  /// beyond [label] is known.
  final String detail;

  final double latitude;
  final double longitude;
}

/// Turns typed text into candidate points.
///
/// An interface, not a concrete client, so the provider can be overridden in
/// widget tests without any network at all — the same way
/// `locationCaptureServiceProvider` stands in for GPS.
abstract interface class PlaceSearchService {
  /// Best matches for [query]. Returns an empty list for a query too short to
  /// be worth sending.
  ///
  /// Deliberately takes no location to bias the results with. An earlier
  /// version passed the map's centre as `lat`/`lon`, which put where the
  /// shopper is standing into a query string sent to a third-party geocoder,
  /// and so into that operator's access logs. Where someone lives may travel
  /// in a request body to our own backend and nowhere else — see
  /// test/features/customer/shipping/address_coordinate_containment_test.dart.
  /// Ranking is a little worse for it; that is the trade being made.
  Future<List<PlaceResult>> search(String query);
}

/// Raised when the geocoder could not be reached or answered with something
/// unusable. The form turns this into one quiet line, never a dialog — a
/// search that fails still leaves the map and the pin working.
class PlaceSearchException implements Exception {
  const PlaceSearchException();
}

/// Photon (https://photon.komoot.io), Komoot's OSM geocoder.
///
/// Chosen over Nominatim, whose usage policy explicitly discourages
/// autocomplete-style querying, and over the keyed providers (LocationIQ,
/// MapTiler, Google Places) because it needs no account, no key and no
/// billing — matching the OSM raster tiles the map already draws. Both read
/// OpenStreetMap, so a result lines up with what the shopper sees on the map.
///
/// Deliberately its own [Dio], not the app's [ApiClient]: this host is a third
/// party, and the shared client attaches StyleMint's bearer token and base URL
/// to everything it sends.
///
/// Note for whoever picks this up later: Photon is a free public endpoint with
/// no uptime guarantee. If place search becomes load-bearing, move to a keyed
/// provider or self-host — [PlaceSearchService] is the seam for it.
class PhotonPlaceSearchService implements PlaceSearchService {
  PhotonPlaceSearchService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: _timeout,
              receiveTimeout: _timeout,
              // A non-200 is handled below, not thrown as a DioException.
              validateStatus: (_) => true,
              headers: const {'User-Agent': _userAgent},
            ),
          );

  final Dio _dio;

  static const String _endpoint = 'https://photon.komoot.io/api';
  static const int _limit = 8;
  static const Duration _timeout = Duration(seconds: 8);

  /// Identifies the app to the geocoder, as the tile layer already does for
  /// OSM's tile servers.
  static const String _userAgent =
      'app.stylemint.stylemint_mobile_frontend';

  /// Below this a query matches most of the planet, so it is not sent.
  static const int minQueryLength = 3;

  @override
  Future<List<PlaceResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) return const <PlaceResult>[];

    final Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        _endpoint,
        queryParameters: <String, dynamic>{'q': trimmed, 'limit': _limit},
      );
    } on Object catch (_) {
      throw const PlaceSearchException();
    }

    if (response.statusCode != 200) throw const PlaceSearchException();

    final body = response.data;
    if (body is! Map) throw const PlaceSearchException();
    final features = body['features'];
    if (features is! List) return const <PlaceResult>[];

    return features
        .whereType<Map<String, dynamic>>()
        .map(_toResult)
        .whereType<PlaceResult>()
        .toList(growable: false);
  }

  /// GeoJSON feature → [PlaceResult]. Returns null for a feature without a
  /// usable point rather than inventing one.
  static PlaceResult? _toResult(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    // GeoJSON orders coordinates [longitude, latitude]. Reading these the
    // other way round drops the pin in the wrong hemisphere, silently.
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;
    final longitude = (coords[0] as num?)?.toDouble();
    final latitude = (coords[1] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    final props = feature['properties'];
    final Map<dynamic, dynamic> p = props is Map ? props : const {};

    String? str(String key) {
      final value = p[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    // House number and street read as one line, the way an address does.
    final street = str('street');
    final houseNumber = str('housenumber');
    final streetLine = street == null
        ? null
        : (houseNumber == null ? street : '$houseNumber $street');

    final label = str('name') ?? streetLine ?? str('city') ?? str('country');
    if (label == null) return null;

    final parts = <String>[];
    void add(String? part) {
      if (part == null || part == label || parts.contains(part)) return;
      parts.add(part);
    }

    add(streetLine);
    add(str('district'));
    add(str('city'));
    add(str('state'));
    add(str('country'));

    return PlaceResult(
      label: label,
      detail: parts.join(', '),
      latitude: latitude,
      longitude: longitude,
    );
  }
}
