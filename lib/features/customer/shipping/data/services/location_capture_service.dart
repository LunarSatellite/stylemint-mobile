import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// A GPS fix looser than this can't tell one building from its neighbours, so
/// the customer is warned and asked to confirm (or drag the pin) before it is
/// saved. The backend enforces its own limit too.
const double kPoorAccuracyMetres = 100;

/// Beyond this the chosen point is probably not where the customer is
/// standing. That is perfectly legitimate — a parent's flat, an office — so
/// this only triggers a confirmation, never a refusal.
const double kFarFromDeviceMetres = 25000;

/// Rejects the obviously-broken coordinates before they reach the API:
/// out-of-range values, NaN/infinity, and the Null Island `0, 0` that a
/// failed parse produces far more often than a real address does.
bool isPlausibleCoordinate(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return false;
  if (latitude.isNaN || longitude.isNaN) return false;
  if (latitude.isInfinite || longitude.isInfinite) return false;
  if (latitude < -90 || latitude > 90) return false;
  if (longitude < -180 || longitude > 180) return false;
  // Null Island: a real delivery address is never within ~1 km of 0,0.
  if (latitude.abs() < 0.01 && longitude.abs() < 0.01) return false;
  return true;
}

/// Great-circle distance in metres. Implemented here rather than via
/// `Geolocator.distanceBetween` so it stays pure Dart — no platform channel,
/// so widget tests can exercise the far-from-you confirmation.
double distanceBetweenMetres(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadiusMetres = 6371000.0;
  double toRadians(double degrees) => degrees * math.pi / 180.0;

  final dLat = toRadians(lat2 - lat1);
  final dLon = toRadians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(toRadians(lat1)) *
          math.cos(toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Outcome of a "Use my current location" tap. Every real-world path the
/// platform can take is a distinct case so the UI can say something true and
/// offer the right next step, instead of a generic failure.
sealed class LocationCaptureResult {
  const LocationCaptureResult();
}

/// Got a fix. [accuracyMetres] is the horizontal accuracy the OS reported.
class LocationCaptured extends LocationCaptureResult {
  const LocationCaptured({
    required this.latitude,
    required this.longitude,
    required this.accuracyMetres,
  });

  final double latitude;
  final double longitude;
  final double accuracyMetres;
}

/// The customer said no this time; asking again is allowed.
class LocationPermissionDenied extends LocationCaptureResult {
  const LocationPermissionDenied();
}

/// "Don't ask again" / iOS Settings-only. Nothing to do in-app except send
/// them to the system settings page.
class LocationPermissionDeniedForever extends LocationCaptureResult {
  const LocationPermissionDeniedForever();
}

/// Location services are switched off device-wide.
class LocationServicesDisabled extends LocationCaptureResult {
  const LocationServicesDisabled();
}

/// No fix arrived inside the time limit — common indoors.
class LocationTimedOut extends LocationCaptureResult {
  const LocationTimedOut();
}

/// Anything else the platform threw.
class LocationCaptureFailed extends LocationCaptureResult {
  const LocationCaptureFailed(this.message);

  final String message;
}

/// Wraps `geolocator` so screens never touch the plugin directly (and so
/// tests can drive every failure path without a platform channel).
abstract interface class LocationCaptureService {
  /// Reads the device position.
  ///
  /// With [requestPermission] false the OS is never prompted — used to get a
  /// quiet reference point for the "is this pin far from you?" check, which
  /// must not throw a permission dialog at someone who only wants to paste a
  /// Maps link.
  Future<LocationCaptureResult> capture({
    Duration timeout,
    bool requestPermission,
  });

  /// Opens the OS app-settings page — the only recovery from
  /// [LocationPermissionDeniedForever].
  Future<bool> openAppSettings();

  /// Opens the OS location-services page — the recovery from
  /// [LocationServicesDisabled].
  Future<bool> openLocationSettings();
}

class GeolocatorLocationCaptureService implements LocationCaptureService {
  const GeolocatorLocationCaptureService();

  @override
  Future<LocationCaptureResult> capture({
    Duration timeout = const Duration(seconds: 15),
    bool requestPermission = true,
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationServicesDisabled();
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationPermissionDeniedForever();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationPermissionDenied();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LocationCaptured(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
      );
    } on TimeoutException {
      return const LocationTimedOut();
    } on LocationServiceDisabledException {
      return const LocationServicesDisabled();
    } on PermissionDeniedException {
      return const LocationPermissionDenied();
    } on PermissionDefinitionsNotFoundException {
      // The manifest/Info.plist entry is missing — a build problem, not
      // something the customer can fix, so don't pretend they denied it.
      return const LocationCaptureFailed(
        'Location is not available in this build.',
      );
    } on Object catch (e) {
      return LocationCaptureFailed(e.toString());
    }
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
